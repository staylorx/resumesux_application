import 'dart:io';

import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart' show DotEnv;
import 'package:resumesux_application/src/infrastructure/ai_service_factory_impl.dart';
import 'package:resumesux_application/src/infrastructure/config_repository_impl.dart';
import 'package:resumesux_application/src/infrastructure/grade_scorer.dart';

/// Grades a generated application file against a job's required skills, using
/// the configured inference provider.
///
/// Example:
///   dart run tool/fitness/grade_content.dart \
///     --content out/application.md --job "Data Scientist" \
///     --requires "Python,SQL,statistics|machine learning,data visualization" \
///     --model gpt-oss-20b-agent:latest
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.')
    ..addOption('content', help: 'Path to the generated application file.')
    ..addOption('job', help: 'Job title the application targets.')
    ..addOption('requires', help: 'Required skills, comma separated.')
    ..addOption('config', abbr: 'c', defaultsTo: 'config.yaml')
    ..addOption('provider', abbr: 'p')
    ..addOption('model', help: 'Model name (default: provider default).');
  final parsed = parser.parse(args);

  if (parsed['help'] == true) {
    stdout.writeln(parser.usage);
    return;
  }

  final contentPath = parsed['content'] as String?;
  final job = parsed['job'] as String?;
  final requires = (parsed['requires'] as String? ?? '');
  final requiredSkills = requires
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  if (contentPath == null || job == null || requiredSkills.isEmpty) {
    stderr.writeln('ERROR: --content, --job and --requires are required');
    exit(1);
  }
  final file = File(contentPath);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: content file not found: $contentPath');
    exit(1);
  }
  final content = await file.readAsString();

  final dot = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    dot.load();
  }
  final configPath = parsed['config'] as String;
  final repository = ConfigRepositoryImpl(
    defaultConfigPath: configPath,
    lookup: (name) => dot[name] ?? '',
  );

  final requestedProvider = parsed['provider'] as String?;
  String providerName;
  if (requestedProvider != null) {
    providerName = requestedProvider;
  } else {
    final either = await repository
        .getDefaultProvider(configPath: configPath)
        .run();
    providerName = either.fold((l) {
      stderr.writeln('ERROR: no default provider: ${l.message}');
      exit(1);
    }, (p) => p.name);
  }

  final factory = AiServiceFactoryImpl(configRepository: repository);
  final serviceEither = await factory
      .createAiService(
        providerName: providerName,
        modelName: parsed['model'] as String?,
      )
      .run();
  final service = serviceEither.fold((l) {
    stderr.writeln('ERROR: ${l.message}');
    exit(1);
  }, (s) => s);

  final scorer = GradeScorer(aiService: service);
  final resultEither = await scorer
      .grade(content: content, jobTitle: job, requiredSkills: requiredSkills)
      .run();
  final report = resultEither.fold((l) {
    stderr.writeln('ERROR: ${l.message}');
    exit(1);
  }, (r) => r);

  stdout.writeln('=== Grade: $job ===');
  for (final point in report.points) {
    final mark = point.covered ? 'covered   ' : 'MISSING   ';
    stdout.writeln('  $mark ${point.skill}');
  }
  stdout.writeln('  -> covered ${report.coveredCount}/${report.points.length}');
  stdout.writeln('  -> fit: ${report.fit ? 'YES' : 'no'}');
}

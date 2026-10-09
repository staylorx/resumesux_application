import 'dart:io';

import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart' show DotEnv;
import 'package:resumesux_application/src/infrastructure/ai_service_factory_impl.dart';
import 'package:resumesux_application/src/infrastructure/config_repository_impl.dart';
import 'package:resumesux_application/src/infrastructure/fitness_scorer.dart';

import 'fixtures.dart';

/// Runs the persona->job fitness matrix against a real inference provider and
/// prints a discernment report (which matches are accepted, which mismatches
/// are rejected, and the totals).
///
/// Example:
///   dart run tool/fitness/run_fitness.dart --provider ollama --model gpt-oss-20b-agent:latest
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.')
    ..addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'config.yaml',
      help: 'Path to the config.yaml file for the provider.',
    )
    ..addOption(
      'provider',
      abbr: 'p',
      help: 'Provider name (default: config default).',
    )
    ..addOption('model', help: 'Model name (default: provider default model).')
    ..addOption(
      'only',
      help:
          'Only run pairs whose persona or job title contains this substring.',
    );
  final parsed = parser.parse(args);

  if (parsed['help'] == true) {
    stdout.writeln('Run the persona->job fitness matrix against a provider.');
    stdout.writeln();
    stdout.writeln(parser.usage);
    return;
  }

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
    providerName = await _defaultProviderName(repository, configPath);
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

  final scorer = FitnessScorer(aiService: service);
  final only = parsed['only'] as String?;

  final results = <PairResult>[];
  for (final persona in personas) {
    for (final job in jobs) {
      if (only != null &&
          !_contains(persona.name, only) &&
          !_contains(job.title, only)) {
        continue;
      }
      final expectedFit = job.bestFitPersonas.contains(persona.name);
      final verdictEither = await scorer
          .score(
            candidateName: persona.name,
            candidateSkills: persona.skills,
            jobTitle: job.title,
            jobRequired: job.requires,
          )
          .run();
      final verdict = verdictEither.fold(
        (l) => FitVerdict(fit: null, reason: 'ERROR: ${l.message}', raw: ''),
        (v) => v,
      );
      results.add(
        PairResult(
          persona: persona.name,
          job: job.title,
          expectedFit: expectedFit,
          verdict: verdict,
        ),
      );
    }
  }

  _report(results);
}

class PairResult {
  final String persona;
  final String job;
  final bool expectedFit;
  final FitVerdict verdict;

  PairResult({
    required this.persona,
    required this.job,
    required this.expectedFit,
    required this.verdict,
  });

  bool get inconclusive => verdict.fit == null;
  bool get correct => !inconclusive && verdict.fit == expectedFit;
}

bool _contains(String haystack, String needle) =>
    haystack.toLowerCase().contains(needle.toLowerCase());

Future<String> _defaultProviderName(
  ConfigRepositoryImpl repo,
  String configPath,
) async {
  final either = await repo.getDefaultProvider(configPath: configPath).run();
  return either.fold((l) {
    stderr.writeln('ERROR: no default provider: ${l.message}');
    exit(1);
  }, (p) => p.name);
}

void _report(List<PairResult> results) {
  var tp = 0, fp = 0, tn = 0, fn = 0, inc = 0;
  final rows = <String>[];
  for (final r in results) {
    String mark;
    if (r.inconclusive) {
      inc++;
      mark = '?';
    } else if (r.verdict.fit! && r.expectedFit) {
      tp++;
      mark = 'TP';
    } else if (r.verdict.fit! && !r.expectedFit) {
      fp++;
      mark = 'FP';
    } else if (!r.verdict.fit! && r.expectedFit) {
      fn++;
      mark = 'FN';
    } else {
      tn++;
      mark = 'TN';
    }
    final got = r.verdict.fit == null
        ? 'INCONCLUSIVE'
        : (r.verdict.fit! ? 'FIT' : 'no-fit');
    final expected = r.expectedFit ? 'FIT' : 'no-fit';
    final note = got == expected
        ? ''
        : '  <- wrong (reason: ${r.verdict.reason ?? 'n/a'})';
    rows.add(
      '  ${mark.padRight(2)} ${r.persona.padRight(24)} -> ${r.job.padRight(28)} '
      'expected=${expected.padRight(6)} got=$got$note',
    );
  }

  stdout.writeln('=== Fitness matrix (${results.length} pairs) ===');
  rows.forEach(stdout.writeln);
  stdout.writeln();
  stdout.writeln('=== Summary ===');
  stdout.writeln('  pairs         : ${results.length}');
  stdout.writeln('  TP (accepted expect-fit)      : $tp');
  stdout.writeln('  TN (rejected expect-no-fit)   : $tn');
  stdout.writeln('  FP (accepted expect-no-fit!)  : $fp');
  stdout.writeln('  FN (rejected expect-fit!)     : $fn');
  stdout.writeln('  inconclusive (parse fail)     : $inc');
  final scored = tp + tn + fp + fn;
  final acc = scored == 0 ? 0.0 : (tp + tn) / scored;
  stdout.writeln(
    '  accuracy (excl. inconclusive) : '
    '${(acc * 100).toStringAsFixed(1)}%  ($scored scored)',
  );
  stdout.writeln();
  stdout.writeln('=== Key cross cases (must be rejected) ===');
  for (final r in results) {
    if (!r.expectedFit &&
        ((r.persona.contains('Equipment') && r.job.contains('Data')) ||
            (r.persona.contains('Data') && r.job.contains('Equipment')) ||
            (r.persona.contains('Equipment') && r.job.contains('Line Cook')))) {
      final got = r.verdict.fit == null
          ? 'INCONCLUSIVE'
          : (r.verdict.fit! ? 'WRONGLY ACCEPTED' : 'correctly rejected');
      stdout.writeln('  ${r.persona} -> ${r.job} : $got');
    }
  }
}

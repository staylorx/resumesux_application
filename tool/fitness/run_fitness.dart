import 'dart:convert';
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
    )
    ..addOption(
      'runs',
      defaultsTo: '1',
      help: 'How many times to repeat each pair (variance / pass-rate).',
    )
    ..addOption(
      'out',
      help: 'Write a JSON report (per-pair pass rates + totals) to this path.',
    )
    ..addOption(
      'job',
      help: 'Run only the job column(s) whose title contains this substring.',
    )
    ..addOption(
      'persona',
      help: 'Run only persona rows whose name contains this substring.',
    );
  final parsed = parser.parse(args);

  if (parsed['help'] == true) {
    stdout.writeln('Run the persona->job fitness matrix against a provider.');
    stdout.writeln();
    stdout.writeln(parser.usage);
    return;
  }

  final runs = int.tryParse(parsed['runs'] as String) ?? 1;
  if (runs < 1) {
    stderr.writeln('ERROR: --runs must be >= 1');
    exit(1);
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
  final jobFilter = parsed['job'] as String?;
  final personaFilter = parsed['persona'] as String?;
  for (final persona in personas) {
    for (final job in jobs) {
      if (jobFilter != null && !_contains(job.title, jobFilter)) continue;
      if (personaFilter != null && !_contains(persona.name, personaFilter)) {
        continue;
      }
      if (only != null &&
          !_contains(persona.name, only) &&
          !_contains(job.title, only)) {
        continue;
      }
      final expectedFit = job.bestFitPersonas.contains(persona.name);
      final verdicts = <FitVerdict>[];
      for (var run = 0; run < runs; run++) {
        final verdictEither = await scorer
            .score(
              candidateName: persona.name,
              candidateSkills: persona.skills,
              jobTitle: job.title,
              jobRequired: job.requires,
            )
            .run();
        verdicts.add(
          verdictEither.fold(
            (l) =>
                FitVerdict(fit: null, reason: 'ERROR: ${l.message}', raw: ''),
            (v) => v,
          ),
        );
      }
      results.add(
        PairResult(
          persona: persona.name,
          job: job.title,
          expectedFit: expectedFit,
          verdicts: verdicts,
        ),
      );
    }
  }

  _report(results, runs: runs);

  final outPath = parsed['out'] as String?;
  if (outPath != null) {
    File(outPath).writeAsStringSync(jsonEncode(_toJson(results, runs: runs)));
    stdout.writeln('\nWrote JSON report to $outPath');
  }
}

class PairResult {
  final String persona;
  final String job;
  final bool expectedFit;
  final List<FitVerdict> verdicts;

  PairResult({
    required this.persona,
    required this.job,
    required this.expectedFit,
    required this.verdicts,
  });

  int get acceptedRuns => verdicts.where((v) => v.fit == true).length;
  int get rejectedRuns => verdicts.where((v) => v.fit == false).length;
  int get inconclusiveRuns => verdicts.where((v) => v.fit == null).length;
  int get correctRuns =>
      verdicts.where((v) => v.fit != null && v.fit == expectedFit).length;

  double get passRate => verdicts.isEmpty ? 0 : correctRuns / verdicts.length;
}

Map<String, Object?> _toJson(List<PairResult> results, {required int runs}) {
  final correct = results.fold(0, (s, r) => s + r.correctRuns);
  final valid = results.fold(
    0,
    (s, r) => s + (r.verdicts.length - r.inconclusiveRuns),
  );
  final falseAccepts = results
      .where((r) => !r.expectedFit)
      .fold(0, (s, r) => s + r.acceptedRuns);
  return {
    'runs': runs,
    'pairs': results
        .map(
          (r) => {
            'persona': r.persona,
            'job': r.job,
            'expectedFit': r.expectedFit,
            'passRate': r.passRate,
            'acceptedRuns': r.acceptedRuns,
            'rejectedRuns': r.rejectedRuns,
            'inconclusiveRuns': r.inconclusiveRuns,
          },
        )
        .toList(),
    'totals': {
      'validRuns': valid,
      'correctRuns': correct,
      'accuracy': valid == 0 ? 0.0 : correct / valid,
      'falseAccepts': falseAccepts,
      'pairs': results.length,
    },
  };
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

void _report(List<PairResult> results, {required int runs}) {
  final correct = results.fold(0, (s, r) => s + r.correctRuns);
  final valid = results.fold(
    0,
    (s, r) => s + (r.verdicts.length - r.inconclusiveRuns),
  );
  final falseAccepts = results
      .where((r) => !r.expectedFit)
      .fold(0, (s, r) => s + r.acceptedRuns);

  stdout.writeln(
    '=== Fitness matrix (${results.length} pairs, $runs run(s)) ===',
  );
  for (final r in results) {
    final passPct = (r.passRate * 100).toStringAsFixed(0).padLeft(3);
    final note = r.expectedFit ? 'expect FIT' : 'expect no-fit';
    stdout.writeln(
      '  $passPct%  ${r.persona.padRight(26)} -> ${r.job.padRight(28)} $note '
      '(accept ${r.acceptedRuns}/${r.verdicts.length}, '
      'inconcl ${r.inconclusiveRuns})',
    );
  }
  stdout.writeln();
  stdout.writeln('=== Summary ===');
  stdout.writeln('  pairs             : ${results.length}');
  stdout.writeln('  runs per pair     : $runs');
  stdout.writeln('  valid verdicts    : $valid');
  stdout.writeln('  correct verdicts  : $correct');
  final accText = valid == 0
      ? 'n/a'
      : '${((correct / valid) * 100).toStringAsFixed(1)}%';
  stdout.writeln('  accuracy          : $accText');
  stdout.writeln(
    '  false accepts     : $falseAccepts '
    '(mismatches wrongly accepted across all runs)',
  );
  stdout.writeln(
    '  inconclusive runs : '
    '${results.fold(0, (s, r) => s + r.inconclusiveRuns)}',
  );
}

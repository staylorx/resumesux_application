import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart' show DotEnv;
import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/infrastructure/ai_service_factory_impl.dart';
import 'package:resumesux_application/src/infrastructure/config_repository_impl.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Runs one AI inference for a configured provider/model and prints the result.
///
/// ```sh
/// dart run resumesux --config config.yaml --provider lmstudio \
///   --model qwen2.5-7b-instruct --prompt "Summarize this job req"
/// ```
///
/// The provider's API key is read from the environment as
/// `RESUMESUX_<PROVIDER>_KEY` (see `.env.example`); a gitignored `.env` file
/// in the working directory is merged in automatically.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.')
    ..addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'config.yaml',
      help: 'Path to the config.yaml file.',
    )
    ..addOption(
      'provider',
      abbr: 'p',
      help: 'Provider name (default: the configured default provider).',
    )
    ..addOption(
      'model',
      help: 'Model name (default: the provider default model).',
    )
    ..addOption('prompt', help: 'Prompt text. If omitted, reads from stdin.');
  final parsed = parser.parse(args);

  if (parsed['help'] == true) {
    stdout.writeln('Run AI inference for a configured provider/model.');
    stdout.writeln();
    stdout.writeln(parser.usage);
    return;
  }

  // Merge a gitignored .env file into an environment source that is visible to
  // the config repository (Platform.environment is read-only on Dart).
  final dot = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    dot.load();
  }

  final configPath = parsed['config'] as String;
  final repository = ConfigRepositoryImpl(
    defaultConfigPath: configPath,
    lookup: (name) => dot[name] ?? '',
  );

  final config = _rightOrExit(
    await repository.loadConfig(configPath: configPath).run(),
    'load config',
  );

  final requestedProvider = parsed['provider'] as String?;
  final provider = _pickProvider(config, requestedProvider);
  if (provider == null) {
    _die('provider not found: ${requestedProvider ?? '(default)'}');
  }

  final requestedModel = parsed['model'] as String?;
  final model = _pickModel(provider, requestedModel);
  if (model == null) {
    _die(
      'model not found: ${requestedModel ?? '(default)'} for provider '
      '${provider.name}',
    );
  }

  final prompt = parsed['prompt'] as String?;
  final effectivePrompt = (prompt != null && prompt.isNotEmpty)
      ? prompt
      : await _readStdin();
  if (effectivePrompt.isEmpty) {
    _die('no prompt provided');
  }

  final factory = AiServiceFactoryImpl(configRepository: repository);
  final service = _rightOrExit(
    await factory
        .createAiService(providerName: provider.name, modelName: model.name)
        .run(),
    'create AI service',
  );

  final content = _rightOrExit(
    await service.generateContent(prompt: effectivePrompt).run(),
    'generate content',
  );
  stdout.writeln(content);
}

/// Returns the [Either]'s right value or prints [what]'s error and exits.
T _rightOrExit<T>(Either<Failure, T> either, String what) {
  return either.fold((failure) {
    stderr.writeln('ERROR while trying to $what: ${failure.message}');
    exit(1);
  }, (value) => value);
}

AiProvider? _pickProvider(Config config, String? requested) {
  if (requested == null) {
    for (final provider in config.providers) {
      if (provider.isDefault) return provider;
    }
    return config.providers.isEmpty ? null : config.providers.first;
  }
  for (final provider in config.providers) {
    if (provider.name == requested) return provider;
  }
  return null;
}

AiModel? _pickModel(AiProvider provider, String? requested) {
  if (requested == null) {
    if (provider.defaultModel != null) return provider.defaultModel;
    for (final model in provider.models) {
      if (model.isDefault) return model;
    }
    return provider.models.isEmpty ? null : provider.models.first;
  }
  for (final model in provider.models) {
    if (model.name == requested) return model;
  }
  return null;
}

Never _die(String message) {
  stderr.writeln('ERROR: $message');
  exit(1);
}

Future<String> _readStdin() async =>
    (await stdin.transform(utf8.decoder).join()).trim();

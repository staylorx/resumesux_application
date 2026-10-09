import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/config/config_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import 'package:yaml/yaml.dart';

/// Resolves an environment variable by name, returning an empty string when
/// unset. The default reads [Platform.environment]; a custom lookup can merge
/// in a gitignored `.env` file (which cannot reach `Platform.environment`,
/// since that map is read-only on Dart).
typedef EnvLookup = String Function(String name);

/// A [ConfigRepository] implementation that reads a YAML config file.
///
/// Providers configured in the file carry their base URL and model list, but
/// **no API keys** — each provider's key is resolved at runtime as
/// `RESUMESUX_<PROVIDER_NAME>_KEY` (see [resolveKey]). This lets folks bring
/// their own provider, key and model without a secret ever being committed.
class ConfigRepositoryImpl implements ConfigRepository {
  /// The config file path used when no [configPath] is supplied.
  final String defaultConfigPath;

  final EnvLookup _lookup;

  /// Creates a [ConfigRepositoryImpl] reading [defaultConfigPath] by default.
  ///
  /// [lookup] resolves environment variables used for provider API keys. It
  /// defaults to [_platformLookup] (reads [Platform.environment]); a caller
  /// that loads a gitignored `.env` file can pass a dotenv-merged lookup.
  ConfigRepositoryImpl({
    this.defaultConfigPath = 'config.yaml',
    EnvLookup? lookup,
  }) : _lookup = lookup ?? _platformLookup;

  /// Prefix for the environment variable that carries a provider's API key.
  static const String keyEnvPrefix = 'RESUMESUX_';

  /// Suffix for the environment variable that carries a provider's API key.
  static const String keyEnvSuffix = '_KEY';

  static String _platformLookup(String name) =>
      Platform.environment[name] ?? '';

  @override
  TaskEither<Failure, Config> loadConfig({String? configPath}) {
    return TaskEither.tryCatch(() async {
      final path = configPath ?? defaultConfigPath;
      final file = File(path);
      if (!file.existsSync()) {
        throw ConfigPathFailure('Config file not found: $path');
      }
      final content = await file.readAsString();
      return _parseConfig(loadYaml(content));
    }, _toFailure);
  }

  @override
  TaskEither<Failure, AiProvider> getProvider({
    required String providerName,
    String? configPath,
  }) {
    return loadConfig(configPath: configPath).flatMap((config) {
      for (final provider in config.providers) {
        if (provider.name == providerName) return TaskEither.right(provider);
      }
      return TaskEither.left(
        NotFoundFailure('AI provider not found in config: $providerName'),
      );
    });
  }

  @override
  TaskEither<Failure, AiProvider> getDefaultProvider({String? configPath}) {
    return loadConfig(configPath: configPath).flatMap((config) {
      for (final provider in config.providers) {
        if (provider.isDefault) return TaskEither.right(provider);
      }
      if (config.providers.isNotEmpty) {
        return TaskEither.right(config.providers.first);
      }
      return TaskEither.left(
        const NotFoundFailure('No AI providers configured'),
      );
    });
  }

  @override
  TaskEither<Failure, AiModel> getDefaultModel({String? configPath}) {
    return getDefaultProvider(configPath: configPath).flatMap((provider) {
      final model = _defaultModelOf(provider);
      if (model != null) return TaskEither.right(model);
      return TaskEither.left(
        NotFoundFailure('No default model for provider: ${provider.name}'),
      );
    });
  }

  @override
  bool hasDefaultModel({required AiProvider provider}) =>
      _defaultModelOf(provider) != null;

  /// Returns the provider's default model: an explicitly set [AiProvider.defaultModel],
  /// else the model flagged `isDefault`, else the first listed model, else none.
  AiModel? _defaultModelOf(AiProvider provider) {
    if (provider.defaultModel != null) return provider.defaultModel;
    for (final model in provider.models) {
      if (model.isDefault) return model;
    }
    return provider.models.isEmpty ? null : provider.models.first;
  }

  Config _parseConfig(Object? doc) {
    final source = _asMap(doc);
    final root = _asMap(source['config'] is Map ? source['config'] : source);
    final applicant = _parseApplicant(_asMapOrNull(root['applicant']));
    final providers = _parseProviders(_asMap(root['providers']));

    return Config(
      outputDir: _asString(root['outputDir'], 'output'),
      includeCover: _asBool(root['includeCover'], true),
      includeFeedback: _asBool(root['includeFeedback'], true),
      providers: providers,
      customPrompt: _asStringNullable(root['customPrompt']),
      appendPrompt: _asBool(root['appendPrompt'], false),
      applicant: applicant,
      digestPath: _asString(root['digestPath'], 'digest'),
      folderOrder: _parseFolderOrder(root['folderOrder']),
    );
  }

  List<AiProvider> _parseProviders(Map<String, dynamic> providers) {
    final result = <AiProvider>[];
    providers.forEach((name, raw) {
      final node = _asMap(raw);
      final models = _asList(node['models']).map((m) {
        final map = _asMap(m);
        return AiModel(
          name: _asString(map['name'], ''),
          isDefault: _asBool(map['default'], false),
          settings: _asMap(map['settings']),
        );
      }).toList();

      result.add(
        AiProvider(
          name: name.toString(),
          url: _asString(node['url'], ''),
          key: resolveKey(name.toString()),
          models: models,
          defaultModel: null,
          settings: _asMap(node['settings']),
          isDefault: _asBool(node['default'], false),
        ),
      );
    });
    return result;
  }

  /// The environment variable name that carries [providerName]'s API key:
  ///
  /// `$keyEnvPrefix` + the uppercased, non-alphanumeric-collapsed provider
  /// name + `$keyEnvSuffix` — e.g. provider `lmstudio` reads
  /// `RESUMESUX_LMSTUDIO_KEY`.
  String envKeyFor(String providerName) {
    final safeName = providerName.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '_',
    );
    return '$keyEnvPrefix$safeName$keyEnvSuffix';
  }

  /// Resolves [providerName]'s API key via [envKeyFor].
  ///
  /// An unset/blank value resolves to an empty key, which the request layer
  /// sends unauthenticated (fine for local providers like LM Studio/Ollama).
  String resolveKey(String providerName) =>
      _lookup(envKeyFor(providerName)).trim();

  Applicant _parseApplicant(Map<String, dynamic>? node) {
    if (node == null) {
      return const Applicant(name: '', email: '');
    }
    final addressNode = _asMapOrNull(node['address']);
    return Applicant(
      name: _asString(node['name'], ''),
      preferredName: _asStringNullable(node['preferred_name']),
      email: _asString(node['email'], ''),
      address: addressNode == null
          ? null
          : Address(
              street1: _asStringNullable(addressNode['street1']),
              street2: _asStringNullable(addressNode['street2']),
              city: _asStringNullable(addressNode['city']),
              state: _asStringNullable(addressNode['state']),
              zip: _asStringNullable(addressNode['zip']),
            ),
      phone: _asStringNullable(node['phone']),
      linkedin: _asStringNullable(node['linkedin']),
      github: _asStringNullable(node['github']),
      portfolio: _asStringNullable(node['portfolio']),
    );
  }

  List<FolderField>? _parseFolderOrder(Object? value) {
    if (value is! List) return null;
    return value.map((item) {
      return switch (item.toString()) {
        'applicant_name' => FolderField.applicant_name,
        'applicant_location' => FolderField.applicant_location,
        'jobreq_title' => FolderField.jobreq_title,
        'jobreq_location' => FolderField.jobreq_location,
        'concern' => FolderField.concern,
        'concern_location' => FolderField.concern_location,
        _ => FolderField.applicant_name,
      };
    }).toList();
  }

  Failure _toFailure(Object error, StackTrace stackTrace) {
    if (error is Failure) return error;
    if (error is FormatException) {
      return ParsingFailure('Invalid config YAML: $error');
    }
    return ServiceFailure('Failed to load config: $error');
  }

  static String _asString(Object? value, String fallback) =>
      value?.toString() ?? fallback;

  static String? _asStringNullable(Object? value) => value?.toString();

  static bool _asBool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static List<dynamic> _asList(Object? value) =>
      value is List ? value : const <dynamic>[];

  static Map<String, dynamic>? _asMapOrNull(Object? value) =>
      value is Map ? _asMap(value) : null;

  static Map<String, dynamic> _asMap(Object? value) => value is Map
      ? (value).map((k, v) => MapEntry(k.toString(), v))
      : const <String, dynamic>{};
}

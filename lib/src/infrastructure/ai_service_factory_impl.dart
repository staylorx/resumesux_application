import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/infrastructure/http_ai_service.dart';
import 'package:resumesux_application/src/repositories/config/config_repository.dart';
import 'package:resumesux_application/src/services/ai_service.dart';
import 'package:resumesux_application/src/services/ai_service_factory.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// An [AiServiceFactory] that builds an [HttpAiService] for a configured
/// provider, using the provider's resolved API key and the requested model.
class AiServiceFactoryImpl implements AiServiceFactory {
  /// The repository used to read provider configuration.
  final ConfigRepository configRepository;

  /// Creates an [AiServiceFactoryImpl] backed by [configRepository].
  AiServiceFactoryImpl({required this.configRepository});

  @override
  TaskEither<Failure, AiService> createAiService({
    required String providerName,
    String? configPath,
    String? modelName,
  }) {
    return configRepository
        .getProvider(providerName: providerName, configPath: configPath)
        .flatMap((provider) {
          final model = _resolveModel(provider, modelName);
          if (model == null) {
            return TaskEither.left(
              NotFoundFailure(
                'No model "${modelName ?? "(default)"}" for '
                'provider: ${provider.name}',
              ),
            );
          }
          return TaskEither.right(
            HttpAiService(
              baseUrl: provider.url,
              apiKey: provider.key,
              model: model.name,
              settings: model.settings,
            ),
          );
        });
  }

  /// Picks the requested model (by name), or falls back to the provider's
  /// default model ([AiProvider.defaultModel], an `isDefault`-flagged model,
  /// or the first listed model). Returns null when no model matches.
  AiModel? _resolveModel(AiProvider provider, String? modelName) {
    if (modelName != null) {
      for (final model in provider.models) {
        if (model.name == modelName) return model;
      }
      return null;
    }
    if (provider.defaultModel != null) return provider.defaultModel;
    for (final model in provider.models) {
      if (model.isDefault) return model;
    }
    return provider.models.isEmpty ? null : provider.models.first;
  }
}

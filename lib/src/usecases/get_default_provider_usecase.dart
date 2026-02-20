import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for retrieving the default AI provider from configuration.
class GetDefaultProviderUsecase {
  final ConfigRepository configRepository;

  /// Creates a new instance of [GetDefaultProviderUsecase].
  GetDefaultProviderUsecase({required this.configRepository});

  /// Retrieves the default AI provider from the configuration.
  ///
  /// Parameters:
  /// - [configPath]: Optional path to the config file. If null, uses default.
  ///
  /// Returns: [TaskEither<Failure, AiProvider>] containing the default provider or a failure.
  TaskEither<Failure, AiProvider> call({String? configPath}) {
    return configRepository.getDefaultProvider(configPath: configPath);
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/config/config_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for retrieving the default AI provider from configuration.
class GetDefaultProviderUsecase {
  /// The repository used to read the configuration.
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

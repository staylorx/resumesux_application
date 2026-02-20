import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for loading application configuration.
class GetConfigUsecase {
  final ConfigRepository configRepository;

  /// Creates a new instance of [GetConfigUsecase].
  GetConfigUsecase({required this.configRepository});

  /// Loads the configuration from the specified path or default.
  ///
  /// Parameters:
  /// - [configPath]: Optional path to the config file. If null, uses default.
  ///
  /// Returns: [TaskEither<Failure, Config>] containing the loaded configuration or a failure.
  TaskEither<Failure, Config> call({String? configPath}) {
    return configRepository.loadConfig(configPath: configPath);
  }
}

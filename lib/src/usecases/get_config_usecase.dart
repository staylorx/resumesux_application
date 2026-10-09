import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/config/config_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for loading application configuration.
class GetConfigUsecase {
  /// The repository used to load the configuration.
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

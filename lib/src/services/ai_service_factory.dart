import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

// TODO: move out to a different package (e.g., resumesux_data) to avoid coupling with the application layer.
/// Abstract factory for creating AiService instances.
abstract class AiServiceFactory {
  /// Creates an AI service for the specified provider.
  ///
  /// Parameters:
  /// - [providerName]: The name of the AI provider to use.
  /// - [configPath]: Optional path to the config file. If null, uses default.
  ///
  /// Returns: [TaskEither<Failure, AiService>] containing the created AI service or a failure.
  TaskEither<Failure, AiService> createAiService({
    required String providerName,
    String? configPath,
  });
}

import 'package:fpdart/fpdart.dart';
import '../failure.dart';

// TODO: move out to a different package (e.g., resumesux_data) to avoid coupling with the application layer.
/// Abstract service for AI content generation.
abstract class AiService {
  /// Generates content using AI based on the provided prompt.
  TaskEither<Failure, String> generateContent({required String prompt});
}

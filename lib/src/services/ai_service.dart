import 'package:fpdart/fpdart.dart';
import '../failure.dart';

/// Abstract service for AI content generation.
abstract class AiService {
  /// Generates content using AI based on the provided prompt.
  TaskEither<Failure, String> generateContent({required String prompt});
}

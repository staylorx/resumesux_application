import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for saving AI responses for assets to the database.
class SaveAssetAiResponseUsecase {
  final AssetRepository assetRepository;

  /// Creates a new instance of [SaveAssetAiResponseUsecase].
  SaveAssetAiResponseUsecase({required this.assetRepository});

  /// Saves AI responses for assets.
  ///
  /// Parameters:
  /// - [jobReqId]: The job requirement ID.
  ///
  /// Returns: [TaskEither<Failure, Unit>] indicating success or failure.
  TaskEither<Failure, Unit> call({required String jobReqId}) {
    final assetAiResponseJson = assetRepository.getLastAiResponsesJson();
    if (assetAiResponseJson != null) {
      return assetRepository.saveAiResponse(
        aiResponseJson: assetAiResponseJson,
        jobReqId: jobReqId,
      ).orElse((_) => TaskEither.right(unit));
    }
    return TaskEither.right(unit);
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../../failure.dart';

/// Repository for asset-related operations.
abstract class AssetRepository {
  /// Retrieves all assets.
  TaskEither<Failure, List<Asset>> getAllAssets();

  TaskEither<Failure, List<AssetWithHandle>> getAll(); // For listing

  /// Saves an asset.
  TaskEither<Failure, Unit> save({
    required AssetHandle handle,
    required Asset asset,
  });

  /// Retrieves the last AI responses as JSON string.
  String? getLastAiResponsesJson();

  /// Saves the AI responses JSON for assets to the database.
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String jobReqId,
  });
}

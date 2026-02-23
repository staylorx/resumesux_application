import 'dart:convert';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for extracting assets from digest markdown files.
class ExtractAssetsFromDigestUsecase {
  final AiService aiService;
  final AssetRepository assetRepository;

  /// Creates a new instance of [ExtractAssetsFromDigestUsecase].
  ExtractAssetsFromDigestUsecase({
    required this.aiService,
    required this.assetRepository,
  });

  /// Extracts assets from the digest path and saves them to the repository.
  TaskEither<Failure, Unit> call({required String digestPath}) {
    return TaskEither.tryCatch(
      () async {
        final assetsDir = Directory('$digestPath/assets');
        if (!assetsDir.existsSync()) {
          return unit;
        }

        final files = assetsDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.md'));

        for (final file in files) {
          final content = await file.readAsString();
          final data = await _extractAssetData(content, file.path);
          if (data != null) {
            final tagStrings =
                (data['tags'] as List<dynamic>?)?.cast<String>() ??
                [_getAssetType(path: file.path)];
            final tags = Tags.fromList(tagStrings);
            final asset = Asset(tags: tags, content: content);

            // Save to repository
            final handle = AssetHandle('asset_${asset.content.hashCode}');
            await assetRepository.save(handle: handle, asset: asset).run();
          }
        }

        return unit;
      },
      (error, stackTrace) => error is Failure
          ? error
          : ServiceFailure('Failed to extract assets from digest: $error'),
    );
  }

  Future<Map<String, dynamic>?> _extractAssetData(
    String content,
    String path,
  ) async {
    final prompt =
        '''
Please analyze the following asset content and extract the following information in JSON format:

- tags: List of tags describing the asset

File path: $path
The file path may contain information about the asset type, etc. Use this to infer tags if the content is ambiguous.

Return only valid JSON like:
{
  "tags": ["certifications", "experience"]
}

Do your best, but if information is absolutely not present, use appropriate tags based on the file path.

Asset content:
$content
''';

    final aiResult = await aiService.generateContent(prompt: prompt).run();
    if (aiResult.isLeft()) {
      return null;
    }
    final aiResponse = aiResult.getOrElse((_) => '');

    try {
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0) return null;
      final jsonString = aiResponse.substring(jsonStart, jsonEnd);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  String _getAssetType({required String path}) {
    final parts = path.split(Platform.pathSeparator);
    final assetsIndex = parts.indexWhere((part) => part == 'assets');
    if (assetsIndex != -1 && assetsIndex + 1 < parts.length) {
      final nextPart = parts[assetsIndex + 1];
      if (nextPart.contains('.')) {
        // It's a file, get the name without extension
        return nextPart.split('.').first;
      } else {
        // It's a subdirectory
        return nextPart;
      }
    }
    return 'unknown';
  }
}

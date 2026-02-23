import 'dart:convert';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for extracting an applicant from digest files
class ExtractApplicantFromDigestUseCase {
  final AiService aiService;
  final GigRepository gigRepository;
  final AssetRepository assetRepository;
  final ApplicantRepository applicantRepository;
  final HandleGenerator handleGenerator;

  ExtractApplicantFromDigestUseCase({
    required this.aiService,
    required this.gigRepository,
    required this.assetRepository,
    required this.applicantRepository,
    required this.handleGenerator,
  });

  TaskEither<Failure, ApplicantHandle> call({
    required Applicant applicant,
    required String digestPath,
  }) {
    return TaskEither.tryCatch(
      () async {
        final handle = handleGenerator.generateApplicantHandle();

        // Extract gigs
        final gigs = await _extractGigs(digestPath);

        // Extract assets
        final assets = await _extractAssets(digestPath);

        // Create updated applicant
        final updatedApplicant = applicant.copyWith(gigs: gigs, assets: assets);

        // Save applicant
        final saveResult = await applicantRepository
            .create(item: updatedApplicant)
            .run();

        if (saveResult.isLeft()) {
          throw saveResult.getLeft().toNullable()!;
        }

        return handle;
      },
      (error, stackTrace) => error is Failure
          ? error
          : ServiceFailure('Failed to extract applicant from digest: $error'),
    );
  }

  Future<List<Gig>> _extractGigs(String digestPath) async {
    final gigs = <Gig>[];
    final gigsDir = Directory('$digestPath/gigs');
    if (!gigsDir.existsSync()) {
      return gigs;
    }

    final files = gigsDir.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.md'),
    );

    for (final file in files) {
      final content = await file.readAsString();
      final data = await _extractGigData(content, file.path);
      if (data != null) {
        final gig = Gig(
          title: data['title'] as String? ?? 'Unknown',
          concern: data['concern'] != null
              ? Concern(name: data['concern'] as String)
              : null,
          location: data['location'] as String?,
          dates: data['dates'] as String?,
          achievements: (data['achievements'] as List<dynamic>?)
              ?.cast<String>(),
        );
        gigs.add(gig);
      }
    }

    return gigs;
  }

  Future<List<Asset>> _extractAssets(String digestPath) async {
    final assets = <Asset>[];
    final assetsDir = Directory('$digestPath/assets');
    if (!assetsDir.existsSync()) {
      return assets;
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
        assets.add(asset);
      }
    }

    return assets;
  }

  Future<Map<String, dynamic>?> _extractGigData(
    String content,
    String path,
  ) async {
    final prompt =
        '''
Please analyze the following gig/work experience content and extract the following information in JSON format:

- title: The job title
- concern: The company or organization name
- location: The job location
- dates: The employment dates
- achievements: List of achievements or responsibilities

File path: $path
The file path may contain information about the company, job title, location, etc. Use this to infer missing details if the content is ambiguous.

Return only valid JSON like:
{
  "title": "Software Engineer",
  "concern": "Tech Company Inc.",
  "location": "San Francisco, CA",
  "dates": "Jan 2020 - Dec 2022",
  "achievements": ["Developed new features", "Improved performance"]
}

Do your best, but if information is absolutely not present, use 'Unknown' for strings or empty list for achievements. Make no assumptions beyond the content provided and the file path.

Gig content:
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

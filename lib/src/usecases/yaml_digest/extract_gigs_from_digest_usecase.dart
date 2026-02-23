import 'dart:convert';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for extracting gigs from digest markdown files.
class ExtractGigsFromDigestUsecase {
  final AiService aiService;
  final GigRepository gigRepository;

  /// Creates a new instance of [ExtractGigsFromDigestUsecase].
  ExtractGigsFromDigestUsecase({
    required this.aiService,
    required this.gigRepository,
  });

  /// Extracts gigs from the digest path and saves them to the repository.
  TaskEither<Failure, Unit> call({required String digestPath}) {
    return TaskEither.tryCatch(
      () async {
        final gigsDir = Directory('$digestPath/gigs');
        if (!gigsDir.existsSync()) {
          return unit;
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

            // Save to repository
            final handle = GigHandle('gig_${gig.title.hashCode}');
            await gigRepository.save(handle: handle, gig: gig).run();
          }
        }

        return unit;
      },
      (error, stackTrace) => error is Failure
          ? error
          : ServiceFailure('Failed to extract gigs from digest: $error'),
    );
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
}

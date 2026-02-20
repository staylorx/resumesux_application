import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for creating a new job requirement from a file.
class ExtractJobReqFromFileUsecase {
  final JobReqRepository jobReqRepository;
  final AiService aiService;
  final FileRepository fileRepository;

  /// Creates a new instance of [ExtractJobReqFromFileUsecase].
  ExtractJobReqFromFileUsecase({
    required this.jobReqRepository,
    required this.aiService,
    required this.fileRepository,
  });

  /// Creates a new job requirement.
  ///
  /// Parameters:
  /// - [path]: Optional path to a job requirement file to extract data from.
  /// - [title]: The job title (required if path is not provided).
  /// - [content]: The job description content (required if path is not provided).
  /// - [salary]: Optional salary information.
  /// - [location]: Optional job location.
  /// - [concern]: Optional company concern.
  /// - [whereFound]: Optional source where the job was found.
  ///
  /// Returns: [TaskEither<Failure, JobReq>] the created job requirement or a failure.
  TaskEither<Failure, JobReq> call({
    String? path,
    String? title,
    String? content,
    String? salary,
    String? location,
    Concern? concern,
    String? whereFound,
  }) {
    if (path != null) {
      return _extractJobReqData(path: path).flatMap((data) {
        final finalTitle = data['title'] as String? ?? 'Unknown';
        final finalContent = data['content'] as String? ?? '';
        final finalSalary = data['salary'] as String?;
        final finalLocation = data['location'] as String?;
        final finalConcern = data['concern'] != null
            ? Concern(name: data['concern'] as String)
            : null;
        final finalWhereFound = data['whereFound'] as String?;

        return _createJobReq(
          title: finalTitle,
          content: finalContent,
          salary: finalSalary ?? salary,
          location: finalLocation ?? location,
          concern: finalConcern ?? concern,
          whereFound: finalWhereFound ?? whereFound,
        );
      });
    } else {
      if ((title?.isEmpty ?? true) || (content?.isEmpty ?? true)) {
        return TaskEither.left(ValidationFailure(
          'title and content are required when path is not provided',
        ));
      }
      return _createJobReq(
        title: title!,
        content: content!,
        salary: salary,
        location: location,
        concern: concern,
        whereFound: whereFound,
      );
    }
  }

  TaskEither<Failure, Map<String, dynamic>> _extractJobReqData({
    required String path,
  }) {
    return TaskEither<Failure, String>.tryCatch(
      () async {
        final contentResult = fileRepository.readFile(path: path);
        return contentResult.fold(
          (failure) => throw failure,
          (content) => content,
        );
      },
      (error, stackTrace) => error is Failure
          ? error
          : ParsingFailure('Failed to read file: $error'),
    ).flatMap((content) {
      final prompt = _buildExtractionPrompt(content: content, path: path);
      return aiService.generateContent(prompt: prompt).flatMap((aiResponse) {
        final extractedData = _parseAiResponse(aiResponse);
        if (extractedData == null) {
          return TaskEither.left(
            ParsingFailure('Failed to parse AI response as JSON'),
          );
        }
        return TaskEither.right(extractedData);
      });
    });
  }

  TaskEither<Failure, JobReq> _createJobReq({
    required String title,
    required String content,
    String? salary,
    String? location,
    Concern? concern,
    String? whereFound,
  }) {
    final createdDate = DateTime.now();
    final jobReq = JobReq(
      title: title,
      content: content,
      salary: salary,
      location: location,
      concern: concern,
      createdDate: createdDate,
      whereFound: whereFound,
    );
    return jobReqRepository.createJobReq(jobReq: jobReq);
  }

  String _buildExtractionPrompt({
    required String content,
    required String path,
  }) {
    return '''
Please analyze the following job requirement content and extract the following information in JSON format:

- title: The job title
- salary: The salary information (if mentioned, otherwise null)
- location: The job location (if mentioned, otherwise null)
- concern: The company or organization name (if mentioned, otherwise null)

File path: $path
The file path may contain information about the concern (company), job title, location, etc. Use this to infer missing details if the content is ambiguous.

Return only valid JSON like:
{
  "title": "Software Engineer",
  "salary": "\$100,000 - \$120,000",
  "location": "San Francisco, CA",
  "concern": "Tech Company Inc."
}

Do your best, but if information is absolutely not present, use 'Unknown'. Make no assumptions beyond the content provided and the file path.


Job requirement content:
$content
''';
  }

  Map<String, dynamic>? _parseAiResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0) return null;
      final jsonString = response.substring(jsonStart, jsonEnd);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

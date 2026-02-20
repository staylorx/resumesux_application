import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../failure.dart';

/// Repository for file operations.
/// Provides abstraction for reading, writing, and managing files and directories.
abstract class FileRepository {
  /// Reads the content of a file at the given path.
  /// Returns the file content or a failure.
  Either<Failure, String> readFile({required String path});

  /// Writes content to a file at the given path.
  /// Returns success or a failure.
  TaskEither<Failure, Unit> writeFile({
    required String path,
    required String content,
  });

  /// Creates a directory at the given path if it doesn't exist.
  /// Returns success or a failure.
  Either<Failure, Unit> createDirectory({required String path});

  /// Validates that the directory is accessible for writing.
  /// Returns success or a failure.
  Either<Failure, Unit> validateDirectory({required String path});

  /// Creates the application directory path for the given job requirement and applicant.
  /// Returns the path to the application directory.
  ///
  /// The directory structure is determined by the config's folderOrder.
  Either<Failure, String> createApplicationDirectory({
    required String baseOutputDir,
    required JobReq jobReq,
    required Applicant applicant,
    required Config config,
  });

  /// Gets the path for the resume file in the application directory.
  String getResumeFilePath({required String appDir, required String jobTitle});

  /// Gets the path for the cover letter file in the application directory.
  String getCoverLetterFilePath({
    required String appDir,
    required String jobTitle,
  });

  /// Gets the path for the feedback file in the application directory.
  String getFeedbackFilePath({required String appDir});

  /// Gets the path for the AI response file in the application directory.
  /// The file name includes the type to distinguish between different AI calls.
  String getAiResponseFilePath({required String appDir, required String type});

  /// Validates that all Markdown files in the directory are valid Markdown.
  TaskEither<Failure, Unit> validateMarkdownFiles({
    required String directory,
    required String fileExtension,
  });
}

import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../failure.dart';

/// Repository for managing Application entities.
abstract class ApplicationRepository {
  /// Saves the application artifacts (resume, cover letter, feedback) to the specified output directory.
  TaskEither<Failure, Unit> saveApplicationArtifacts({
    required Application application,
    required Config config,
    required String outputDir,
  });

  TaskEither<Failure, Unit> save({
    required ApplicationHandle handle,
    required Application application,
  });
  TaskEither<Failure, Application> getByHandle({
    required ApplicationHandle handle,
  });
  TaskEither<Failure, List<ApplicationWithHandle>> getAll(); // For listing
}

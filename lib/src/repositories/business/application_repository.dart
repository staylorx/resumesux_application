import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/repositories/basic_crud_contract.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../../failure.dart';

/// Repository for managing Application entities.
abstract class ApplicationRepository
    implements BasicCrudContract<Application, String, ApplicationWithHandle> {
  /// Saves the application artifacts (resume, cover letter, feedback) to the specified output directory.
  TaskEither<Failure, Unit> saveApplicationArtifacts({
    required Application application,
    required Config config,
    required String outputDir,
  });
}

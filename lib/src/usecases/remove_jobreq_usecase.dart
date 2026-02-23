import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for removing a job req
class RemoveJobReqUsecase {
  final JobReqRepository jobReqRepository;

  /// Creates a new instance of [RemoveJobReqUsecase].
  RemoveJobReqUsecase({required this.jobReqRepository});

  /// Remove the job req
  TaskEither<Failure, Unit> call({required String handle}) {
    return jobReqRepository.deleteByHandle(handle: handle);
  }
}

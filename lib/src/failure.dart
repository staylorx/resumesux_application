/// Base abstract class for representing failures in functional programming patterns,
/// such as those used with the Either type from the dartz package.
/// This class provides a standard way to encapsulate error information.
abstract class Failure {
  /// The error message describing the failure.
  final String message;

  /// Creates a [Failure] with the given [message].
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class ServiceFailure extends Failure {
  const ServiceFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class DatabaseConnectionFailure extends Failure {
  const DatabaseConnectionFailure(super.message);
}

class DatabaseReadFailure extends Failure {
  const DatabaseReadFailure(super.message);
}

class DatabaseWriteFailure extends Failure {
  const DatabaseWriteFailure(super.message);
}

class DatabaseConstraintFailure extends Failure {
  const DatabaseConstraintFailure(super.message);
}

class DataParsingFailure extends Failure {
  const DataParsingFailure(super.message);
}

class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}

class EnvironmentFailure extends Failure {
  const EnvironmentFailure(super.message);
}

class ConfigPathFailure extends Failure {
  const ConfigPathFailure(super.message);
}

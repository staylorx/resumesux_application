/// Base abstract class for representing failures in functional programming patterns,
/// such as those used with the Either type from the dartz package.
/// This class provides a standard way to encapsulate error information.
abstract class Failure {
  /// The error message describing the failure.
  final String message;

  /// Creates a [Failure] with the given [message].
  const Failure(this.message);
}

/// A [Failure] representing an error that occurred while interacting with a
/// database.
class DatabaseFailure extends Failure {
  /// Creates a [DatabaseFailure] with the given [message].
  const DatabaseFailure(super.message);
}

/// A [Failure] representing a validation error, such as invalid input data.
class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure] with the given [message].
  const ValidationFailure(super.message);
}

/// A [Failure] representing that a requested resource could not be found.
class NotFoundFailure extends Failure {
  /// Creates a [NotFoundFailure] with the given [message].
  const NotFoundFailure(super.message);
}

/// A [Failure] representing that the current user lacks the required
/// permissions to perform an operation.
class PermissionFailure extends Failure {
  /// Creates a [PermissionFailure] with the given [message].
  const PermissionFailure(super.message);
}

/// A [Failure] representing an unexpected error from a service or service
/// layer.
class ServiceFailure extends Failure {
  /// Creates a [ServiceFailure] with the given [message].
  const ServiceFailure(super.message);
}

/// A [Failure] representing a network error, such as a lost connection.
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure] with the given [message].
  const NetworkFailure(super.message);
}

/// A [Failure] representing an error that occurred while parsing data.
class ParsingFailure extends Failure {
  /// Creates a [ParsingFailure] with the given [message].
  const ParsingFailure(super.message);
}

/// A [Failure] representing an error that occurred while establishing a
/// database connection.
class DatabaseConnectionFailure extends Failure {
  /// Creates a [DatabaseConnectionFailure] with the given [message].
  const DatabaseConnectionFailure(super.message);
}

/// A [Failure] representing an error that occurred while reading from a
/// database.
class DatabaseReadFailure extends Failure {
  /// Creates a [DatabaseReadFailure] with the given [message].
  const DatabaseReadFailure(super.message);
}

/// A [Failure] representing an error that occurred while writing to a
/// database.
class DatabaseWriteFailure extends Failure {
  /// Creates a [DatabaseWriteFailure] with the given [message].
  const DatabaseWriteFailure(super.message);
}

/// A [Failure] representing a violation of a database constraint.
class DatabaseConstraintFailure extends Failure {
  /// Creates a [DatabaseConstraintFailure] with the given [message].
  const DatabaseConstraintFailure(super.message);
}

/// A [Failure] representing an error that occurred while parsing data.
class DataParsingFailure extends Failure {
  /// Creates a [DataParsingFailure] with the given [message].
  const DataParsingFailure(super.message);
}

/// A [Failure] representing an error from the underlying platform.
class PlatformFailure extends Failure {
  /// Creates a [PlatformFailure] with the given [message].
  const PlatformFailure(super.message);
}

/// A [Failure] representing an error related to the runtime environment.
class EnvironmentFailure extends Failure {
  /// Creates an [EnvironmentFailure] with the given [message].
  const EnvironmentFailure(super.message);
}

/// A [Failure] representing an error related to a configuration path.
class ConfigPathFailure extends Failure {
  /// Creates a [ConfigPathFailure] with the given [message].
  const ConfigPathFailure(super.message);
}

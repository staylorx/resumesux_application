import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Abstract Unit of Work for managing transactions across repositories.
abstract class UnitOfWork {
  /// Runs an operation within a transaction.
  /// The operation receives a Transaction handle and returns a `TaskEither<Failure, T>`.
  /// The transaction is committed if the operation succeeds, rolled back on failure.
  TaskEither<Failure, T> run<T>(
    TaskEither<Failure, T> Function(Transaction txn) operation,
  );

  /// Manually commits the current transaction.
  TaskEither<Failure, Unit> commit();

  /// Manually rolls back the current transaction.
  TaskEither<Failure, Unit> rollback();
}

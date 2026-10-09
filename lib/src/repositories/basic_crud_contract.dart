import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/transaction.dart';

/// A contract for basic create, read, update, and delete (CRUD) operations on
/// a repository using [TaskEither] for functional error handling.
///
/// [T] is the input item type used for creation, [TH] is the handle type used
/// to identify entries, and [TWH] is the with-handle item type returned by the
/// repository.
abstract class BasicCrudContract<T, TH, TWH> {
  /// Creates a new entry from [item] and returns it with its handle, or a
  /// [Failure] on error.
  TaskEither<Failure, TWH> create({required T item, Transaction? txn});

  /// Returns all entries with their handles, or a [Failure] on error.
  TaskEither<Failure, List<TWH>> getAll();

  /// Returns the entry identified by [handle], or a [Failure] on error.
  TaskEither<Failure, TWH> getByHandle({required TH handle});

  /// Deletes all entries, or returns a [Failure] on error.
  TaskEither<Failure, Unit> deleteAll({Transaction? txn});

  /// Deletes the entry identified by [handle], or returns a [Failure] on
  /// error.
  TaskEither<Failure, Unit> deleteByHandle({
    required TH handle,
    Transaction? txn,
  });

  /// Updates the given [item] and returns it with its handle, or a [Failure]
  /// on error.
  TaskEither<Failure, TWH> update({required TWH item, Transaction? txn});
}

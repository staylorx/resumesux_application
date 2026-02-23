import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

abstract class BasicCrudContract<T> {
  TaskEither<Failure, T> create({required T item, Transaction? txn});

  TaskEither<Failure, List<T>> getAll();

  TaskEither<Failure, T> getByHandle({required String handle});

  TaskEither<Failure, Unit> deleteAll({Transaction? txn});

  TaskEither<Failure, Unit> deleteByHandle({
    required String handle,
    Transaction? txn,
  });

  TaskEither<Failure, T> update({required T item, Transaction? txn});
}

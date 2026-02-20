import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

abstract class BasicCrudContract<T> {
  TaskEither<Failure, T> create({required T item, Transaction? txn});

  TaskEither<Failure, List<T>> getAll();

  TaskEither<Failure, T> getById({required String id});

  TaskEither<Failure, Unit> deleteAll({Transaction? txn});

  TaskEither<Failure, Unit> deleteById({required T item, Transaction? txn});

  TaskEither<Failure, T> update({required T item, Transaction? txn});
}

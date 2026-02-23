import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

abstract class BasicCrudContract<T, TH, TWH> {
  TaskEither<Failure, TWH> create({required T item, Transaction? txn});

  TaskEither<Failure, List<TWH>> getAll();

  TaskEither<Failure, TWH> getByHandle({required TH handle});

  TaskEither<Failure, Unit> deleteAll({Transaction? txn});

  TaskEither<Failure, Unit> deleteByHandle({
    required TH handle,
    Transaction? txn,
  });

  TaskEither<Failure, TWH> update({required TWH item, Transaction? txn});
}

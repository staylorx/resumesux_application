/// Abstract transaction interface for database operations.
abstract class Transaction {
  /// Gets the database handle for the transaction.
  dynamic get db;
}

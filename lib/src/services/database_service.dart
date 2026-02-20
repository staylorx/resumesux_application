/// Abstract interface for database operations to allow swapping implementations (e.g., Sembast, Hive, SQLite).
// TODO: move out to a different package (e.g., resumesux_data) to avoid coupling with the application layer.
abstract class DatabaseService {
  /// Initializes the database.
  Future<void> initialize();

  /// Stores a value in the specified store with the given key.
  Future<void> put({
    required String storeName,
    required String key,
    required Map<String, dynamic> value,
    dynamic transaction,
  });

  /// Retrieves a value from the specified store by key.
  Future<Map<String, dynamic>?> get({
    required String storeName,
    required String key,
    dynamic transaction,
  });

  /// Finds all records in the specified store.
  Future<List<Map<String, dynamic>>> find({
    required String storeName,
    dynamic transaction,
  });

  /// Drops the specified store.
  Future<void> drop({required String storeName, dynamic transaction});

  /// Deletes a record from the specified store by key.
  Future<void> delete({
    required String storeName,
    required String key,
    dynamic transaction,
  });
}

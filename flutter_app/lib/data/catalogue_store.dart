/// Durable local state, independent of the synchronization provider.
///
/// Write the snapshot, pending operations and conflict history atomically. A
/// failed write must leave the previous state readable. Credentials do not
/// belong in this document. Implementations own their database lifecycle.
abstract interface class CatalogueStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> state);
}

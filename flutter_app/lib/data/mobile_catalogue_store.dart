import 'dart:convert';

import 'package:sqflite/sqflite.dart' as sql;

import 'catalogue_store.dart';

export 'catalogue_store.dart';

class SqliteCatalogueStore implements CatalogueStore {
  SqliteCatalogueStore(this.scope, {this.factory, this.path});
  final String scope;
  final sql.DatabaseFactory? factory;
  final String? path;
  Future<sql.Database>? _database;

  Future<sql.Database> get _db => _database ??= _open();

  Future<sql.Database> _open() async {
    final databaseFactory = factory ?? sql.databaseFactory;
    final databasePath =
        path ??
        '${await databaseFactory.getDatabasesPath()}/bona_mangxo_catalogue.sqlite3';
    return databaseFactory.openDatabase(
      databasePath,
      options: sql.OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute(
          'CREATE TABLE catalogues (scope TEXT PRIMARY KEY, document TEXT NOT NULL)',
        ),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    // Android's CursorWindow cannot return the multi-megabyte catalogue in
    // one field. Slice inside SQLite, including for existing version-1 files.
    // One transaction keeps all chunks on the same snapshot during writes.
    return (await _db).transaction((txn) async {
      final sizes = await txn.rawQuery(
        'SELECT length(document) AS size FROM catalogues WHERE scope = ?',
        [scope],
      );
      if (sizes.isEmpty) return null;
      final length = sizes.single['size'] as int;
      const chunkSize = 64 * 1024;
      final document = StringBuffer();
      for (var offset = 1; offset <= length; offset += chunkSize) {
        final rows = await txn.rawQuery(
          'SELECT substr(document, ?, ?) AS chunk FROM catalogues WHERE scope = ?',
          [offset, chunkSize, scope],
        );
        document.write(rows.single['chunk'] as String);
      }
      return jsonDecode(document.toString()) as Map<String, dynamic>;
    });
  }

  @override
  Future<void> write(Map<String, dynamic> state) async {
    await (await _db).transaction(
      (txn) => txn.insert('catalogues', {
        'scope': scope,
        'document': jsonEncode(state),
      }, conflictAlgorithm: sql.ConflictAlgorithm.replace),
    );
  }

  /// Used by isolated persistence/device checks to genuinely reopen the file.
  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null) {
      await (await database).close();
    }
  }
}

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _databaseName = 'dispensiamo.db';
  static const _databaseVersion = 1;
  static const _tableName = 'products';
  static Future<Database>? _database;

  static Future<Database> get _db => _database ??= _openDatabase();

  static Future<Database> _openDatabase() async {
    final databasePath = path.join(
      await getDatabasesPath(),
      _databaseName,
    );
    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final db = await _db;
    await db.transaction((transaction) async {
      for (final product in products) {
        final name = product['name'];
        final price = product['price'];
        if (name is! String ||
            name.trim().isEmpty ||
            price is! num ||
            !price.isFinite) {
          throw ArgumentError(
              'Ogni prodotto deve avere nome e prezzo numerico.');
        }

        await transaction.insert(_tableName, {
          'name': name.trim(),
          'price': price,
        });
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getPaginatedProducts(
      String? lastDocId) async {
    final db = await _db;
    final lastId = lastDocId == null ? null : int.parse(lastDocId);
    final rows = await db.query(
      _tableName,
      columns: ['id', 'name', 'price'],
      where: lastId == null ? null : 'id > ?',
      whereArgs: lastId == null ? null : [lastId],
      orderBy: 'id ASC',
      limit: 10,
    );

    return rows
        .map((row) => {
              ...row,
              'id': row['id'].toString(),
            })
        .toList();
  }
}

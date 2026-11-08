import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const productsPageSize = 10;
  static const _databaseName = 'dispensiamo.db';
  static const _databaseVersion = 2;
  static const _tableName = 'products';
  static const _settingsTableName = 'settings';
  static const _webProductsKey = 'dispensiamo.products';
  static const _webNextProductIdKey = 'dispensiamo.nextProductId';
  static const _webSettingPrefix = 'dispensiamo.setting.';
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
            price REAL NOT NULL,
            expiration_date TEXT,
            alert_days INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE $_settingsTableName (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN expiration_date TEXT',
          );
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN alert_days INTEGER',
          );
          await db.execute('''
            CREATE TABLE $_settingsTableName (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<int> saveProduct(Map<String, dynamic> product) async {
    final values = _validatedProductValues(product);
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      final products = await _getWebProducts(preferences);
      final nextId = preferences.getInt(_webNextProductIdKey) ?? 1;
      products.add({'id': nextId, ...values});
      await preferences.setString(_webProductsKey, jsonEncode(products));
      await preferences.setInt(_webNextProductIdKey, nextId + 1);
      return nextId;
    }

    final db = await _db;
    return db.insert(_tableName, values);
  }

  static Future<void> updateProduct(
    String id,
    Map<String, dynamic> product,
  ) async {
    final values = _validatedProductValues(product);
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      final products = await _getWebProducts(preferences);
      final productId = int.parse(id);
      final index = products.indexWhere((item) => item['id'] == productId);
      if (index == -1) return;
      products[index] = {'id': productId, ...values};
      await preferences.setString(_webProductsKey, jsonEncode(products));
      return;
    }

    final db = await _db;
    await db.update(
      _tableName,
      values,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  static Future<void> deleteProduct(String id) async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      final products = await _getWebProducts(preferences);
      products.removeWhere((product) => product['id'] == int.parse(id));
      await preferences.setString(_webProductsKey, jsonEncode(products));
      return;
    }

    final db = await _db;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  static Map<String, Object?> _validatedProductValues(
    Map<String, dynamic> product,
  ) {
    final name = product['name'];
    final price = product['price'];
    final expirationDate = product['expiration_date'];
    final alertDays = product['alert_days'];
    if (name is! String ||
        name.trim().isEmpty ||
        price is! num ||
        !price.isFinite ||
        price < 0 ||
        (expirationDate != null && expirationDate is! String) ||
        (expirationDate is String &&
            DateTime.tryParse(expirationDate) == null) ||
        (alertDays != null &&
            (alertDays is! int || alertDays < 0 || alertDays > 30))) {
      throw ArgumentError(
        'Ogni prodotto deve avere un nome, un prezzo valido e una scadenza valida.',
      );
    }

    return {
      'name': name.trim(),
      'price': price,
      'expiration_date': expirationDate,
      'alert_days': alertDays,
    };
  }

  static Future<List<Map<String, dynamic>>> getPaginatedProducts(
      String? lastDocId) async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      final lastId = lastDocId == null ? null : int.parse(lastDocId);
      final products = await _getWebProducts(preferences);
      final filteredProducts = products
          .where((product) => lastId == null || (product['id'] as int) > lastId)
          .take(productsPageSize)
          .toList();
      return filteredProducts.map(_productMap).toList();
    }

    final db = await _db;
    final lastId = lastDocId == null ? null : int.parse(lastDocId);
    final rows = await db.query(
      _tableName,
      columns: ['id', 'name', 'price', 'expiration_date', 'alert_days'],
      where: lastId == null ? null : 'id > ?',
      whereArgs: lastId == null ? null : [lastId],
      orderBy: 'id ASC',
      limit: productsPageSize,
    );

    return rows.map(_productMap).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      return (await _getWebProducts(preferences)).map(_productMap).toList();
    }

    final db = await _db;
    final rows = await db.query(
      _tableName,
      columns: ['id', 'name', 'price', 'expiration_date', 'alert_days'],
      orderBy: 'id ASC',
    );
    return rows.map(_productMap).toList();
  }

  static Map<String, dynamic> _productMap(Map<String, Object?> row) => {
        ...row,
        'id': row['id'].toString(),
      };

  static Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString('$_webSettingPrefix$key');
    }

    final db = await _db;
    final rows = await db.query(
      _settingsTableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('$_webSettingPrefix$key', value);
      return;
    }

    final db = await _db;
    await db.insert(
      _settingsTableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> _getWebProducts(
    SharedPreferences preferences,
  ) async {
    final encodedProducts = preferences.getString(_webProductsKey);
    if (encodedProducts == null) return [];
    final decodedProducts = jsonDecode(encodedProducts);
    if (decodedProducts is! List) {
      throw const FormatException('I prodotti salvati non sono validi.');
    }
    return decodedProducts.map((product) {
      if (product is! Map) {
        throw const FormatException('Un prodotto salvato non è valido.');
      }
      return Map<String, dynamic>.from(product);
    }).toList()
      ..sort((first, second) =>
          (first['id'] as int).compareTo(second['id'] as int));
  }
}

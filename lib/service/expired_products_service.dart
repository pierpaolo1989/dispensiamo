import 'package:dispensiamo/service/database_service.dart';
import 'package:flutter/foundation.dart';

class ExpiredProductsService {
  static Future<int> deleteExpiredProducts() async {
    final products = await DatabaseService.getAllProducts();
    final now = DateTime.now();
    int deletedCount = 0;

    for (final product in products) {
      final expirationDateStr = product['expiration_date'];
      if (expirationDateStr != null && expirationDateStr is String) {
        try {
          final expirationDate = DateTime.parse(expirationDateStr);
          if (expirationDate.isBefore(now)) {
            await DatabaseService.deleteProduct(product['id'].toString());
            deletedCount++;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing expiration date: $e');
          }
        }
      }
    }

    return deletedCount;
  }

  static Future<List<Map<String, dynamic>>> getExpiredProducts() async {
    final products = await DatabaseService.getAllProducts();
    final now = DateTime.now();
    final expiredProducts = <Map<String, dynamic>>[];

    for (final product in products) {
      final expirationDateStr = product['expiration_date'];
      if (expirationDateStr != null && expirationDateStr is String) {
        try {
          final expirationDate = DateTime.parse(expirationDateStr);
          if (expirationDate.isBefore(now)) {
            expiredProducts.add(product);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing expiration date: $e');
          }
        }
      }
    }

    return expiredProducts;
  }
}

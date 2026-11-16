import 'package:dispensiamo/model/product_category.dart';

class SpendingBucket {
  const SpendingBucket({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class CategorySpendingBucket {
  const CategorySpendingBucket({
    required this.category,
    required this.amount,
  });

  final ProductCategory category;
  final double amount;
}

class PurchaseStatistics {
  const PurchaseStatistics({
    required this.total,
    required this.productCount,
    required this.buckets,
    required this.categoryBuckets,
  });

  final double total;
  final int productCount;
  final List<SpendingBucket> buckets;
  final List<CategorySpendingBucket> categoryBuckets;

  factory PurchaseStatistics.fromProducts(
    Iterable<Map<String, dynamic>> products, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final amountsByDate = <DateTime, double>{};
    final amountsByCategory = <ProductCategory, double>{};
    var total = 0.0;
    var productCount = 0;

    for (final product in products) {
      final purchaseDate = product['purchase_date'];
      final price = product['price'];
      if (purchaseDate is! String ||
          price is! num ||
          !price.isFinite ||
          price < 0) {
        continue;
      }

      final parsedDate = DateTime.tryParse(purchaseDate);
      if (parsedDate == null) continue;
      final date = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      if (date.isBefore(start) || date.isAfter(end)) continue;

      final amount = price.toDouble();
      total += amount;
      productCount++;
      final category = ProductCategory.fromId(product['category']);
      amountsByCategory.update(
        category,
        (existingAmount) => existingAmount + amount,
        ifAbsent: () => amount,
      );
      amountsByDate.update(
        date,
        (existingAmount) => existingAmount + amount,
        ifAbsent: () => amount,
      );
    }

    final dates = amountsByDate.keys.toList()..sort();
    final categoryBuckets = [
      for (final entry in amountsByCategory.entries)
        if (entry.value > 0)
          CategorySpendingBucket(category: entry.key, amount: entry.value),
    ]..sort((first, second) {
        final amountOrder = second.amount.compareTo(first.amount);
        return amountOrder != 0
            ? amountOrder
            : first.category.name.compareTo(second.category.name);
      });
    return PurchaseStatistics(
      total: total,
      productCount: productCount,
      buckets: [
        for (final date in dates)
          SpendingBucket(date: date, amount: amountsByDate[date]!),
      ],
      categoryBuckets: categoryBuckets,
    );
  }
}

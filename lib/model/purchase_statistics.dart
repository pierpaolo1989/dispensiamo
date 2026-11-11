class SpendingBucket {
  const SpendingBucket({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class PurchaseStatistics {
  const PurchaseStatistics({
    required this.total,
    required this.productCount,
    required this.buckets,
  });

  final double total;
  final int productCount;
  final List<SpendingBucket> buckets;

  factory PurchaseStatistics.fromProducts(
    Iterable<Map<String, dynamic>> products, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final amountsByDate = <DateTime, double>{};
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
      amountsByDate.update(
        date,
        (existingAmount) => existingAmount + amount,
        ifAbsent: () => amount,
      );
    }

    final dates = amountsByDate.keys.toList()..sort();
    return PurchaseStatistics(
      total: total,
      productCount: productCount,
      buckets: [
        for (final date in dates)
          SpendingBucket(date: date, amount: amountsByDate[date]!),
      ],
    );
  }
}

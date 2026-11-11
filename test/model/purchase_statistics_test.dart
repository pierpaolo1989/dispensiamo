import 'package:dispensiamo/model/purchase_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseStatistics', () {
    test('aggregates purchases by day within an inclusive date range', () {
      final statistics = PurchaseStatistics.fromProducts(
        [
          {'purchase_date': '2026-04-02', 'price': 2.50},
          {'purchase_date': '2026-04-02', 'price': 1.25},
          {'purchase_date': '2026-04-03', 'price': 4.00},
          {'purchase_date': '2026-04-04', 'price': 8.00},
          {'purchase_date': null, 'price': 10.00},
        ],
        startDate: DateTime(2026, 4, 2, 15),
        endDate: DateTime(2026, 4, 3, 10),
      );

      expect(statistics.total, 7.75);
      expect(statistics.productCount, 3);
      expect(statistics.buckets, hasLength(2));
      expect(statistics.buckets[0].date, DateTime(2026, 4, 2));
      expect(statistics.buckets[0].amount, 3.75);
      expect(statistics.buckets[1].date, DateTime(2026, 4, 3));
      expect(statistics.buckets[1].amount, 4.00);
    });

    test('ignores malformed dates and invalid prices', () {
      final statistics = PurchaseStatistics.fromProducts(
        [
          {'purchase_date': 'not-a-date', 'price': 2.0},
          {'purchase_date': '2026-04-02', 'price': double.nan},
          {'purchase_date': '2026-04-02', 'price': -1},
        ],
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
      );

      expect(statistics.total, 0);
      expect(statistics.productCount, 0);
      expect(statistics.buckets, isEmpty);
    });
  });
}

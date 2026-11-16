import 'package:dispensiamo/model/product_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductCategory', () {
    test('suggests categories from local product-name keywords', () {
      expect(
        ProductCategory.suggestForName('ACQUA NATURALE'),
        ProductCategory.beverages,
      );
      expect(
        ProductCategory.suggestForName('Latte intero'),
        ProductCategory.food,
      );
      expect(
        ProductCategory.suggestForName('Detersivo piatti'),
        ProductCategory.homeCare,
      );
      expect(
        ProductCategory.suggestForName('Caffè'),
        ProductCategory.beverages,
      );
    });

    test('keeps unknown products uncategorized', () {
      expect(
        ProductCategory.suggestForName('SKU 123'),
        ProductCategory.uncategorized,
      );
      expect(
        ProductCategory.fromId('not-a-category'),
        ProductCategory.uncategorized,
      );
    });
  });
}

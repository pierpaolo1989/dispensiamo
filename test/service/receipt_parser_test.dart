import 'package:dispensiamo/service/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptParser', () {
    test('keeps repeated products and applies each following discount', () {
      final products = ReceiptParser.parse('''
        DESCRIZIONE IVA Prezzo(€)
        DENTIFR. AZ 100ML VI* 1,29
        SCONTO VI* -0,30
        DENTIFR. AZ 100ML VI* 1,29
        SCONTO VI* -0,30
        DENTIFR. AZ 100ML VI* 1,29
        SCONTO VI* -0,30
        ARROTONDAMENTI VI* -0,02
        TOTALE COMPLESSIVO 2,95
        DETTAGLIO FORME DI PAGAMENTO CONTANTI 2,95
      ''');

      expect(products, hasLength(3));
      expect(products.map((product) => product.name).toSet(), {
        'DENTIFR. AZ 100ML',
      });
      expect(products.map((product) => product.price), [
        0.99,
        0.99,
        0.99,
      ]);
    });

    test('supports discounts printed as positive values', () {
      final products = ReceiptParser.parse('''
        SAPONE 2,50
        SCONTO 0,50
      ''');

      expect(products, hasLength(1));
      expect(products.single.price, 2.0);
    });

    test('matches descriptions and amounts recognized on separate lines', () {
      final products = ReceiptParser.parse('''
        DENTIFR. AZ 100ML
        VI*
        1,29
        SCONTO
        VI*
        -0,30
        DENTIFR. AZ 100ML VI* 1,29
        SCONTO VI* -0,30
      ''');

      expect(products, hasLength(2));
      expect(products.map((product) => product.name), [
        'DENTIFR. AZ 100ML',
        'DENTIFR. AZ 100ML',
      ]);
      expect(products.map((product) => product.price), [0.99, 0.99]);
    });
  });
}

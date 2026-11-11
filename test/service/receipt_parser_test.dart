import 'package:dispensiamo/service/receipt_parser.dart';
import 'package:dispensiamo/model/receipt_ocr_result.dart';
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

    test('merges same-row OCR fragments using their coordinates', () {
      const receipt = ReceiptOcrResult(
        lines: [
          ReceiptOcrLine(
            text: '1,29',
            left: 180,
            top: 11,
            width: 30,
            height: 10,
            confidence: 0.96,
          ),
          ReceiptOcrLine(
            text: 'PANE INTEGRALE',
            left: 10,
            top: 10,
            width: 120,
            height: 10,
            confidence: 0.98,
          ),
        ],
      );

      final products = const ReceiptParser().parseReceipt(receipt).items;

      expect(products, hasLength(1));
      expect(products.single.name, 'PANE INTEGRALE');
      expect(products.single.price, 1.29);
      expect(products.single.confidence, closeTo(0.97, 0.001));
    });

    test('extracts receipt metadata, quantity and checks the total', () {
      final receipt = ReceiptOcrResult.fromText('''
        LIDL
        10/11/2026
        SCONTRINO N.123456
        LATTE PARZ. SCREMATO 2 X 1,29 2,58
        SCONTO -0,10
        TOTALE IVA 0,10
        TOTALE 2,48
      ''');

      final analysis = const ReceiptParser().parseReceipt(receipt);

      expect(analysis.store, 'LIDL');
      expect(analysis.date, '2026-11-10');
      expect(analysis.receiptNumber, '123456');
      expect(analysis.currency, 'EUR');
      expect(analysis.items, hasLength(1));
      expect(analysis.items.single.name, 'LATTE PARZ. SCREMATO');
      expect(analysis.items.single.quantity, 2);
      expect(analysis.items.single.unitPrice, 1.29);
      expect(analysis.items.single.price, 2.48);
      expect(analysis.items.single.totalPrice, 2.58);
      expect(analysis.items.single.discount, 0.10);
      expect(analysis.subtotal, 2.58);
      expect(analysis.tax, 0.10);
      expect(analysis.total, 2.48);
      expect(analysis.totalsAreConsistent, isTrue);
      expect(
        analysis.toJson()['items'],
        [
          {
            'description': 'LATTE PARZ. SCREMATO',
            'quantity': 2.0,
            'unit_price': 1.29,
            'total_price': 2.58,
            'discount': 0.10,
            'confidence': null,
          },
        ],
      );
    });

    test('parses European thousands separators and excludes payment totals',
        () {
      final products = ReceiptParser.parse('''
        PASTA 1.234,56
        TOTALE COMPLESSIVO 1.234,56
        CONTANTI 1.234,56
      ''');

      expect(products, hasLength(1));
      expect(products.single.price, 1234.56);
    });
  });
}

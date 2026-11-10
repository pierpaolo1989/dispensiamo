class ReceiptProductDraft {
  const ReceiptProductDraft({required this.name, required this.price});

  final String name;
  final double price;

  ReceiptProductDraft copyWith({String? name, double? price}) =>
      ReceiptProductDraft(
        name: name ?? this.name,
        price: price ?? this.price,
      );
}

class ReceiptParser {
  static final _amountAtLineEnd = RegExp(
    r'(-?\s*\d+(?:[.,]\d{2}))\s*€?\s*$',
  );
  static final _amountOnly = RegExp(r'^-?\s*\d+(?:[.,]\d{2})\s*€?$');
  static final _discount = RegExp(r'\bSCONTO\b', caseSensitive: false);
  static final _taxMarker = RegExp(
    r'\bV[IA]\s*\*?',
    caseSensitive: false,
  );
  static final _ignoredDescription = RegExp(
    r'\b(?:TOTALE|COMPLESSIVO|PAGAMENTO|CONTANTI|IMPORTO|IVA|DOCUMENTO|'
    r'ARROTONDAMENTI|DESCRIZIONE|PREZZO|DETTAGLIO|SCONTRINO|RESTO)\b',
    caseSensitive: false,
  );

  static List<ReceiptProductDraft> parse(String text) {
    final products = <ReceiptProductDraft>[];
    String? pendingDescription;
    var pendingDiscount = false;

    for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final amountMatch = _amountAtLineEnd.firstMatch(line);
      final description = amountMatch == null
          ? null
          : _cleanDescription(line.substring(0, amountMatch.start));

      if (amountMatch != null) {
        final amountText = amountMatch.group(1)!.replaceAll(' ', '');
        final amount = double.tryParse(amountText.replaceAll(',', '.'));
        if (amount == null || !amount.isFinite) continue;

        if (_discount.hasMatch(line)) {
          _applyDiscount(products, amount);
          pendingDescription = null;
          pendingDiscount = false;
        } else if (description != null && _isProductDescription(description)) {
          products.add(ReceiptProductDraft(name: description, price: amount));
          pendingDescription = null;
          pendingDiscount = false;
        } else if (description == null || description.isEmpty) {
          if (pendingDiscount) {
            _applyDiscount(products, amount);
            pendingDiscount = false;
            pendingDescription = null;
          } else if (pendingDescription != null) {
            products.add(
              ReceiptProductDraft(
                name: pendingDescription,
                price: amount,
              ),
            );
            pendingDescription = null;
          }
        }
        continue;
      }

      if (_discount.hasMatch(line)) {
        pendingDiscount = true;
        pendingDescription = null;
        continue;
      }

      if (_amountOnly.hasMatch(line)) {
        continue;
      }

      final candidate = _cleanDescription(line);
      if (!_isProductDescription(candidate)) continue;

      pendingDescription = pendingDescription == null
          ? candidate
          : '$pendingDescription $candidate';
    }

    return products;
  }

  static String _cleanDescription(String value) => value
      .replaceAll(_taxMarker, ' ')
      .replaceAll(RegExp(r'[>*]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isProductDescription(String value) =>
      value.isNotEmpty &&
      !_ignoredDescription.hasMatch(value) &&
      RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(value);

  static void _applyDiscount(
    List<ReceiptProductDraft> products,
    double amount,
  ) {
    if (products.isEmpty) return;

    final previous = products.last;
    final discountedPrice =
        amount < 0 ? previous.price + amount : previous.price - amount;
    if (discountedPrice >= 0) {
      products[products.length - 1] = previous.copyWith(price: discountedPrice);
    }
  }
}

import 'package:dispensiamo/model/receipt_ocr_result.dart';

class ReceiptProductDraft {
  const ReceiptProductDraft({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.unitPrice,
    this.discount = 0,
    this.confidence,
    double? totalPrice,
  }) : totalPrice = totalPrice ?? price;

  final String name;
  final double price;
  final double quantity;
  final double? unitPrice;
  final double discount;
  final double? confidence;
  final double totalPrice;

  ReceiptProductDraft copyWith({
    String? name,
    double? price,
    double? quantity,
    double? unitPrice,
    double? discount,
    double? confidence,
    double? totalPrice,
  }) =>
      ReceiptProductDraft(
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
        confidence: confidence ?? this.confidence,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  Map<String, Object?> toJson() => {
        'description': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'discount': discount,
        'confidence': confidence,
      };
}

class ReceiptAnalysis {
  const ReceiptAnalysis({
    required this.items,
    required this.currency,
    this.store,
    this.date,
    this.receiptNumber,
    this.subtotal,
    this.tax,
    this.total,
  });

  final String? store;
  final String? date;
  final String? receiptNumber;
  final String currency;
  final List<ReceiptProductDraft> items;
  final double? subtotal;
  final double? tax;
  final double? total;

  bool? get totalsAreConsistent {
    if (total == null) return null;
    final sum = items.fold<double>(0, (value, item) => value + item.price);
    return (sum - total!).abs() <= 0.02;
  }

  Map<String, Object?> toJson() => {
        'store': store,
        'date': date,
        'receipt_number': receiptNumber,
        'currency': currency,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
      };
}

abstract interface class StoreSpecificReceiptParser {
  bool supports(ReceiptOcrResult receipt);

  ReceiptAnalysis parse(ReceiptOcrResult receipt);
}

class ReceiptParser {
  const ReceiptParser({this.storeParsers = const []});

  final List<StoreSpecificReceiptParser> storeParsers;

  ReceiptAnalysis parseReceipt(ReceiptOcrResult receipt) {
    for (final parser in storeParsers) {
      if (parser.supports(receipt)) return parser.parse(receipt);
    }
    return GenericReceiptParser.parse(receipt);
  }

  static List<ReceiptProductDraft> parse(String text) =>
      GenericReceiptParser.parse(ReceiptOcrResult.fromText(text)).items;
}

class GenericReceiptParser {
  static final _amountAtLineEnd = RegExp(
    r'(-?\s*(?:(?:\d{1,3}(?:[. ]\d{3})+)|\d+)(?:[,.]\d{2}))\s*€?\s*$',
  );
  static final _amountOnly = RegExp(
    r'^-?\s*(?:(?:\d{1,3}(?:[. ]\d{3})+)|\d+)(?:[,.]\d{2})\s*€?$',
  );
  static final _discount = RegExp(r'\bSCONTO\b', caseSensitive: false);
  static final _taxMarker = RegExp(r'\bV[IA]\s*\*?', caseSensitive: false);
  static final _ignoredDescription = RegExp(
    r'\b(?:TOTALE|COMPLESSIVO|PAGAMENTO|CONTANTI|IMPORTO|IVA|DOCUMENTO|'
    r'ARROTONDAMENTI|DESCRIZIONE|PREZZO|DETTAGLIO|SCONTRINO|RESTO|'
    r'SUBTOTALE|IMPONIBILE|TASSE)\b',
    caseSensitive: false,
  );
  static final _totalMarker = RegExp(
    r'\b(?:TOTALE|COMPLESSIVO)\b',
    caseSensitive: false,
  );
  static final _subtotalMarker = RegExp(
    r'\b(?:SUBTOTALE|IMPONIBILE)\b',
    caseSensitive: false,
  );
  static final _taxTotalMarker = RegExp(
    r'\b(?:IVA\s+TOTALE|TOTALE\s+IVA|TASSE)\b',
    caseSensitive: false,
  );
  static final _datePattern = RegExp(
    r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b'
    r'|\b(\d{4})-(\d{1,2})-(\d{1,2})\b',
  );
  static final _receiptNumberPattern = RegExp(
    r'\b(?:SCONTRINO|DOC(?:UMENTO)?)\s*(?:N(?:R|UM)?\.?\s*)?'
    r'([A-Z0-9/-]{4,})\b',
    caseSensitive: false,
  );

  static ReceiptAnalysis parse(ReceiptOcrResult receipt) {
    final products = <ReceiptProductDraft>[];
    var pendingDescription = '';
    var pendingDiscount = false;
    var pendingTotal = false;
    var pendingSubtotal = false;
    var pendingTax = false;
    double? total;
    double? printedSubtotal;
    double? tax;

    for (final row in _rowsFrom(receipt)) {
      final line = row.text.trim();
      if (line.isEmpty) continue;

      final amountMatch = _amountAtLineEnd.firstMatch(line);
      final amount =
          amountMatch == null ? null : _parseAmount(amountMatch.group(1)!);

      if (_taxTotalMarker.hasMatch(line)) {
        if (amount != null) {
          tax = amount;
          pendingTax = false;
        } else {
          pendingTax = true;
        }
        pendingDescription = '';
        continue;
      }

      if (_totalMarker.hasMatch(line)) {
        if (amount != null) {
          total = amount;
          pendingTotal = false;
        } else {
          pendingTotal = true;
        }
        pendingDescription = '';
        continue;
      }

      if (_subtotalMarker.hasMatch(line)) {
        if (amount != null) {
          printedSubtotal = amount;
          pendingSubtotal = false;
        } else {
          pendingSubtotal = true;
        }
        pendingDescription = '';
        continue;
      }

      if (amount != null && pendingTotal && _amountOnly.hasMatch(line)) {
        total = amount;
        pendingTotal = false;
        continue;
      }
      if (amount != null && pendingSubtotal && _amountOnly.hasMatch(line)) {
        printedSubtotal = amount;
        pendingSubtotal = false;
        continue;
      }
      if (amount != null && pendingTax && _amountOnly.hasMatch(line)) {
        tax = amount;
        pendingTax = false;
        continue;
      }

      final discountMatch = _discount.firstMatch(line);
      if (discountMatch != null) {
        final itemText = line.substring(0, discountMatch.start).trim();
        final itemAmountMatch = _amountAtLineEnd.firstMatch(itemText);
        final itemAmount = itemAmountMatch == null
            ? null
            : _parseAmount(itemAmountMatch.group(1)!);
        final itemDescription = itemAmountMatch == null
            ? null
            : _cleanDescription(
                itemText.substring(0, itemAmountMatch.start),
              );
        if (itemAmount != null &&
            itemDescription != null &&
            _isProductDescription(itemDescription)) {
          products.add(
            _createProduct(itemDescription, itemAmount, row.confidence),
          );
        }
        if (amount != null) {
          _applyDiscount(products, amount);
          pendingDiscount = false;
        } else {
          pendingDiscount = true;
        }
        pendingDescription = '';
        continue;
      }

      if (amount != null) {
        final description = _cleanDescription(
          amountMatch == null ? line : line.substring(0, amountMatch.start),
        );
        if (_isProductDescription(description)) {
          products.add(_createProduct(description, amount, row.confidence));
          pendingDescription = '';
          pendingDiscount = false;
        } else if (_amountOnly.hasMatch(line)) {
          if (pendingDiscount) {
            _applyDiscount(products, amount);
            pendingDiscount = false;
            pendingDescription = '';
          } else if (pendingDescription.isNotEmpty) {
            products.add(
              _createProduct(
                pendingDescription,
                amount,
                row.confidence,
              ),
            );
            pendingDescription = '';
          }
        }
        continue;
      }

      final candidate = _cleanDescription(line);
      if (!_isProductDescription(candidate)) continue;
      pendingDescription = pendingDescription.isEmpty
          ? candidate
          : '$pendingDescription $candidate';
    }

    final text = receipt.text;
    final date = _extractDate(text);
    final receiptNumber = _receiptNumberPattern.firstMatch(text)?.group(1);
    final productSum =
        products.fold<double>(0, (sum, product) => sum + product.totalPrice);

    return ReceiptAnalysis(
      store: _detectStore(text),
      date: date,
      receiptNumber: receiptNumber,
      currency: 'EUR',
      items: products,
      subtotal: printedSubtotal ?? productSum,
      tax: tax,
      total: total,
    );
  }

  static List<_ReceiptRow> _rowsFrom(ReceiptOcrResult receipt) {
    final lines =
        receipt.lines.where((line) => line.text.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];
    if (!lines.every((line) => line.hasPosition)) {
      return lines
          .map((line) => _ReceiptRow(line.text, line.confidence))
          .toList();
    }

    lines.sort((first, second) {
      final verticalOrder = first.centerY.compareTo(second.centerY);
      return verticalOrder != 0
          ? verticalOrder
          : first.left!.compareTo(second.left!);
    });

    final rows = <_PositionedReceiptRow>[];
    for (final line in lines) {
      final currentRow = rows.isEmpty ? null : rows.last;
      final height = line.height ?? 1;
      final sameRow = currentRow != null &&
          (line.centerY - currentRow.centerY).abs() <=
              (height > currentRow.height ? height : currentRow.height) * 0.55;
      if (sameRow) {
        currentRow.add(line);
      } else {
        rows.add(_PositionedReceiptRow(line));
      }
    }
    return rows.map((row) => row.toReceiptRow()).toList();
  }

  static ReceiptProductDraft _createProduct(
    String description,
    double amount,
    double? confidence,
  ) {
    final quantityPrefix = RegExp(
      r'^(\d+(?:[,.]\d+)?)\s*[xX]\s*(.+)$',
    ).firstMatch(description);
    if (quantityPrefix != null) {
      final quantity = _parseAmount(quantityPrefix.group(1)!);
      if (quantity != null && quantity > 0) {
        return ReceiptProductDraft(
          name: quantityPrefix.group(2)!.trim(),
          price: amount,
          quantity: quantity,
          unitPrice: amount / quantity,
          confidence: confidence,
        );
      }
    }

    final quantitySuffix = RegExp(
      r'^(.+?)\s+(\d+(?:[,.]\d+)?)\s*[xX]\s*'
      r'(\d+(?:[,.]\d{1,2})?)$',
    ).firstMatch(description);
    if (quantitySuffix != null) {
      final quantity = _parseAmount(quantitySuffix.group(2)!);
      final unitPrice = _parseAmount(quantitySuffix.group(3)!);
      if (quantity != null && quantity > 0 && unitPrice != null) {
        return ReceiptProductDraft(
          name: quantitySuffix.group(1)!.trim(),
          price: amount,
          quantity: quantity,
          unitPrice: unitPrice,
          confidence: confidence,
        );
      }
    }

    return ReceiptProductDraft(
      name: description,
      price: amount,
      unitPrice: amount,
      confidence: confidence,
    );
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
    final discount = amount.abs();
    final discountedPrice = previous.price - discount;
    if (discountedPrice >= 0) {
      products[products.length - 1] = previous.copyWith(
        price: discountedPrice,
        discount: previous.discount + discount,
      );
    }
  }

  static double? _parseAmount(String value) {
    var normalized = value.replaceAll(RegExp(r'[\s€]'), '');
    final negative = normalized.startsWith('-');
    normalized = normalized.replaceFirst(RegExp(r'^-'), '');

    final comma = normalized.lastIndexOf(',');
    final dot = normalized.lastIndexOf('.');
    final decimalSeparator = comma > dot ? ',' : '.';
    final decimalIndex = normalized.lastIndexOf(decimalSeparator);
    if (decimalIndex >= 0) {
      final integer =
          normalized.substring(0, decimalIndex).replaceAll(RegExp(r'[.,]'), '');
      final fraction = normalized.substring(decimalIndex + 1);
      normalized = '$integer.$fraction';
    } else {
      normalized = normalized.replaceAll(RegExp(r'[.,]'), '');
    }

    final amount = double.tryParse(normalized);
    if (amount == null || !amount.isFinite) return null;
    return negative ? -amount : amount;
  }

  static String? _extractDate(String text) {
    final match = _datePattern.firstMatch(text);
    if (match == null) return null;
    final yearFirst = match.group(4) != null;
    final year = int.parse(yearFirst ? match.group(4)! : match.group(3)!);
    final month = int.parse(yearFirst ? match.group(5)! : match.group(2)!);
    final day = int.parse(yearFirst ? match.group(6)! : match.group(1)!);
    final normalizedYear = year < 100 ? 2000 + year : year;
    final date = DateTime.tryParse(
      '${normalizedYear.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );
    if (date == null ||
        date.year != normalizedYear ||
        date.month != month ||
        date.day != day) {
      return null;
    }
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String? _detectStore(String text) {
    const storeNames = [
      'LIDL',
      'EUROSPIN',
      'CONAD',
      'ESSELUNGA',
      'COOP',
      'CARREFOUR',
      'PAM',
      'DESPAR',
      'MD',
      'TODIS',
    ];
    final uppercaseText = text.toUpperCase();
    for (final store in storeNames) {
      if (RegExp(
        r'(?<![A-Z])' + RegExp.escape(store) + r'(?![A-Z])',
      ).hasMatch(uppercaseText)) {
        return store;
      }
    }
    return null;
  }
}

class _ReceiptRow {
  const _ReceiptRow(this.text, this.confidence);

  final String text;
  final double? confidence;
}

class _PositionedReceiptRow {
  _PositionedReceiptRow(ReceiptOcrLine line) : _lines = [line];

  final List<ReceiptOcrLine> _lines;

  double get centerY =>
      _lines.map((line) => line.centerY).reduce((a, b) => a + b) /
      _lines.length;

  double get height =>
      _lines.map((line) => line.height ?? 1).reduce((a, b) => a > b ? a : b);

  void add(ReceiptOcrLine line) => _lines.add(line);

  _ReceiptRow toReceiptRow() {
    _lines.sort((first, second) => first.left!.compareTo(second.left!));
    final confidences =
        _lines.map((line) => line.confidence).whereType<double>().toList();
    final confidence = confidences.isEmpty
        ? null
        : confidences.reduce((a, b) => a + b) / confidences.length;
    return _ReceiptRow(
      _lines.map((line) => line.text.trim()).join(' '),
      confidence,
    );
  }
}

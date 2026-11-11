import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/service/database_service.dart';
import 'package:dispensiamo/service/receipt_parser.dart';
import 'package:dispensiamo/service/text_recognition_service.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.scanDate,
    this.onProductsImported,
  });

  final String imagePath;
  final DateTime scanDate;
  final ValueChanged<int>? onProductsImported;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _products = <_ReceiptProductFields>[];
  String? _recognizedText;
  late DateTime _purchaseDate = widget.scanDate;
  Object? _analysisError;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _analyzeReceipt();
  }

  @override
  void dispose() {
    for (final product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  Future<void> _analyzeReceipt() async {
    setState(() {
      _isLoading = true;
      _analysisError = null;
    });

    try {
      final ocrResult = await TextRecognitionService.analyzeReceipt(
        widget.imagePath,
      );
      final receipt = const ReceiptParser().parseReceipt(ocrResult);
      if (!mounted) return;

      setState(() {
        _recognizedText = ocrResult.text;
        _purchaseDate = receipt.date == null
            ? widget.scanDate
            : DateTime.parse(receipt.date!);
        _products
          ..forEach((product) => product.dispose())
          ..clear()
          ..addAll(receipt.items.map(_ReceiptProductFields.fromDraft));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _analysisError = error;
        _isLoading = false;
      });
    }
  }

  void _addProduct() {
    setState(() {
      _products.add(_ReceiptProductFields());
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index).dispose();
    });
  }

  Future<void> _saveProducts() async {
    if (!_formKey.currentState!.validate()) return;

    final products = _products.map((draft) {
      return {
        'name': draft.name.text.trim(),
        'price': double.parse(draft.price.text.trim().replaceAll(',', '.')),
        'expiration_date': null,
        'alert_days': null,
        'purchase_date': _formatDateForStorage(_purchaseDate),
      };
    }).toList();

    setState(() {
      _isSaving = true;
    });

    try {
      final savedIds = await DatabaseService.saveProducts(products);
      if (!mounted) return;

      final navigator = Navigator.of(context);
      widget.onProductsImported?.call(savedIds.length);
      navigator.popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.of(context).importReceiptError} $error',
          ),
        ),
      );
    }
  }

  static String _formatDateForStorage(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.reviewReceipt)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysisError != null
              ? _AnalysisError(
                  message: strings.receiptAnalysisError(_analysisError!),
                  onRetry: _analyzeReceipt,
                )
              : _buildReview(strings),
      bottomNavigationBar: !_isLoading && _analysisError == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed:
                      _isSaving || _products.isEmpty ? null : _saveProducts,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.inventory_2_outlined),
                  label: Text(strings.importReceiptProducts),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildReview(AppStrings strings) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                strings.receiptReviewDescription,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            if (_recognizedText case final String text
                when text.trim().isNotEmpty)
              ExpansionTile(
                initiallyExpanded: _products.isEmpty,
                title: Text(strings.receiptText),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(text),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: Text(strings.addReceiptProduct),
                ),
              ),
            ),
            if (_products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  strings.noReceiptProducts,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...List.generate(_products.length, (index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: product.name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: strings.name,
                            isDense: true,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? strings.enterName
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: product.price,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: strings.price,
                                  prefixText: '€ ',
                                  isDense: true,
                                ),
                                validator: (value) {
                                  final price = double.tryParse(
                                    (value ?? '').trim().replaceAll(',', '.'),
                                  );
                                  return price == null ||
                                          !price.isFinite ||
                                          price < 0
                                      ? strings.invalidReceiptPrice
                                      : null;
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: strings.removeReceiptProduct,
                              onPressed: () => _removeProduct(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ReceiptProductFields {
  _ReceiptProductFields({String name = '', String price = ''})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);

  factory _ReceiptProductFields.fromDraft(ReceiptProductDraft draft) =>
      _ReceiptProductFields(
        name: draft.name,
        price: draft.price.toStringAsFixed(2).replaceAll('.', ','),
      );

  final TextEditingController name;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

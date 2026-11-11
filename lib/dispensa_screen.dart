import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/service/app_settings.dart';
import 'package:dispensiamo/service/database_service.dart';
import 'package:dispensiamo/service/notification_service.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DispensaScreen extends StatefulWidget {
  const DispensaScreen({super.key});

  @override
  State<DispensaScreen> createState() => _DispensaScreenState();
}

class _DispensaScreenState extends State<DispensaScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    _scrollController.addListener(_loadNextPageWhenNeeded);
  }

  void _loadNextPageWhenNeeded() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        !_hasMore ||
        _scrollController.position.extentAfter > 300) {
      return;
    }
    _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newProducts = await DatabaseService.getPaginatedProducts(
        _products.isEmpty ? null : _products.last['id'] as String,
      );

      if (!mounted) return;
      setState(() {
        _products.addAll(newProducts);
        _isLoading = false;
        _hasMore = newProducts.length == DatabaseService.productsPageSize;
      });
    } catch (error) {
      if (!mounted) return;
      final strings = AppStrings.of(context);
      setState(() {
        _isLoading = false;
        _errorMessage = strings.loadProductsError(error);
      });
      if (_products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  Future<void> _showProductForm({Map<String, dynamic>? existingProduct}) async {
    final strings = AppStrings.of(context);
    final formKey = GlobalKey<FormState>();
    var name = existingProduct?['name'] as String? ?? '';
    var priceValue = existingProduct == null
        ? ''
        : (existingProduct['price'] as num).toString();
    final savedDate = existingProduct?['expiration_date'] as String?;
    DateTime? expirationDate =
        savedDate == null ? null : DateTime.parse(savedDate);
    int? alertDays = existingProduct?['alert_days'] as int?;

    final product = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(
            existingProduct == null ? strings.addProduct : strings.editProduct,
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    autofocus: true,
                    decoration: InputDecoration(labelText: strings.name),
                    onSaved: (value) => name = value?.trim() ?? '',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? strings.enterName
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: priceValue,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)
                            ? newValue
                            : oldValue;
                      }),
                    ],
                    decoration: InputDecoration(labelText: strings.price),
                    onSaved: (value) => priceValue = value?.trim() ?? '',
                    validator: (value) {
                      final price = double.tryParse((value ?? '').trim());
                      return price == null || !price.isFinite || price < 0
                          ? strings.enterValidPrice
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.expirationDate),
                    subtitle: Text(
                      expirationDate == null
                          ? strings.chooseExpirationDate
                          : _formatDate(context, expirationDate!),
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: expirationDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setDialogState(() {
                          expirationDate = pickedDate;
                        });
                      }
                    },
                  ),
                  if (expirationDate != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setDialogState(() {
                            expirationDate = null;
                          });
                        },
                        child: Text(strings.clearExpirationDate),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: alertDays ?? -1,
                    decoration: InputDecoration(labelText: strings.reminder),
                    items: [
                      DropdownMenuItem<int>(
                        value: -1,
                        child: Text(
                          '${strings.defaultReminder} '
                          '(${_alertLabel(strings, AppSettings.instance.defaultExpirationAlertDays)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text(strings.noReminder),
                      ),
                      for (final days in [1, 2, 3, 7, 14])
                        DropdownMenuItem<int>(
                          value: days,
                          child: Text(strings.defaultAlertDays(days)),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        alertDays = value == -1 ? null : value;
                      });
                    },
                  ),
                  if (expirationDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          strings.expirationDateRequiredForReminder,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                Navigator.pop(context, {
                  'name': name,
                  'price': double.parse(priceValue),
                  'expiration_date': expirationDate == null
                      ? null
                      : _dateForStorage(expirationDate!),
                  'alert_days': alertDays,
                  'purchase_date': existingProduct == null
                      ? _dateForStorage(DateTime.now())
                      : existingProduct['purchase_date'],
                });
              },
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
    if (product == null || !mounted) return;
    final productId = existingProduct?['id'] as String?;
    late final int savedProductId;
    try {
      if (productId == null) {
        savedProductId = await DatabaseService.saveProduct(product);
      } else {
        await DatabaseService.updateProduct(productId, product);
        savedProductId = int.parse(productId);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.saveProductError(error))),
      );
      return;
    }

    try {
      final permissionGranted =
          await NotificationService.instance.scheduleProductReminder(
        productId: savedProductId,
        productName: product['name'] as String,
        expirationDate: product['expiration_date'] as String?,
        alertDays: product['alert_days'] as int?,
      );
      if (!permissionGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? strings.notificationsUnavailable
                  : strings.notificationsDenied,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.saveProductReminderError(error))),
      );
    }

    if (!mounted) return;
    setState(() {
      _products.clear();
      _hasMore = true;
    });
    await _fetchProducts();
  }

  static String _dateForStorage(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _formatDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);

  static String _alertLabel(AppStrings strings, int days) =>
      days == 0 ? strings.noReminder : strings.defaultAlertDays(days);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: _errorMessage != null && _products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _fetchProducts,
                    child: Text(strings.retry),
                  ),
                ],
              ),
            )
          : _products.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? Center(child: Text(strings.noProducts))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _products.length + (_isLoading || _hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _products.length) {
                          return Center(
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: _fetchProducts,
                                    child: Text(strings.loadMore),
                                  ),
                          );
                        }
                        final product = _products[index];
                        final expirationDate =
                            product['expiration_date'] as String?;
                        final productId = product['id'] as String;
                        return Dismissible(
                          key: ValueKey(productId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.centerRight,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.deleteProduct,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (_) async {
                            try {
                              await DatabaseService.deleteProduct(productId);
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      strings.deleteProductError(error),
                                    ),
                                  ),
                                );
                              }
                              return false;
                            }

                            try {
                              await NotificationService.instance
                                  .cancelProductReminder(
                                int.parse(productId),
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      strings.deleteProductReminderError(error),
                                    ),
                                  ),
                                );
                              }
                            }
                            return true;
                          },
                          onDismissed: (_) {
                            setState(() {
                              _products.removeWhere(
                                (item) => item['id'] == productId,
                              );
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            color: const Color(0xFFF8F8F5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              onTap: () => _showProductForm(
                                existingProduct: product,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.acidGreen,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.shopping_basket_outlined,
                                  color: AppColors.black,
                                ),
                              ),
                              title: Text(
                                product['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '€${(product['price'] as num).toStringAsFixed(2)}',
                                    style:
                                        const TextStyle(color: AppColors.muted),
                                  ),
                                  if (expirationDate != null)
                                    Text(
                                      strings.expirationLabel(
                                        _formatDate(
                                          context,
                                          DateTime.parse(expirationDate),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        tooltip: strings.addProductTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

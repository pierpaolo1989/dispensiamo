import 'package:dispensiamo/service/database_service.dart';
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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
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
        _hasMore = newProducts.length == 10;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossibile caricare i prodotti: $error';
      });
      if (_products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    final product = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi prodotto'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Inserisci un nome'
                    : null,
              ),
              TextFormField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Prezzo'),
                validator: (value) {
                  final price = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  return price == null || !price.isFinite || price < 0
                      ? 'Inserisci un prezzo valido'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'price': double.parse(
                  priceController.text.trim().replaceAll(',', '.'),
                ),
              });
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    nameController.dispose();
    priceController.dispose();

    if (product == null) return;
    try {
      await DatabaseService.saveProducts([product]);
      if (!mounted) return;
      setState(() {
        _products.clear();
        _hasMore = true;
      });
      await _fetchProducts();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile salvare il prodotto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      body: _errorMessage != null && _products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _fetchProducts,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            )
          : _products.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? const Center(child: Text('Nessun prodotto salvato'))
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
                                    child: const Text('Carica altri'),
                                  ),
                          );
                        }
                        final product = _products[index];
                        return Card(
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '€${(product['price'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        tooltip: 'Aggiungi prodotto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

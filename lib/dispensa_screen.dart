import 'package:dispensiamo/service/database_service.dart';
import 'package:flutter/material.dart';

class DispensaScreen extends StatefulWidget {
  @override
  _DispensaScreenState createState() => _DispensaScreenState();
}

class _DispensaScreenState extends State<DispensaScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    final newProducts = await FirebaseService.getPaginatedProducts(
      _products.isEmpty ? null : _products.last['id'],
    );

    setState(() {
      _products.addAll(newProducts);
      _isLoading = false;
      if (newProducts.isEmpty) {
        _hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = _products[index];
          return ListTile(
            title: Text(product['name']),
            subtitle: Text('Prezzo: €${product['price']}'),
          );
        },
      ),
    );
  }
}

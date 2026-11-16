class Product {
  String id;
  String name;
  int quantity;
  DateTime? expirationDate;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    this.expirationDate,
  });
}

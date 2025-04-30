class Product {
  final int id;
  final String name;
  final double price;
  final double gstRate;
  final String? description;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.gstRate,
    this.description,
    required this.createdAt,
  });

  // Calculate GST components
  double get cgst => (price * gstRate) / 2;
  double get sgst => (price * gstRate) / 2;
  double get totalGst => cgst + sgst;
  double get totalPrice => price + totalGst;

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'gstRate': gstRate,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      gstRate: map['gstRate'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 
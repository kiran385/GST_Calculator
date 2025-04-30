import 'product.dart';

class InvoiceItem {
  final Product product;
  final int quantity;

  InvoiceItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;
  double get cgst => (subtotal * product.gstRate) / 2;
  double get sgst => (subtotal * product.gstRate) / 2;
  double get totalGst => cgst + sgst;
  double get total => subtotal + totalGst;
}

class Invoice {
  final int id;
  final List<InvoiceItem> items;
  final DateTime createdAt;
  final String? customerName;
  final String? invoiceNumber;

  Invoice({
    required this.id,
    required this.items,
    required this.createdAt,
    this.customerName,
    this.invoiceNumber,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalGst => items.fold(0, (sum, item) => sum + item.totalGst);
  double get total => items.fold(0, (sum, item) => sum + item.total);

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'customerName': customerName,
      'invoiceNumber': invoiceNumber,
    };
  }

  // Create from Map
  factory Invoice.fromMap(Map<String, dynamic> map, List<Product> products) {
    return Invoice(
      id: map['id'],
      items: (map['items'] as List).map((item) {
        final product = products.firstWhere((p) => p.id == item['productId']);
        return InvoiceItem(
          product: product,
          quantity: item['quantity'],
        );
      }).toList(),
      createdAt: DateTime.parse(map['createdAt']),
      customerName: map['customerName'],
      invoiceNumber: map['invoiceNumber'],
    );
  }
}
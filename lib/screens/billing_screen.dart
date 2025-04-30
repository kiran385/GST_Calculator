import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';

class BillingScreen extends StatefulWidget {
  final Product? initialProduct;
  const BillingScreen({super.key, this.initialProduct});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _customerNameController = TextEditingController();
  List<Product> _products = [];
  List<InvoiceItem> _selectedItems = [];
  String? _invoiceNumber;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.initialProduct != null) {
      _addProduct(widget.initialProduct!);
    }
  }

  Future<void> _loadProducts() async {
    final products = await _dbService.getProducts();
    setState(() {
      _products = products;
    });
  }

  void _addProduct(Product product) {
    setState(() {
      final existingItem = _selectedItems.firstWhere(
        (item) => item.product.id == product.id,
        orElse: () => InvoiceItem(product: product, quantity: 0),
      );

      if (existingItem.quantity > 0) {
        _selectedItems.remove(existingItem);
        _selectedItems.add(InvoiceItem(
          product: product,
          quantity: existingItem.quantity + 1,
        ));
      } else {
        _selectedItems.add(InvoiceItem(
          product: product,
          quantity: 1,
        ));
      }
    });
  }

  void _updateQuantity(InvoiceItem item, int newQuantity) {
    setState(() {
      _selectedItems.remove(item);
      if (newQuantity > 0) {
        _selectedItems.add(InvoiceItem(
          product: item.product,
          quantity: newQuantity,
        ));
      }
    });
  }

  Future<void> _generateInvoice() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the invoice')),
      );
      return;
    }

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch,
      items: _selectedItems,
      createdAt: DateTime.now(),
      customerName: _customerNameController.text.isEmpty
          ? null
          : _customerNameController.text,
      invoiceNumber: _invoiceNumber,
    );

    await _dbService.insertInvoice(invoice);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice generated successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '₹${product.price.toStringAsFixed(2)} - GST: ${(product.gstRate * 100).toInt()}%',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addProduct(product),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Selected Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _selectedItems.length,
                          itemBuilder: (context, index) {
                            final item = _selectedItems[index];
                            return ListTile(
                              title: Text(item.product.name),
                              subtitle: Text(
                                '₹${item.subtotal.toStringAsFixed(2)} (${item.quantity} x ₹${item.product.price})',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _updateQuantity(
                                      item,
                                      item.quantity - 1,
                                    ),
                                  ),
                                  Text(item.quantity.toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _updateQuantity(
                                      item,
                                      item.quantity + 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selectedItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Total: ₹${_selectedItems.fold(0.0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _generateInvoice,
                                child: const Text('Generate Invoice'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }
} 
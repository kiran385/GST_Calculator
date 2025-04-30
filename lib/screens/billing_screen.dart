import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';
import '../services/gst_calculator.dart';

class BillingScreen extends StatefulWidget {
  final Product? initialProduct;
  const BillingScreen({super.key, this.initialProduct});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GstCalculator _gstCalculator = GstCalculator();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();
  List<Product> _products = [];
  List<InvoiceItem> _selectedItems = [];
  double _totalAmount = 0;
  double _totalGst = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.initialProduct != null) {
      _addToBill(widget.initialProduct!);
    }
  }

  Future<void> _loadProducts() async {
    final products = await _dbService.getProducts();
    setState(() {
      _products = products;
    });
  }

  void _addToBill(Product product) {
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
        _selectedItems.add(InvoiceItem(product: product, quantity: 1));
      }

      _calculateTotals();
    });
  }

  void _removeFromBill(InvoiceItem item) {
    setState(() {
      if (item.quantity > 1) {
        _selectedItems.remove(item);
        _selectedItems.add(InvoiceItem(
          product: item.product,
          quantity: item.quantity - 1,
        ));
      } else {
        _selectedItems.remove(item);
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _totalAmount = 0;
    _totalGst = 0;

    for (var item in _selectedItems) {
      _totalAmount += item.total;
      _totalGst += item.totalGst;
    }
  }

  Future<void> _createInvoice() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the bill')),
      );
      return;
    }

    if (_invoiceNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter invoice number')),
      );
      return;
    }

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch,
      customerName: _customerNameController.text,
      invoiceNumber: _invoiceNumberController.text,
      items: _selectedItems,
      createdAt: DateTime.now(),
    );

    try {
      await _dbService.insertInvoice(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invoice: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _customerNameController.clear();
      _invoiceNumberController.clear();
      _selectedItems.clear();
      _totalAmount = 0;
      _totalGst = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Customer Details Card
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products List
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final selectedItem = _selectedItems.firstWhere(
                  (item) => item.product.id == product.id,
                  orElse: () => InvoiceItem(product: product, quantity: 0),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '₹${product.price.toStringAsFixed(2)} (GST: ${(product.gstRate * 100).toStringAsFixed(0)}%)',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedItem.quantity > 0)
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _removeFromBill(selectedItem),
                          ),
                        Text(selectedItem.quantity > 0 ? selectedItem.quantity.toString() : ''),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addToBill(product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bill Summary
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total GST:'),
                      Text(
                        '₹${_totalGst.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createInvoice,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Create Invoice'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
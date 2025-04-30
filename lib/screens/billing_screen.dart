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
  List<Product> _products = [];
  List<InvoiceItem> _selectedItems = [];
  double _totalAmount = 0;
  double _totalGst = 0;

  // Color scheme
  final Color primaryColor = const Color(0xFF2196F3); // Blue
  final Color secondaryColor = const Color(0xFF4CAF50); // Green
  final Color accentColor = const Color(0xFFFFC107); // Amber
  final Color backgroundColor = const Color(0xFFF5F5F5); // Light Grey
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF333333);

  Future<String> _generateInvoiceNumber() async {
    final lastNumber = await _dbService.getLastInvoiceNumber();
    final nextNumber = lastNumber + 1;
    return 'INV-${nextNumber.toString().padLeft(6, '0')}';
  }

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

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch,
      customerName: _customerNameController.text,
      invoiceNumber: await _generateInvoiceNumber(),
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
      _selectedItems.clear();
      _totalAmount = 0;
      _totalGst = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Customer Details Card
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2,
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      labelStyle: TextStyle(color: primaryColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
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
                  elevation: 2,
                  color: cardColor,
                  child: ListTile(
                    title: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      '₹${product.price.toStringAsFixed(2)} (GST: ${(product.gstRate * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: selectedItem.quantity > 0 ? primaryColor.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedItem.quantity > 0)
                            IconButton(
                              icon: Icon(Icons.remove, color: primaryColor),
                              onPressed: () => _removeFromBill(selectedItem),
                            ),
                          Text(
                            selectedItem.quantity > 0 ? selectedItem.quantity.toString() : '',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: primaryColor),
                            onPressed: () => _addToBill(product),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bill Summary
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2,
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total GST:',
                        style: TextStyle(color: textColor),
                      ),
                      Text(
                        '₹${_totalGst.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
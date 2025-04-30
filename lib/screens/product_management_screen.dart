import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'billing_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  double _selectedGstRate = 0.18;
  List<Product> _products = [];

  // Color scheme
  final Color primaryColor = const Color(0xFF2196F3); // Blue
  final Color secondaryColor = const Color(0xFF4CAF50); // Green
  final Color accentColor = const Color(0xFFFFC107); // Amber
  final Color backgroundColor = const Color(0xFFF5F5F5); // Light Grey
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _dbService.getProducts();
    setState(() {
      _products = products;
    });
  }

  Future<void> _addProduct() async {
    try {
      if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        gstRate: _selectedGstRate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        createdAt: DateTime.now(),
      );

      print('Adding product: ${product.name}');
      final id = await _dbService.insertProduct(product);
      print('Product added with ID: $id');
      
      await _loadProducts();
      print('Products reloaded, count: ${_products.length}');
      
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedGstRate = 0.18;
      });
    } catch (e) {
      print('Error adding product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add Product Form
            Card(
              elevation: 2,
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add New Product',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        labelStyle: TextStyle(color: primaryColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        labelStyle: TextStyle(color: primaryColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: primaryColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GST Rate',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _selectedGstRate,
                      min: 0.05,
                      max: 0.28,
                      divisions: 3,
                      label: '${(_selectedGstRate * 100).toStringAsFixed(0)}%',
                      onChanged: (value) {
                        setState(() {
                          _selectedGstRate = value;
                        });
                      },
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.3),
                    ),
                    Text(
                      '${(_selectedGstRate * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Products List
            Text(
              'Existing Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  elevation: 2,
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                          await _dbService.deleteProduct(product.id);
                          await _loadProducts();
                        } catch (e) {
                          print('Error deleting product: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting product: $e')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 
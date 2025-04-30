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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      print('Error adding product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _dbService.deleteProduct(product.id);
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
    }
  }

  void _navigateToBilling() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BillingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.receipt),
              onPressed: _navigateToBilling,
              tooltip: 'Generate Bill',
            ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price*',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    value: _selectedGstRate,
                    decoration: const InputDecoration(
                      labelText: 'GST Rate*',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0.05, child: Text('5%')),
                      DropdownMenuItem(value: 0.12, child: Text('12%')),
                      DropdownMenuItem(value: 0.18, child: Text('18%')),
                      DropdownMenuItem(value: 0.28, child: Text('28%')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedGstRate = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addProduct,
                    child: const Text('Add Product'),
                  ),
                ],
              ),
            ),
          ),
          if (_products.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Added Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ₹${product.price.toStringAsFixed(2)}'),
                          Text('GST: ${(product.gstRate * 100).toInt()}%'),
                          if (product.description != null)
                            Text('Description: ${product.description}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BillingScreen(
                                    initialProduct: product,
                                  ),
                                ),
                              );
                            },
                            tooltip: 'Add to Bill',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product),
                            tooltip: 'Delete Product',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
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
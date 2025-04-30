import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';
import '../services/gst_calculator.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GstCalculator _gstCalculator = GstCalculator();
  List<Invoice> _invoices = [];
  Map<String, double> _productSales = {};
  Map<String, double> _dateWiseSales = {};
  double _totalSales = 0;
  double _totalGst = 0;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final invoices = await _dbService.getInvoices();
    setState(() {
      _invoices = invoices;
      _calculateSales();
    });
  }

  void _calculateSales() {
    _productSales.clear();
    _dateWiseSales.clear();
    _totalSales = 0;
    _totalGst = 0;

    for (var invoice in _invoices) {
      final date = invoice.createdAt.toString().split(' ')[0];
      final invoiceTotal = _gstCalculator.calculateTotalAmount(invoice);
      final invoiceGst = _gstCalculator.calculateGstAmount(invoice);

      _totalSales += invoiceTotal;
      _totalGst += invoiceGst;

      // Update date-wise sales
      _dateWiseSales[date] = (_dateWiseSales[date] ?? 0) + invoiceTotal;

      // Update product-wise sales
      for (var item in invoice.items) {
        final productName = item.product.name;
        final itemTotal = item.product.price * item.quantity;
        _productSales[productName] = (_productSales[productName] ?? 0) + itemTotal;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _invoices.isEmpty
          ? const Center(
              child: Text('No sales data available'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Sales',
                          '₹${_totalSales.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total GST',
                          '₹${_totalGst.toStringAsFixed(2)}',
                          Icons.receipt,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Invoices',
                          _invoices.length.toString(),
                          Icons.list_alt,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Average Sale',
                          '₹${(_totalSales / _invoices.length).toStringAsFixed(2)}',
                          Icons.analytics,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Product-wise Sales
                  const Text(
                    'Product-wise Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._productSales.entries.map((entry) {
                    final percentage = (entry.value / _totalSales * 100).toStringAsFixed(1);
                    return Card(
                      child: ListTile(
                        title: Text(entry.key),
                        subtitle: LinearProgressIndicator(
                          value: entry.value / _totalSales,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${entry.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),

                  // Date-wise Sales
                  const Text(
                    'Date-wise Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._dateWiseSales.entries.map((entry) {
                    return Card(
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text(
                          '₹${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
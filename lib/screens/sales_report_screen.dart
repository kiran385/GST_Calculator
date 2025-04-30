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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _invoices.isEmpty
          ? Center(
              child: Text(
                'No sales data available',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                ),
              ),
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
                          primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total GST',
                          '₹${_totalGst.toStringAsFixed(2)}',
                          Icons.receipt,
                          secondaryColor,
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
                          accentColor,
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
                  Text(
                    'Product-wise Sales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    color: cardColor,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _productSales.length,
                      itemBuilder: (context, index) {
                        final productName = _productSales.keys.elementAt(index);
                        final sales = _productSales[productName]!;
                        return ListTile(
                          title: Text(
                            productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          trailing: Text(
                            '₹${sales.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Date-wise Sales
                  Text(
                    'Date-wise Sales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    color: cardColor,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _dateWiseSales.length,
                      itemBuilder: (context, index) {
                        final date = _dateWiseSales.keys.elementAt(index);
                        final sales = _dateWiseSales[date]!;
                        return ListTile(
                          title: Text(
                            date,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          trailing: Text(
                            '₹${sales.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 
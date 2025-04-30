import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';
import '../services/gst_calculator.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GstCalculator _gstCalculator = GstCalculator();
  List<Invoice> _invoices = [];

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
    });
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Invoice',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Are you sure you want to delete invoice #${invoice.invoiceNumber}?',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _dbService.deleteInvoice(invoice.id);
        await _loadInvoices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting invoice: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _invoices.isEmpty
          ? Center(
              child: Text(
                'No transactions found',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                final totalAmount = _gstCalculator.calculateTotalAmount(invoice);
                final gstAmount = _gstCalculator.calculateGstAmount(invoice);
                final cgstAmount = gstAmount / 2;
                final sgstAmount = gstAmount / 2;
                final baseAmount = totalAmount - gstAmount;
                final gstRate = invoice.items.isNotEmpty ? invoice.items.first.product.gstRate : 0.0;

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 2,
                  color: cardColor,
                  child: ExpansionTile(
                    title: Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Date: ${invoice.createdAt.toString().split(' ')[0]}\n'
                      'Customer: ${invoice.customerName ?? 'N/A'}',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteInvoice(invoice),
                      tooltip: 'Delete Invoice',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (invoice.items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'No items in this invoice',
                                  style: TextStyle(color: textColor),
                                ),
                              )
                            else
                              ...invoice.items.map((item) {
                                final itemTotal = item.product.price * item.quantity;
                                final itemGst = itemTotal * item.product.gstRate;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.product.name} (${item.quantity} x ₹${item.product.price})',
                                          style: TextStyle(color: textColor),
                                        ),
                                      ),
                                      Text(
                                        '₹${itemTotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Base Amount:',
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  '₹${baseAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CGST (${(gstRate * 50).toStringAsFixed(0)}%):',
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  '₹${cgstAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SGST (${(gstRate * 50).toStringAsFixed(0)}%):',
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  '₹${sgstAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total GST:',
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  '₹${gstAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
} 
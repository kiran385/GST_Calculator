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
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice #${invoice.invoiceNumber}?'),
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
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _invoices.isEmpty
          ? const Center(
              child: Text('No transactions found'),
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
                  child: ExpansionTile(
                    title: Text('Invoice #${invoice.invoiceNumber}'),
                    subtitle: Text(
                      'Date: ${invoice.createdAt.toString().split(' ')[0]}\n'
                      'Customer: ${invoice.customerName ?? 'N/A'}',
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
                            const Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (invoice.items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text('No items in this invoice'),
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
                                        ),
                                      ),
                                      Text('₹${itemTotal.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                );
                              }),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Base Amount:'),
                                Text('₹${baseAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CGST (${(gstRate * 50).toStringAsFixed(0)}%):'),
                                Text('₹${cgstAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SGST (${(gstRate * 50).toStringAsFixed(0)}%):'),
                                Text('₹${sgstAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total GST:'),
                                Text('₹${gstAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
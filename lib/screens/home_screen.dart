import 'package:flutter/material.dart';
import 'billing_screen.dart';
import 'product_management_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Billing App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(
            context,
            'New Bill',
            Icons.receipt,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BillingScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            'Products',
            Icons.inventory,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductManagementScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            'History',
            Icons.history,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            'Reports',
            Icons.analytics,
            () {
              // TODO: Implement reports screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reports feature coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
} 
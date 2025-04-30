import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/product_management_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/sales_report_screen.dart';
import 'screens/billing_screen.dart';
import 'models/product.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TATA Retail Solutions',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF2196F3), // Blue
          secondary: const Color(0xFF4CAF50), // Green
          tertiary: const Color(0xFFFFC107), // Amber
          background: const Color(0xFFF5F5F5), // Light Grey
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: const Color(0xFF333333), // Dark Grey
          onSurface: const Color(0xFF333333), // Dark Grey
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2196F3).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2196F3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF2196F3)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Product? _initialProduct;

  List<Widget> get _screens => [
        BillingScreen(initialProduct: _initialProduct),
        const ProductManagementScreen(),
        const TransactionHistoryScreen(),
        const SalesReportScreen(),
      ];

  void _setInitialProduct(Product product) {
    setState(() {
      _initialProduct = product;
      _selectedIndex = 0; // Switch to Billing screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TATA Retail Solutions'),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 0) {
              _initialProduct = null; // Clear initial product when switching to other screens
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart),
            label: 'Bill',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

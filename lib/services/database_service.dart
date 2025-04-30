import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/invoice.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gst_billing.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        gstRate REAL NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create invoices table
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT,
        invoiceNumber TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create invoice_items table
    await db.execute('''
      CREATE TABLE invoice_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    try {
      print('Inserting product into database: ${product.name}');
      final db = await database;
      print('Database connection established');
      final id = await db.insert('products', product.toMap());
      print('Product inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      print('Deleting product with ID: $productId');
      final db = await database;
      
      // First delete any invoice items that reference this product
      await db.delete(
        'invoice_items',
        where: 'productId = ?',
        whereArgs: [productId],
      );
      
      // Then delete the product
      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
      
      print('Product and related invoice items deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      print('Fetching products from database');
      final db = await database;
      print('Database connection established');
      final List<Map<String, dynamic>> maps = await db.query('products');
      print('Products fetched: ${maps.length}');
      return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  // Invoice operations
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    final invoiceId = await db.insert('invoices', {
      'customerName': invoice.customerName,
      'invoiceNumber': invoice.invoiceNumber,
      'createdAt': invoice.createdAt.toIso8601String(),
    });

    for (var item in invoice.items) {
      await db.insert('invoice_items', {
        'invoiceId': invoiceId,
        'productId': item.product.id,
        'quantity': item.quantity,
      });
    }

    return invoiceId;
  }

  Future<void> deleteInvoice(int invoiceId) async {
    try {
      print('Deleting invoice with ID: $invoiceId');
      final db = await database;
      
      // First delete all invoice items
      await db.delete(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [invoiceId],
      );
      
      // Then delete the invoice
      await db.delete(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      
      print('Invoice and related items deleted successfully');
    } catch (e) {
      print('Error deleting invoice: $e');
      rethrow;
    }
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> invoiceMaps = await db.query('invoices');
    final List<Product> products = await getProducts();
    
    List<Invoice> invoices = [];
    for (var invoiceMap in invoiceMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [invoiceMap['id']],
      );

      List<InvoiceItem> items = [];
      for (var itemMap in itemMaps) {
        final product = products.firstWhere((p) => p.id == itemMap['productId']);
        items.add(InvoiceItem(
          product: product,
          quantity: itemMap['quantity'],
        ));
      }

      invoices.add(Invoice(
        id: invoiceMap['id'],
        items: items,
        createdAt: DateTime.parse(invoiceMap['createdAt']),
        customerName: invoiceMap['customerName'],
        invoiceNumber: invoiceMap['invoiceNumber'],
      ));
    }

    return invoices;
  }
} 
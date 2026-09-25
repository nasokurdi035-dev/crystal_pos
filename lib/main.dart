import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrystalPOSApp());
}

class CrystalPOSApp extends StatelessWidget {
  const CrystalPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crystal POS',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Database Helper
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('crystal_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productName TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> recordSale(String name, double price, int qty) async {
    final db = await instance.database;
    return await db.insert('sales', {
      'productName': name,
      'price': price,
      'quantity': qty,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> monthlyReset() async {
    final db = await instance.database;
    await db.delete('sales');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PosScreen(),
    const ProductsScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'فرۆشتن (POS)'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'کاڵاکان'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'ئامار و ڕاپۆرت'),
        ],
      ),
    );
  }
}

// 1. POS Screen
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final data = await DatabaseHelper.instance.getProducts();
    setState(() => _products = data);
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['cartQty'] += 1;
      } else {
        _cart.add({...product, 'cartQty': 1});
      }
    });
  }

  double get _totalAmount {
    double total = 0;
    for (var item in _cart) {
      total += (item['price'] as double) * (item['cartQty'] as int);
    }
    return total;
  }

  void _checkout() async {
    if (_cart.isEmpty) return;
    for (var item in _cart) {
      await DatabaseHelper.instance.recordSale(
        item['name'],
        item['price'],
        item['cartQty'],
      );
    }
    setState(() => _cart.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فرۆشتنەکە بە سەرکەوتوویی تۆمار کرا!')),
    );
  }

  void _scanBarcode() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null) {
      final matchedProduct = _products.firstWhere(
        (p) => p['barcode'] == scannedCode,
        orElse: () => {},
      );

      if (matchedProduct.isNotEmpty) {
        _addToCart(matchedProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('کاڵا نەدۆزرایەوە بە بارکۆدی: $scannedCode')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سیستەمی فرۆشگە (POS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(product['name']),
                    subtitle: Text('نرخ: \$${product['price']} | بارکۆد: ${product['barcode']}'),
                    trailing: ElevatedButton(
                      onPressed: () => _addToCart(product),
                      child: const Text('زیادکردن'),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                const Text('سەبەتەی کڕین', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        title: Text(item['name']),
                        trailing: Text('${item['cartQty']} دانە - \$${item['price'] * item['cartQty']}'),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('کۆی گشتی: \$${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: _checkout,
                      icon: const Icon(Icons.check),
                      label: const Text('فرۆشتن تەواو بکە'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Barcode Scanner Screen
class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سکانکردنی بارکۆد')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

// 2. Products Screen (Add/Manage Products)
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() async {
    final data = await DatabaseHelper.instance.getProducts();
    setState(() => _products = data);
  }

  void _addProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;

    await DatabaseHelper.instance.insertProduct({
      'name': _nameController.text,
      'barcode': _barcodeController.text.isEmpty ? '0000' : _barcodeController.text,
      'price': double.parse(_priceController.text),
      'quantity': int.tryParse(_qtyController.text) ?? 1,
    });

    _nameController.clear();
    _barcodeController.clear();
    _priceController.clear();
    _qtyController.clear();

    _refreshProducts();
    Navigator.pop(context);
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('زیادکردنی کاڵای نوێ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ناوی کاڵا')),
              TextField(controller: _barcodeController, decoration: const InputDecoration(labelText: 'بارکۆد')),
              TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نرخ')),
              TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بڕ (دانە)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(onPressed: _addProduct, child: const Text('پاشەکەوتکردن')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بەڕێوەبردنی کاڵاکان')),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product['name']),
            subtitle: Text('نرخ: \$${product['price']} | بڕ: ${product['quantity']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DatabaseHelper.instance.deleteProduct(product['id']);
                _refreshProducts();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 3. Reports & Monthly Reset Screen
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() async {
    final db = await DatabaseHelper.instance.database;
    final sales = await db.query('sales', orderBy: 'id DESC');
    setState(() => _sales = sales);
  }

  void _monthlyResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سفرکردنەوەی مانگانە'),
        content: const Text('ئایا دڵنیای لە سفربوونەوەی سەرجەم ئامار و فرۆشتنەکان؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('نەخێر')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await DatabaseHelper.instance.monthlyReset();
              _loadSales();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مانگەکە بە سەرکەوتوویی سفربووەوە!')),
              );
            },
            child: const Text('بەڵێ، سفرکردنەوە'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = _sales.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int)));

    return Scaffold(
      appBar: AppBar(title: const Text('ئامار و ڕاپۆرتی فرۆشتن')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('کۆی داهاتی گشتی:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.indigo, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: _monthlyResetDialog,
            icon: const Icon(Icons.refresh),
            label: const Text('دوگمەی سفرکردنەوەی مانگانە'),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return ListTile(
                  title: Text(sale['productName']),
                  subtitle: Text('بەروار: ${sale['date'].substring(0, 10)}'),
                  trailing: Text('${sale['quantity']} دانە - \$${(sale['price'] as double) * (sale['quantity'] as int)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

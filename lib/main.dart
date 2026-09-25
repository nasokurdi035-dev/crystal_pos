import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'add_product.dart';
import 'checkout_screen.dart';

void main() {
  runApp(const CrystalPosApp());
}

class CrystalPosApp extends StatelessWidget {
  const CrystalPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crystal POS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const POSHomeScreen(),
    );
  }
}

class POSHomeScreen extends StatefulWidget {
  const POSHomeScreen({super.key});

  @override
  State<POSHomeScreen> createState() => _POSHomeScreenState();
}

class _POSHomeScreenState extends State<POSHomeScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    final data = await DbHelper.loadProductsFromExcel();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سیستەمی فرۆشتنی کریستاڵ (POS)'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale, size: 28),
            tooltip: 'کاشێر / فرۆشتن',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
              _refreshProducts(); // دوای گەڕانەوە لە کاشێر داتاکان نوێ دەکەینەوە
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text(
                    'هیچ کالایەک نەدۆزرایەوە!\nتکایە دڵنیابە فایلی ئێکسڵ لە جێگەی خۆیدایە',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.diamond, color: Colors.blueAccent),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text('نرخی کڕین: \$${item['buyPrice']} | فرۆشراو: ${item['soldCount']}'),
                        trailing: Text(
                          '\$${item['price']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          _refreshProducts();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

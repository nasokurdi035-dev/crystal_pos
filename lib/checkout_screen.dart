import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'scanner_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0.0;

  void _scanAndAddItem() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && scannedCode is String) {
      final products = await DBHelper.getProducts();
      final item = products.firstWhere(
        (p) => p['barcode'] == scannedCode,
        orElse: () => {},
      );

      if (item.isNotEmpty) {
        setState(() {
          _cartItems.add(item);
          _totalAmount += (item['price'] as num).toDouble();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ئەم بارکۆدە لە داتابەیسدا نەدۆزرایەوە!')),
          );
        }
      }
    }
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _totalAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کاشێر و دەرکردنی وەسڵ'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCart,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'سەبەتەکە بەتاڵە!\nدۆگمەی سکان داگرە بۆ زیادکردنی کالا',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.green),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text('کۆد: ${item['barcode']}'),
                        trailing: Text(
                          '\$${item['price']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'کۆی گشتی:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanAndAddItem,
        label: const Text('سکانکردنی کالا'),
        icon: const Icon(Icons.qr_code_scanner),
        backgroundColor: Colors.green,
      ),
    );
  }
}

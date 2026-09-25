import 'package:flutter/services.dart';
import 'package:excel/excel.dart';

class DbHelper {
  static Future<List<Map<String, dynamic>>> loadProductsFromExcel() async {
    try {
      ByteData data = await rootBundle.load('assets/داتای دوکانەکەم.xlsx');
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      var excel = Excel.decodeBytes(bytes);
      List<Map<String, dynamic>> productList = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        // تێپەڕاندنی خشتەی سەری ستوونەکان (Row 0)
        for (var row in sheet.rows.skip(1)) {
          if (row.isEmpty) continue;
          
          var name = row[0]?.value?.toString() ?? ''; // ناوی کاڵا (ستوونی A)
          var buyPrice = double.tryParse(row[1]?.value?.toString() ?? '0') ?? 0.0; // نرخی کڕین (ستوونی B)
          var sellPrice = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0; // نرخی فرۆشتن (ستوونی C)
          var soldCount = int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0; // عدد فرۆشراو (ستوونی D)

          if (name.isNotEmpty) {
            double totalSales = soldCount * sellPrice;
            double totalProfit = soldCount * (sellPrice - buyPrice);
            double capital = soldCount * buyPrice;

            productList.add({
              'name': name,
              'buyPrice': buyPrice,
              'price': sellPrice, // نرخی فرۆشتن
              'soldCount': soldCount,
              'totalSales': totalSales,
              'totalProfit': totalProfit,
              'capital': capital,
              'barcode': '100${productList.length + 1}',
            });
          }
        }
      }
      return productList;
    } catch (e) {
      print('کێشە لە خوێندنەوەی فایلەکەدا هەبوو: $e');
      return [];
    }
  }
}

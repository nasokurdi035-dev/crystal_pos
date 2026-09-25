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

        for (var row in sheet.rows.skip(1)) {
          if (row.isEmpty) continue;
          
          var name = row[0]?.value?.toString() ?? '';
          var price = double.tryParse(row[1]?.value?.toString() ?? '0') ?? 0.0;
          var stock = int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0;

          if (name.isNotEmpty) {
            productList.add({
              'name': name,
              'price': price,
              'stock': stock,
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

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class DbHelper {
  static Future<String> _getLocalFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/داتای دوکانەکەم.xlsx';
    
    File file = File(path);
    // ئەگەر فایلەکە نەبوو، لە assetsـەوە دەگوازرێتەوە
    if (!await file.exists()) {
      try {
        ByteData data = await rootBundle.load('assets/داتای دوکانەکەم.xlsx');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes);
      } catch (e) {
        print('کێشە لە هاوردەکردنی فایلی ئێکسڵ: $e');
      }
    }
    return path;
  }

  static Future<List<Map<String, dynamic>>> loadProductsFromExcel() async {
    try {
      String filePath = await _getLocalFilePath();
      var bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      
      List<Map<String, dynamic>> productList = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        int index = 0;
        for (var row in sheet.rows.skip(1)) {
          if (row.isEmpty || row[0] == null) continue;
          
          var name = row[0]?.value?.toString() ?? '';
          if (name.isEmpty || name == 'null') continue;

          var buyPrice = double.tryParse(row.length > 1 ? row[1]?.value?.toString() ?? '0' : '0') ?? 0.0;
          var sellPrice = double.tryParse(row.length > 2 ? row[2]?.value?.toString() ?? '0' : '0') ?? 0.0;
          var soldCount = int.tryParse(row.length > 3 ? row[3]?.value?.toString() ?? '0' : '0') ?? 0;

          productList.add({
            'rowIndex': index + 1,
            'name': name,
            'buyPrice': buyPrice,
            'price': sellPrice,
            'soldCount': soldCount,
            'totalSales': soldCount * sellPrice,
            'totalProfit': soldCount * (sellPrice - buyPrice),
            'capital': soldCount * buyPrice,
            'barcode': '100${index + 1}',
          });
          index++;
        }
      }
      return productList;
    } catch (e) {
      print('کێشە لە خوێندنەوەی ئێکسڵدا: $e');
      return [];
    }
  }

  static Future<void> recordSale(String productName) async {
    try {
      String filePath = await _getLocalFilePath();
      var bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          var row = sheet.rows[i];
          var name = row[0]?.value?.toString() ?? '';

          if (name == productName) {
            var currentSold = int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0;
            sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i), currentSold + 1);
            
            var file = File(filePath);
            file.writeAsBytesSync(excel.encode()!);
            break;
          }
        }
      }
    } catch (e) {
      print('کێشە لە تۆمارکردنی فرۆشتندا: $e');
    }
  }

  static Future<void> resetMonthlySales() async {
    try {
      String filePath = await _getLocalFilePath();
      var bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i), 0);
        }

        var file = File(filePath);
        file.writeAsBytesSync(excel.encode()!);
      }
    } catch (e) {
      print('کێشە لە سفرکردنەوەی مانگانەدا: $e');
    }
  }
}

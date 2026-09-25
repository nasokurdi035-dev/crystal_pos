import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class DbHelper {
  // هێنانی ڕێڕەوی فایلی ئێکسڵ لە ناوخۆی مۆبایلدا
  static Future<String> _getLocalFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/داتای دوکانەکەم.xlsx';
    
    // ئەگەر فایلەکە لە ناوخۆ نەبوو، لە assetsـەوە دەگوازینەوە
    File file = File(path);
    if (!await file.exists()) {
      ByteData data = await rootBundle.load('assets/داتای دوکانەکەم.xlsx');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes);
    }
    return path;
  }

  // خوێندنەوەی کاڵاکان لە فایلی ئێکسڵەوە
  static Future<List<Map<String, dynamic>>> loadProductsFromExcel() async {
    try {
      String filePath = await _getLocalFilePath();
      var bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      
      List<Map<String, dynamic>> productList = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        // تێپەڕاندنی سەری ستوونەکان (Row 0)
        int index = 0;
        for (var row in sheet.rows.skip(1)) {
          if (row.isEmpty) continue;
          
          var name = row[0]?.value?.toString() ?? '';
          if (name.isEmpty || name == 'null') continue;

          var buyPrice = double.tryParse(row[1]?.value?.toString() ?? '0') ?? 0.0;
          var sellPrice = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0;
          var soldCount = int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0;

          double totalSales = soldCount * sellPrice;
          double totalProfit = soldCount * (sellPrice - buyPrice);
          double capital = soldCount * buyPrice;

          productList.add({
            'rowIndex': index + 1, // بۆ زانینی ڕیزەکە لە ئێکسڵدا
            'name': name,
            'buyPrice': buyPrice,
            'price': sellPrice,
            'soldCount': soldCount,
            'totalSales': totalSales,
            'totalProfit': totalProfit,
            'capital': capital,
            'barcode': '100${index + 1}',
          });
          index++;
        }
      }
      return productList;
    } catch (e) {
      print('کێشە لە خوێندنەوەی فایلەکەدا هەبوو: $e');
      return [];
    }
  }

  // زیادکردنی عەددی فرۆشراو بۆ کاڵایەک و پاشەکەوتکردنی لە ئێکسڵدا
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
            
            // پاشەکەوتکردنەوەی فایلەکە
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

  // سفرکردنەوەی مانگانە (گێڕانەوەی عەددی فرۆشراو بۆ سفر)
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

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class PdfService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static DateTime _convertToDateTime(dynamic timestamp) {
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    throw Exception('Unsupported timestamp type: ${timestamp.runtimeType}');
  }

  static Future<File> generateProductListPdf(List<Product> products, String filePath) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Daftar Produk', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 25,
            cellHeight: 40,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
            },
            headerStyle: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 10,
            ),
            headers: ['Nama', 'Kategori', 'SKU', 'Harga', 'Stok'],
            data: products.map((product) => [
              product.name,
              product.category,
              product.sku ?? '-',
              _currencyFormat.format(product.price),
              product.stock.toString(),
            ]).toList(),
          ),
        ],
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateStockHistoryPdf(List<Map<String, dynamic>> logs, String filePath) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Riwayat Stok', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 25,
            cellHeight: 40,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            headerStyle: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 10,
            ),
            headers: ['Produk', 'Tipe', 'Jumlah', 'Tanggal', 'User'],
            data: logs.map((log) => [
              log['productName'] as String,
              (log['type'] as String) == 'in' ? 'Masuk' : 'Keluar',
              log['qty'].toString(),
              DateFormat('dd/MM/yyyy HH:mm').format(_convertToDateTime(log['timestamp'])),
              log['userName'] as String,
            ]).toList(),
          ),
        ],
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateActivityLogPdf(List<Map<String, dynamic>> activities, String filePath) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Log Aktivitas', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 25,
            cellHeight: 40,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
            },
            headerStyle: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 10,
            ),
            headers: ['User', 'Tanggal', 'Tipe', 'Deskripsi'],
            data: activities.map((activity) => [
              activity['userName'] as String,
              DateFormat('dd/MM/yyyy HH:mm').format(_convertToDateTime(activity['timestamp'])),
              activity['type'] as String,
              activity['description'] as String,
            ]).toList(),
          ),
        ],
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
} 
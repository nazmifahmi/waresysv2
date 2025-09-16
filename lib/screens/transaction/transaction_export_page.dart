import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class TransactionExportPage extends StatelessWidget {
  const TransactionExportPage({super.key});

  Future<void> _exportTransactions(BuildContext context, TransactionType type) async {
    try {
      final transactions = await TransactionService().getTransactionsStream(type: type).first;
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                type == TransactionType.sales ? 'Riwayat Transaksi Penjualan' : 'Riwayat Transaksi Pembelian',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: [
                  'Tanggal',
                  'Customer/Supplier',
                  'Produk',
                  'Qty',
                  'Total',
                  'Status Bayar',
                  'Status Kirim',
                ],
                data: transactions.map((trx) {
                  final produk = trx.items.map((item) => '${item.productName}').join(', ');
                  final qty = trx.items.fold(0, (sum, item) => sum + item.quantity);
                  return [
                    DateFormat('dd/MM/yyyy').format(trx.createdAt),
                    trx.customerSupplierName,
                    produk,
                    qty.toString(),
                    trx.total.toStringAsFixed(2),
                    trx.paymentStatus.name.toUpperCase(),
                    trx.deliveryStatus.name.toUpperCase(),
                  ];
                }).toList(),
              ),
            ],
          ),
        ),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/riwayat_${type.name}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
      // Log aktivitas export
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';
      final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
      await FirestoreService().logActivity(
        userId: userId,
        userName: userName,
        type: 'transaction',
        action: 'export_pdf',
        description: 'Export riwayat transaksi ${type == TransactionType.sales ? 'sales' : 'purchase'} PDF',
        details: {
          'file': file.path,
          'type': type.name,
          'periode': transactions.isNotEmpty ? '${DateFormat('dd/MM/yyyy').format(transactions.first.createdAt)} - ${DateFormat('dd/MM/yyyy').format(transactions.last.createdAt)}' : '-',
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export Seluruh Sales (PDF)'),
              onPressed: () => _exportTransactions(context, TransactionType.sales),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export Seluruh Purchase (PDF)'),
              onPressed: () => _exportTransactions(context, TransactionType.purchase),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_model.dart';
import '../../services/finance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';

class FinanceTransactionsPage extends StatefulWidget {
  @override
  State<FinanceTransactionsPage> createState() => _FinanceTransactionsPageState();
}

class _FinanceTransactionsPageState extends State<FinanceTransactionsPage> {
  final _service = FinanceService();
  final _trxService = TransactionService();
  final _searchController = TextEditingController();
  String _search = '';
  String _filter = 'all'; // all, sales, purchase, manual

  Stream<List<_UnifiedTransaction>> get _unifiedTransactionsStream {
    final manualStream = _service.getTransactionsStream()
      .map((list) => list.where((t) => 
        t.category != 'Penjualan (Sales)' && 
        t.category != 'Pembelian (Purchase)' &&
        !t.id.startsWith('trx_') // Filter out auto-generated finance records from sales/purchase
      ).toList());
    
    final salesStream = _trxService.getTransactionsStream(type: TransactionType.sales)
      .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());
    
    final purchaseStream = _trxService.getTransactionsStream(type: TransactionType.purchase)
      .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());
    
    return Rx.combineLatest3<List<FinanceTransaction>, List<TransactionModel>, List<TransactionModel>, List<_UnifiedTransaction>>(
      manualStream,
      salesStream,
      purchaseStream,
      (manual, sales, purchase) {
        final unified = <_UnifiedTransaction>[];
        // Only add sales/purchase transactions
        unified.addAll(sales.map((t) => _UnifiedTransaction.fromSalesPurchase(t)));
        unified.addAll(purchase.map((t) => _UnifiedTransaction.fromSalesPurchase(t)));
        // Add manual transactions that are not related to sales/purchase
        unified.addAll(manual.map((t) => _UnifiedTransaction.fromFinance(t)));
        unified.sort((a, b) => b.date.compareTo(a.date));
        return unified;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              DropdownButton<String>(
                value: _filter,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('Semua')),
                  DropdownMenuItem(value: 'sales', child: Text('Sales')),
                  DropdownMenuItem(value: 'purchase', child: Text('Purchase')),
                  DropdownMenuItem(value: 'manual', child: Text('Manual')),
                ],
                onChanged: (v) => setState(() => _filter = v!),
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(hintText: 'Cari transaksi...'),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Tambah'),
                onPressed: () => _showAddTransactionDialog(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<_UnifiedTransaction>>(
            stream: _unifiedTransactionsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              var data = snapshot.data!;
              if (_filter == 'sales') {
                data = data.where((trx) => trx.source == 'sales').toList();
              } else if (_filter == 'purchase') {
                data = data.where((trx) => trx.source == 'purchase').toList();
              } else if (_filter == 'manual') {
                data = data.where((trx) => trx.source == null).toList();
              }
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                data = data.where((trx) =>
                  trx.category.toLowerCase().contains(q) ||
                  (trx.description?.toLowerCase().contains(q) ?? false) ||
                  (trx.customerSupplierName?.toLowerCase().contains(q) ?? false) ||
                  (trx.salesPurchaseTransaction?.items.any((item) => item.productName.toLowerCase().contains(q)) ?? false)
                ).toList();
              }
              if (data.isEmpty) {
                return Center(child: Text('Belum ada transaksi keuangan'));
              }
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, i) {
                  final trx = data[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        trx.type == FinanceTransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                        color: trx.type == FinanceTransactionType.income ? Colors.green : Colors.red,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              trx.category,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (trx.source != null) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: trx.source == 'sales' ? Colors.blue[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                trx.source == 'sales' ? 'Penjualan (Sales)' : 'Pembelian (Purchase)',
                                style: TextStyle(
                                  color: trx.source == 'sales' ? Colors.blue : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(trx.date)}'
                        '${trx.customerSupplierName != null ? ' | ' + trx.customerSupplierName! : ''}'
                        '${trx.description != null && trx.description!.isNotEmpty ? ' | ' + trx.description! : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              (trx.type == FinanceTransactionType.income ? '+ ' : '- ') + _formatRupiah(trx.amount),
                              style: TextStyle(
                                color: trx.type == FinanceTransactionType.income ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (trx.source == null) // hanya transaksi manual yang bisa dihapus
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.grey),
                              onPressed: () => _deleteTransaction(trx.financeTransaction!),
                            ),
                        ],
                      ),
                      onTap: () => _showDetailPopup(context, trx),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double n) {
    final f = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return f.format(n);
  }

  void _showAddTransactionDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final kas = await _service.getBalance();
    final formKey = GlobalKey<FormState>();
    FinanceTransactionType _type = FinanceTransactionType.expense;
    String _category = '';
    String _desc = '';
    double _amount = 0;
    DateTime _date = DateTime.now();
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tambah Transaksi'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: StreamBuilder<List<FinanceBudget>>(
                stream: _service.getBudgetsStream(month: now.month, year: now.year),
                builder: (context, snap) {
                  final budgetCats = snap.data?.map((b) => b.category).toList() ?? [];
                  final allCats = [...budgetCats, ..._service.getCategories()];
                  final categories = {...allCats}.toList()..removeWhere((c) => c == null || c.isEmpty);
                  categories.remove('Lainnya');
                  categories.add('Lainnya');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<FinanceTransactionType>(
                        value: _type,
                        items: FinanceTransactionType.values.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == FinanceTransactionType.income ? 'Pemasukan' : 'Pengeluaran'),
                        )).toList(),
                        onChanged: (v) => setDialogState(() => _type = v!),
                        decoration: InputDecoration(labelText: 'Tipe'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _category.isNotEmpty ? _category : null,
                        items: categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        )).toList(),
                        onChanged: (v) => setDialogState(() => _category = v ?? ''),
                        decoration: InputDecoration(labelText: 'Kategori'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib dipilih' : null,
                      ),
                      if (_category == 'Lainnya')
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Kategori Manual'),
                          onChanged: (v) => _desc = v,
                          validator: (v) => _category == 'Lainnya' && (v == null || v.isEmpty) ? 'Kategori wajib diisi' : null,
                        ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Deskripsi'),
                        onChanged: (v) => _desc = v,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Nominal'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _amount = double.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Nominal harus > 0' : null,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setDialogState(() => _date = picked);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final trx = FinanceTransaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: _type,
                    category: _category == 'Lainnya' && _desc.isNotEmpty ? _desc : _category,
                    amount: _amount,
                    description: _desc,
                    date: _date,
                    createdBy: user?.uid ?? '',
                  );
                  await _service.addTransaction(
                    trx,
                    currentKas: kas.kasUtama,
                    userId: user?.uid ?? '',
                    userName: user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User',
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal tambah transaksi: $e')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTransaction(FinanceTransaction trx) async {
    final user = FirebaseAuth.instance.currentUser;
    final kas = await _service.getBalance();
    try {
      await _service.deleteTransaction(
        trx,
        currentKas: kas.kasUtama,
        userId: user?.uid ?? '',
        userName: user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus transaksi: $e')),
      );
    }
  }

  void _showDetailPopup(BuildContext context, _UnifiedTransaction trx) {
    showDialog(
      context: context,
      builder: (context) {
        if (trx.salesPurchaseTransaction != null) {
          final t = trx.salesPurchaseTransaction!;
          return AlertDialog(
            title: Row(
              children: [
                Icon(t.type == TransactionType.sales ? Icons.point_of_sale : Icons.shopping_cart, color: t.type == TransactionType.sales ? Colors.blue : Colors.orange),
                SizedBox(width: 8),
                Text(t.type == TransactionType.sales ? 'Detail Penjualan' : 'Detail Pembelian'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID Transaksi: \\${t.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Customer/Supplier: \\${t.customerSupplierName}'),
                  SizedBox(height: 8),
                  Text('Tanggal: \\${DateFormat('dd MMMM yyyy HH:mm').format(t.createdAt)}'),
                  SizedBox(height: 8),
                  Text('Status Pembayaran: \\${t.paymentStatus.name.toUpperCase()}'),
                  Text('Status Pengiriman: \\${t.deliveryStatus.name.toUpperCase()}'),
                  if (t.trackingNumber != null && t.trackingNumber!.isNotEmpty)
                    Text('Resi: \\${t.trackingNumber}'),
                  SizedBox(height: 12),
                  Text('Daftar Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...t.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text('\\${item.productName} x\\${item.quantity}')),
                        Text(_formatRupiah(item.price)),
                        SizedBox(width: 8),
                        Text('Subtotal: \\${_formatRupiah(item.subtotal)}'),
                      ],
                    ),
                  )),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatRupiah(t.total), style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (t.notes != null && t.notes!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text('Catatan: \\${t.notes!}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text('Cetak Invoice'),
                onPressed: () async {
                  await _printInvoice(t, context);
                },
              ),
            ],
          );
        } else if (trx.financeTransaction != null) {
          final t = trx.financeTransaction!;
          return AlertDialog(
            title: Row(
              children: [
                Icon(t.type == FinanceTransactionType.income ? Icons.arrow_downward : Icons.arrow_upward, color: t.type == FinanceTransactionType.income ? Colors.green : Colors.red),
                SizedBox(width: 8),
                Text(t.type == FinanceTransactionType.income ? 'Detail Pemasukan' : 'Detail Pengeluaran'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID: \\${t.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Kategori: \\${t.category}'),
                  SizedBox(height: 8),
                  Text('Nominal: \\${_formatRupiah(t.amount)}'),
                  SizedBox(height: 8),
                  Text('Deskripsi: \\${t.description}'),
                  SizedBox(height: 8),
                  Text('Tanggal: \\${DateFormat('dd MMMM yyyy HH:mm').format(t.date)}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _showEditManualTransactionDialog(context, t);
                },
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text('Cetak Invoice'),
                onPressed: () async {
                  await _printManualInvoice(t, context);
                },
              ),
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _printInvoice(TransactionModel trx, BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('ID: ${trx.id}'),
            pw.Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(trx.createdAt)}'),
            pw.Text('Customer/Supplier: ${trx.customerSupplierName}'),
            pw.Text('Status Pembayaran: ${trx.paymentStatus.name.toUpperCase()}'),
            pw.Text('Status Pengiriman: ${trx.deliveryStatus.name.toUpperCase()}'),
            if (trx.trackingNumber != null && trx.trackingNumber!.isNotEmpty)
              pw.Text('Resi: ${trx.trackingNumber}'),
            pw.SizedBox(height: 12),
            pw.Text('Produk:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Nama', 'Qty', 'Harga', 'Subtotal'],
              data: trx.items.map((item) => [
                item.productName,
                item.quantity.toString(),
                item.price.toStringAsFixed(2),
                item.subtotal.toStringAsFixed(2),
              ]).toList(),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Total: ${trx.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (trx.notes != null && trx.notes!.isNotEmpty)
              pw.Text('Catatan: ${trx.notes!}'),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${trx.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> _printManualInvoice(FinanceTransaction trx, BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('ID: \\${trx.id}'),
            pw.Text('Tanggal: \\${DateFormat('dd/MM/yyyy').format(trx.date)}'),
            pw.Text('Kategori: \\${trx.category}'),
            pw.Text('Nominal: \\${_formatRupiah(trx.amount)}'),
            pw.Text('Deskripsi: \\${trx.description}'),
            pw.Text('Tipe: \\${trx.type == FinanceTransactionType.income ? 'Pemasukan' : 'Pengeluaran'}'),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_manual_${trx.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> _showEditManualTransactionDialog(BuildContext context, FinanceTransaction trx) async {
    final _formKey = GlobalKey<FormState>();
    String _category = trx.category;
    String _desc = trx.description;
    double _amount = trx.amount;
    DateTime _date = trx.date;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Transaksi'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _category,
                  decoration: InputDecoration(labelText: 'Kategori'),
                  onChanged: (v) => _category = v,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  initialValue: _desc,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                  onChanged: (v) => _desc = v,
                ),
                TextFormField(
                  initialValue: _amount.toStringAsFixed(0),
                  decoration: InputDecoration(labelText: 'Nominal'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _amount = double.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Nominal harus > 0' : null,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Tanggal: \\${DateFormat('dd/MM/yyyy').format(_date)}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) _date = picked;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final updated = FinanceTransaction(
                id: trx.id,
                type: trx.type,
                category: _category,
                amount: _amount,
                description: _desc,
                date: _date,
                createdBy: trx.createdBy,
              );
              await FinanceService().updateTransaction(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// Helper class untuk menyatukan data transaksi manual dan sales/purchase
enum _UnifiedSource { manual, sales, purchase }

class _UnifiedTransaction {
  final FinanceTransactionType type;
  final String category;
  final double amount;
  final String? description;
  final DateTime date;
  final String? customerSupplierName;
  final String? source; // 'sales', 'purchase', atau null (manual)
  final FinanceTransaction? financeTransaction;
  final TransactionModel? salesPurchaseTransaction;

  _UnifiedTransaction({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.customerSupplierName,
    this.source,
    this.financeTransaction,
    this.salesPurchaseTransaction,
  });

  factory _UnifiedTransaction.fromFinance(FinanceTransaction t) => _UnifiedTransaction(
    type: t.type,
    category: t.category,
    amount: t.amount,
    date: t.date,
    description: t.description,
    source: null,
    financeTransaction: t,
    salesPurchaseTransaction: null,
  );

  factory _UnifiedTransaction.fromSalesPurchase(TransactionModel t) => _UnifiedTransaction(
    type: t.type == TransactionType.sales ? FinanceTransactionType.income : FinanceTransactionType.expense,
    category: t.type == TransactionType.sales ? 'Penjualan (Sales)' : 'Pembelian (Purchase)',
    amount: t.total,
    date: t.createdAt,
    description: t.notes,
    customerSupplierName: t.customerSupplierName,
    source: t.type == TransactionType.sales ? 'sales' : 'purchase',
    financeTransaction: null,
    salesPurchaseTransaction: t,
  );
}
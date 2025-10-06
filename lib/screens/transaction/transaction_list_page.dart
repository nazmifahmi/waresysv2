import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import 'package:intl/intl.dart';
import 'transaction_form_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/finance_service.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class TransactionListPage extends StatelessWidget {
  final TransactionType type;
  const TransactionListPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    ValueNotifier<String> searchQuery = ValueNotifier('');
    ValueNotifier<String?> selectedProduct = ValueNotifier<String?>(null);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderDark,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: searchQuery,
                  builder: (context, value, _) => CommonWidgets.buildTextField(
                    label: 'Pencarian',
                    hint: type == TransactionType.sales 
                        ? 'Cari transaksi penjualan...' 
                        : 'Cari transaksi pembelian...',
                    controller: searchController,
                    prefixIcon: Icons.search,
                    onChanged: (val) => searchQuery.value = val,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              CommonWidgets.buildPrimaryButton(
                text: 'Tambah',
                icon: Icons.add,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionFormPage(type: type),
                    ),
                  );
                  // Setelah kembali dari form, StreamBuilder akan otomatis refresh
                },
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingS,
          ),
          child: ValueListenableBuilder<String?>(
            valueListenable: selectedProduct,
            builder: (context, selected, _) {
              return StreamBuilder<List<TransactionModel>>(
                stream: TransactionService().getTransactionsStream(type: type),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  // Ambil semua nama produk unik dari transaksi
                  final allProducts = snapshot.data!
                    .expand((trx) => trx.items.map((item) => item.productName))
                    .toSet()
                    .toList();
                  allProducts.sort();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selected,
                        hint: Text(
                          'Filter produk',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceDark,
                        style: AppTheme.bodyMedium,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Semua Produk',
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                          ...allProducts.map((p) => DropdownMenuItem<String?>(
                            value: p,
                            child: Text(
                              p,
                              style: AppTheme.bodyMedium,
                            ),
                          ))
                        ],
                        onChanged: (val) => selectedProduct.value = val,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: searchQuery,
            builder: (context, query, _) => ValueListenableBuilder<String?>(
              valueListenable: selectedProduct,
              builder: (context, selectedProd, _) => StreamBuilder<List<TransactionModel>>(
              stream: TransactionService().getTransactionsStream(type: type),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: CommonWidgets.buildLoadingIndicator(),
                  );
                }
                var transactions = snapshot.data!;
                if (query.isNotEmpty) {
                  final q = query.toLowerCase();
                  transactions = transactions.where((trx) {
                    final inCustomer = trx.customerSupplierName.toLowerCase().contains(q);
                    final inId = trx.id.toLowerCase().contains(q);
                    final inProduct = trx.items.any((item) => item.productName.toLowerCase().contains(q));
                    return inCustomer || inId || inProduct;
                  }).toList();
                }
                  // Filter by selected product
                  if (selectedProd != null) {
                    transactions = transactions.where((trx) => trx.items.any((item) => item.productName == selectedProd)).toList();
                  }
                if (transactions.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(
                           type == TransactionType.sales 
                               ? Icons.point_of_sale_outlined 
                               : Icons.shopping_cart_outlined,
                           size: 64,
                           color: AppTheme.textTertiary,
                         ),
                         const SizedBox(height: AppTheme.spacingL),
                         Text(
                           type == TransactionType.sales
                               ? 'Belum ada transaksi penjualan'
                               : 'Belum ada transaksi pembelian',
                           style: AppTheme.heading4.copyWith(
                             color: AppTheme.textSecondary,
                           ),
                         ),
                         const SizedBox(height: AppTheme.spacingS),
                         Text(
                           'Tambah transaksi baru untuk memulai',
                           style: AppTheme.bodyMedium.copyWith(
                             color: AppTheme.textTertiary,
                           ),
                         ),
                       ],
                     ),
                   );
                 }
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, i) {
                    final trx = transactions[i];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(trx.createdAt);
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: AppTheme.cardDecoration.copyWith(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.surfaceDark,
                            AppTheme.cardDark,
                          ],
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: (type == TransactionType.sales 
                                ? AppTheme.accentBlue 
                                : AppTheme.accentGreen).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Icon(
                            type == TransactionType.sales 
                                ? Icons.point_of_sale 
                                : Icons.shopping_cart,
                            color: type == TransactionType.sales 
                                ? AppTheme.accentBlue 
                                : AppTheme.accentGreen,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          trx.customerSupplierName,
                          style: AppTheme.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              'Tanggal: $dateStr',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Total: ${trx.total.toStringAsFixed(2)}',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Row(
                              children: [
                                _statusChip(trx),
                                const SizedBox(width: AppTheme.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingS,
                                    vertical: AppTheme.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _deliveryStatusColor(trx.deliveryStatus).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    trx.deliveryStatus.name.toUpperCase(),
                                    style: AppTheme.labelSmall.copyWith(
                                      color: _deliveryStatusColor(trx.deliveryStatus),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.textTertiary,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => TransactionDetailDialog(trx: trx),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(TransactionModel trx) {
    Color color;
    String label;
    if (trx.paymentStatus == PaymentStatus.paid) {
      color = Colors.green;
      label = 'Paid';
    } else {
      color = Colors.orange;
      label = 'Unpaid';
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  static Color _deliveryStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.canceled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class TransactionDetailDialog extends StatelessWidget {
  final TransactionModel trx;
  const TransactionDetailDialog({super.key, required this.trx});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detail Transaksi'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Customer/Supplier', trx.customerSupplierName),
            _row('Tanggal', DateFormat('dd/MM/yyyy HH:mm').format(trx.createdAt)),
            _row('Metode Pembayaran', trx.paymentMethod.name.toUpperCase()),
            _row('Status Pembayaran', trx.paymentStatus.name.toUpperCase()),
            _row('Status Pengiriman', trx.deliveryStatus.name.toUpperCase()),
            if (trx.trackingNumber != null && trx.trackingNumber!.isNotEmpty)
              _row('Resi', trx.trackingNumber!),
            if (trx.notes != null && trx.notes!.isNotEmpty)
              _row('Catatan', trx.notes!),
            const SizedBox(height: 8),
            const Text('Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...trx.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('- ${item.productName} | Qty: ${item.quantity} x ${item.price.toStringAsFixed(2)} = ${item.subtotal.toStringAsFixed(2)}'),
                )),
            const SizedBox(height: 8),
            Text('Total: ${trx.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Log History:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...trx.logHistory.map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    '- [${DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp)}] ${log.action} oleh ${log.userName}${log.note != null && log.note!.isNotEmpty ? ': ${log.note}' : ''}',
                    style: TextStyle(fontSize: 12),
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await showDialog<_StatusUpdateResult>(
              context: context,
              builder: (context) => _EditStatusDialog(trx: trx),
            );
            if (result != null) {
              final user = FirebaseAuth.instance.currentUser;
              await TransactionService().updateStatus(
                trxId: trx.id,
                paymentStatus: result.paymentStatus,
                deliveryStatus: result.deliveryStatus,
                trackingNumber: result.trackingNumber,
                userId: user?.uid ?? 'unknown',
                userName: user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User',
                note: result.note,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status transaksi berhasil diupdate!')),
                );
              }
            }
          },
          child: const Text('Edit Status'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
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
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal membuat invoice: $e')),
              );
            }
          },
          child: const Text('Cetak Invoice'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EditStatusDialog extends StatefulWidget {
  final TransactionModel trx;
  const _EditStatusDialog({required this.trx});
  @override
  State<_EditStatusDialog> createState() => _EditStatusDialogState();
}

class _EditStatusDialogState extends State<_EditStatusDialog> {
  late PaymentStatus _paymentStatus;
  late DeliveryStatus _deliveryStatus;
  late TextEditingController _trackingController;
  late TextEditingController _noteController;
  double? _currentKasUtama;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _paymentStatus = widget.trx.paymentStatus;
    _deliveryStatus = widget.trx.deliveryStatus;
    _trackingController = TextEditingController(text: widget.trx.trackingNumber ?? '');
    _noteController = TextEditingController();
    _loadKasUtama();
  }

  Future<void> _loadKasUtama() async {
    try {
      final balance = await FinanceService().getBalance();
      if (mounted) {
        setState(() {
          _currentKasUtama = balance.kasUtama;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateKasUtama() {
    if (widget.trx.type == TransactionType.purchase && 
        _paymentStatus == PaymentStatus.paid && 
        widget.trx.paymentStatus == PaymentStatus.unpaid &&
        _currentKasUtama != null) {
      return _currentKasUtama! >= widget.trx.total;
    }
    return true;
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Status Transaksi'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.trx.type == TransactionType.purchase && _currentKasUtama != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Saldo Kas Utama: ${_currentKasUtama!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _validateKasUtama() ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  DropdownButtonFormField<PaymentStatus>(
                    value: _paymentStatus,
                    items: PaymentStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _paymentStatus = val ?? _paymentStatus);
                      if (val == PaymentStatus.paid && !_validateKasUtama()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saldo kas utama tidak mencukupi untuk pembayaran pembelian ini!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => _paymentStatus = PaymentStatus.unpaid);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Status Pembayaran'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DeliveryStatus>(
                    value: _deliveryStatus,
                    items: DeliveryStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _deliveryStatus = val ?? _deliveryStatus),
                    decoration: const InputDecoration(labelText: 'Status Pengiriman'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _trackingController,
                    decoration: const InputDecoration(labelText: 'Resi/Tracking (opsional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Catatan perubahan (opsional)'),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_validateKasUtama()
              ? null 
              : () {
                  Navigator.pop(context, _StatusUpdateResult(
                    paymentStatus: _paymentStatus,
                    deliveryStatus: _deliveryStatus,
                    trackingNumber: _trackingController.text,
                    note: _noteController.text,
                  ));
                },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _StatusUpdateResult {
  final PaymentStatus paymentStatus;
  final DeliveryStatus deliveryStatus;
  final String trackingNumber;
  final String note;
  _StatusUpdateResult({
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.trackingNumber,
    required this.note,
  });
}
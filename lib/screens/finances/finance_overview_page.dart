import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../services/auth_service.dart';
import '../../services/finance_service.dart';
import 'package:intl/intl.dart';
import '../../models/finance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'finance_reports_page.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import 'package:rxdart/rxdart.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class FinanceOverviewPage extends StatefulWidget {
  const FinanceOverviewPage({super.key});

  @override
  State<FinanceOverviewPage> createState() => _FinanceOverviewPageState();
}

class _FinanceOverviewPageState extends State<FinanceOverviewPage> {
  final _service = FinanceService();
  final _trxService = TransactionService();
  final _authService = AuthService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Stream<List<_UnifiedTransaction>> _unifiedTransactionsStream() {
    try {
      final manualStream = _service.getTransactionsStream();
      final salesStream = _trxService.getTransactionsStream(type: TransactionType.sales)
        .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());
      final purchaseStream = _trxService.getTransactionsStream(type: TransactionType.purchase)
        .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());
      
      return Rx.combineLatest3<List<FinanceTransaction>, List<TransactionModel>, List<TransactionModel>, List<_UnifiedTransaction>>(
        manualStream,
        salesStream,
        purchaseStream,
        (manual, sales, purchase) {
          try {
            final unified = <_UnifiedTransaction>[];
            
            // Add manual transactions (filter out auto-generated ones)
            unified.addAll(manual
              .where((t) => !t.id.startsWith('trx_'))
              .map((t) => _UnifiedTransaction.fromFinance(t)));
            
            // Add sales transactions
            unified.addAll(sales.map((t) => _UnifiedTransaction.fromSalesPurchase(t)));
            
            // Add purchase transactions
            unified.addAll(purchase.map((t) => _UnifiedTransaction.fromSalesPurchase(t)));
            
            // Sort by date (most recent first)
            unified.sort((a, b) => b.date.compareTo(a.date));
            
            return unified;
          } catch (e) {
            debugPrint('Error processing unified transactions: $e');
            return <_UnifiedTransaction>[];
          }
        },
      ).handleError((error) {
        debugPrint('Error in unified transactions stream: $error');
        return <_UnifiedTransaction>[];
      });
    } catch (e) {
      debugPrint('Error creating unified transactions stream: $e');
      // Return empty stream in case of error
      return Stream.value(<_UnifiedTransaction>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Top section with financial summary (non-scrollable)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentGreen.withOpacity(0.1),
                  AppTheme.backgroundDark,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Keuangan',
                  style: AppTheme.heading2.copyWith(
                    color: AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                StreamBuilder<FinanceBalance>(
                  stream: _service.getBalanceStream(),
                  builder: (context, balanceSnap) {
                    if (balanceSnap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CommonWidgets.buildLoadingIndicator(),
                      );
                    }
                    
                    if (balanceSnap.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Error loading balance: ${balanceSnap.error}',
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final balance = balanceSnap.data ?? FinanceBalance(kasUtama: 0, bank: 0);
                    
                    return StreamBuilder<List<_UnifiedTransaction>>(
                      stream: _unifiedTransactionsStream(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
                          return Center(
                            child: CommonWidgets.buildLoadingIndicator(),
                          );
                        }
                        
                        if (snap.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Error loading transactions: ${snap.error}',
                                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final data = snap.data!;
                        final now = DateTime.now();
                        final bulanIni = data.where((trx) => trx.date.month == now.month && trx.date.year == now.year).toList();
                        final pemasukan = bulanIni.where((t) => t.type == FinanceTransactionType.income).fold(0.0, (a, b) => a + b.amount);
                        final pengeluaran = bulanIni.where((t) => t.type == FinanceTransactionType.expense).fold(0.0, (a, b) => a + b.amount);
                        
                        return Column(
                          children: [
                            if (balance.kasUtama <= 0)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                                padding: const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(
                                    color: AppTheme.errorColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_outlined,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacingS),
                                    Expanded(
                                      child: Text(
                                        'Saldo kas utama kosong atau minus!',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.errorColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            _financeBalanceCard(
                              title: 'Saldo Kas Utama',
                              amount: _formatRupiah(balance.kasUtama),
                              isAdmin: true,
                              onEdit: _isAdmin ? () => _showEditSaldoDialog(context, balance.kasUtama) : null,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Row(
                              children: [
                                Expanded(
                                  child: _financeBalanceCard(
                                    title: 'Pemasukan',
                                    amount: _formatRupiah(pemasukan),
                                    isIncome: true,
                                    subtitle: 'Bulan ini',
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: _financeBalanceCard(
                                    title: 'Pengeluaran',
                                    amount: _formatRupiah(pengeluaran),
                                    isIncome: false,
                                    subtitle: 'Bulan ini',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Activity section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aktivitas Terakhir', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Activity list (scrollable)
          Expanded(
            child: StreamBuilder<List<FinanceBalanceLog>>(
              stream: _service.getBalanceLogsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Belum ada aktivitas', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: snapshot.data!.map((log) {
                    final isBalanceChange = log.note.contains('Edit saldo');
                    IconData icon;
                    Color color;
                    String title;

                    if (isBalanceChange) {
                      icon = Icons.account_balance_wallet;
                      color = Colors.blue;
                      title = 'Perubahan Saldo';
                    } else if (log.note.contains('transaksi')) {
                      icon = log.note.contains('Pemasukan') ? Icons.arrow_downward : Icons.arrow_upward;
                      color = log.note.contains('Pemasukan') ? Colors.green : Colors.red;
                      title = log.note.contains('Pemasukan') ? 'Pemasukan' : 'Pengeluaran';
                    } else {
                      icon = Icons.info;
                      color = Colors.grey;
                      title = 'Aktivitas';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () => _showActivityDetailDialog(context, log),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(icon, color: color),
                          ),
                          title: Text(title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.note),
                              Text(
                                'Oleh: ${log.userName}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(log.date),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: isBalanceChange ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatRupiah(log.after),
                                style: TextStyle(
                                  color: log.after >= log.before ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${log.after >= log.before ? '+' : ''}${_formatRupiah(log.after - log.before)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: log.after >= log.before ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ) : null,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Admin actions at bottom
          if (_isAdmin)
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.cleaning_services),
                    label: Text('Bersihkan Data'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 36),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _showCleanupConfirmDialog(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatRupiah(double n) {
    final f = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return f.format(n);
  }

  Widget _financeBalanceCard({
    required String title,
    required String amount,
    bool isAdmin = false,
    String? subtitle,
    VoidCallback? onEdit,
    bool isIncome = false,
  }) {
    Color iconColor;
    IconData iconData;
    
    if (isIncome) {
      iconColor = AppTheme.successColor;
      iconData = Icons.trending_up;
    } else if (isAdmin) {
      iconColor = AppTheme.accentBlue;
      iconData = Icons.account_balance_wallet_outlined;
    } else {
      iconColor = AppTheme.errorColor;
      iconData = Icons.trending_down;
    }
    
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXS),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: AppTheme.heading4.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_isAdmin && onEdit != null)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
                onPressed: onEdit,
              ),
            ),
        ],
      ),
    );
  }

  void _showEditSaldoDialog(BuildContext context, double currentSaldo) async {
    final _controller = TextEditingController(text: currentSaldo.toStringAsFixed(0));
    final _service = FinanceService();
    final user = FirebaseAuth.instance.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Edit Saldo Kas Utama',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.accentGreen,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonWidgets.buildTextField(
              label: 'Saldo Baru',
              hint: 'Masukkan saldo baru dalam Rupiah',
              controller: _controller,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.textPrimary,
            ),
            onPressed: () async {
              final newSaldo = double.tryParse(_controller.text.replaceAll('.', '').replaceAll(',', '')) ?? currentSaldo;
              final before = currentSaldo;
              final after = newSaldo;
              final userId = user?.uid ?? '';
              final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
              await _service.updateBalance(after, userId: userId, userName: userName);
              await _service.addBalanceLog(FinanceBalanceLog(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                before: before,
                after: after,
                userId: userId,
                userName: userName,
                date: DateTime.now(),
                note: 'Edit saldo manual oleh admin',
              ), userId: userId, userName: userName, action: 'edit_balance', description: 'Edit saldo manual oleh admin');
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Simpan',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityDetailDialog(BuildContext context, FinanceBalanceLog log) {
    final isBalanceChange = log.note.contains('Edit saldo');
    final isTransaction = log.note.contains('transaksi');
    final isBudget = log.note.contains('anggaran');
    final isExport = log.note.contains('export');
    IconData icon;
    Color color;
    String title;
    
    if (isBalanceChange) {
      icon = Icons.account_balance_wallet;
      color = Colors.blue;
      title = 'Detail Perubahan Saldo';
    } else if (isTransaction) {
      icon = log.note.contains('Pemasukan') ? Icons.arrow_downward : Icons.arrow_upward;
      color = log.note.contains('Pemasukan') ? Colors.green : Colors.red;
      title = log.note.contains('Pemasukan') ? 'Detail Pemasukan' : 'Detail Pengeluaran';
    } else if (isBudget) {
      icon = Icons.account_balance;
      color = Colors.purple;
      title = 'Detail Anggaran';
    } else if (isExport) {
      icon = Icons.picture_as_pdf;
      color = Colors.orange;
      title = 'Detail Export';
    } else {
      icon = Icons.info;
      color = Colors.grey;
      title = 'Detail Aktivitas';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan waktu dan pelaku
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: color),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMMM yyyy HH:mm').format(log.date),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: color),
                        SizedBox(width: 8),
                        Text(
                          log.userName,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Detail aktivitas berdasarkan jenis
              if (isBalanceChange) ...[
                _buildDetailSection('Perubahan Saldo', [
                  _buildDetailRow('Saldo Sebelum', _formatRupiah(log.before)),
                  _buildDetailRow('Saldo Sesudah', _formatRupiah(log.after)),
                  _buildDetailRow(
                    'Selisih',
                    _formatRupiah(log.after - log.before),
                    valueColor: log.after >= log.before ? Colors.green : Colors.red,
                  ),
                ]),
              ] else if (isTransaction) ...[
                _buildDetailSection('Detail Transaksi', [
                  _buildDetailRow('Jenis', log.note.contains('Pemasukan') ? 'Pemasukan' : 'Pengeluaran'),
                  _buildDetailRow('Kategori', log.note.split('kategori ').last.split(' ').first),
                  _buildDetailRow('Nominal', _formatRupiah(log.after - log.before)),
                  _buildDetailRow('Deskripsi', log.note.split('dengan deskripsi ').last),
                ]),
              ] else if (isBudget) ...[
                _buildDetailSection('Detail Anggaran', [
                  _buildDetailRow('Kategori', log.note.split('kategori ').last.split(' ').first),
                  _buildDetailRow('Nominal', _formatRupiah(log.after)),
                  _buildDetailRow('Periode', log.note.contains('bulan') ? 
                    'Bulan ${DateFormat('MMMM yyyy').format(log.date)}' : 'Tahunan'),
                ]),
              ] else if (isExport) ...[
                _buildDetailSection('Detail Export', [
                  _buildDetailRow('Jenis', log.note.contains('PDF') ? 'PDF' : 'Excel'),
                  _buildDetailRow('Periode', log.note.contains('bulan') ? 
                    'Bulan ${DateFormat('MMMM yyyy').format(log.date)}' : 'Kustom'),
                  _buildDetailRow('Format', log.note.contains('PDF') ? 'PDF' : 'Excel'),
                ]),
              ] else ...[
                _buildDetailSection('Detail Aktivitas', [
                  _buildDetailRow('Deskripsi', log.note),
                ]),
              ],

              SizedBox(height: 16),
              _buildDetailSection('Catatan Sistem', [
                _buildDetailRow('ID Aktivitas', log.id),
                _buildDetailRow('Waktu Sistem', DateFormat('yyyy-MM-dd HH:mm:ss').format(log.date)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCleanupConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bersihkan Data Keuangan'),
        content: Text(
          'Anda yakin ingin membersihkan semua data keuangan? '
          'Ini akan menghapus semua transaksi dan mengatur ulang saldo ke 0.\n\n'
          'Tindakan ini tidak dapat dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userName = user.displayName?.isNotEmpty == true 
                  ? user.displayName! 
                  : user.email?.split('@')[0] ?? 'User';
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Membersihkan data...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  await FinanceService().cleanupFinanceData(
                    userId: user.uid,
                    userName: userName,
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Dismiss loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Data keuangan berhasil dibersihkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Dismiss loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal membersihkan data: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Ya, Bersihkan'),
          ),
        ],
      ),
    );
  }
}

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
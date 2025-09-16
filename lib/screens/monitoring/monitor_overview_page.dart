import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:waresys_fix1/providers/auth_provider.dart';
import 'package:waresys_fix1/providers/transaction_provider.dart';
import 'package:waresys_fix1/providers/inventory_provider.dart';
import 'package:waresys_fix1/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:waresys_fix1/services/finance_service.dart';
import 'package:waresys_fix1/models/finance_model.dart';
import 'package:waresys_fix1/services/transaction_service.dart';
import 'package:waresys_fix1/models/transaction_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:waresys_fix1/services/ai/ai_service.dart';
import 'package:waresys_fix1/models/ai_insight_model.dart';
import 'package:waresys_fix1/widgets/ai_insight_card.dart';

class MonitorOverviewPage extends StatefulWidget {
  const MonitorOverviewPage({super.key});

  @override
  State<MonitorOverviewPage> createState() => _MonitorOverviewPageState();
}

class _MonitorOverviewPageState extends State<MonitorOverviewPage> {
  final _financeService = FinanceService();
  final _trxService = TransactionService();
  DateTimeRange? _dateRange;
  final AIService _aiService = AIService();
  bool _showAIInsights = true;

  Stream<List<TransactionModel>> get _salesStream => _trxService
    .getTransactionsStream(
      type: TransactionType.sales,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    )
    .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());

  Stream<List<TransactionModel>> get _purchaseStream => _trxService
    .getTransactionsStream(
      type: TransactionType.purchase,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    )
    .map((list) => list.where((t) => t.paymentStatus == PaymentStatus.paid).toList());

  Stream<List<FinanceTransaction>> get _manualTransactionsStream => _financeService
    .getTransactionsStream(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    )
    .map((list) => list.where((t) => !t.id.startsWith('trx_')).toList());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    await Future.wait([
      transactionProvider.loadTransactions(),
      inventoryProvider.loadProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_dateRange != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
                    child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                        children: [
                    Icon(Icons.date_range, color: Colors.green),
                    const SizedBox(width: 12),
                              Expanded(
                      child: Text(
                        'Filter: ${DateFormat('d MMM y').format(_dateRange!.start)} - '
                        '${DateFormat('d MMM y').format(_dateRange!.end)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                                ),
                              ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                      onPressed: () => setState(() => _dateRange = null),
                              ),
                            ],
                          ),
                      ),
              ),
              const SizedBox(height: 16),
          // Financial Status
          StreamBuilder<FinanceBalance>(
            stream: _financeService.getBalanceStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorCard('Error loading financial data');
              }
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              
              final balance = snapshot.data!;
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Financial Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                        ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showKasUtamaDetails(context),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.account_balance, 
                                          color: Colors.blue[700], 
                                          size: 20
                          ),
                          const SizedBox(width: 8),
                                        Text(
                                          'Kas Utama',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyFormatter.format(balance.kasUtama),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showBankDetails(context),
                              child: Container(
                  padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                    Row(
                                      children: [
                                        Icon(Icons.credit_card, 
                                          color: Colors.purple[700],
                                          size: 20
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Bank',
                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyFormatter.format(balance.bank),
                                      style: TextStyle(
                                        fontSize: 20,
                          fontWeight: FontWeight.bold,
                                        color: Colors.purple[700],
                            ),
                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
              ),
              const SizedBox(height: 16),
          // Transaction Summary
          StreamBuilder<List<TransactionModel>>(
            stream: _salesStream,
            builder: (context, salesSnap) {
              return StreamBuilder<List<TransactionModel>>(
                stream: _purchaseStream,
                builder: (context, purchaseSnap) {
                  return StreamBuilder<List<FinanceTransaction>>(
                    stream: _manualTransactionsStream,
                    builder: (context, manualSnap) {
                      if (salesSnap.hasError || purchaseSnap.hasError || manualSnap.hasError) {
                        return _buildErrorCard('Error loading transaction data');
                      }
                      if (!salesSnap.hasData || !purchaseSnap.hasData || !manualSnap.hasData) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                      
                      final sales = salesSnap.data ?? [];
                      final purchases = purchaseSnap.data ?? [];
                      final manualTransactions = manualSnap.data ?? [];
                      
                      final totalSales = sales.fold<double>(0.0, (sum, t) => sum + t.total);
                      final totalPurchases = purchases.fold<double>(0.0, (sum, t) => sum + t.total);
                      
                      final totalManualIncome = manualTransactions
                        .where((t) => t.type == FinanceTransactionType.income)
                        .fold<double>(0.0, (sum, t) => sum + t.amount);
                      
                      final totalManualExpense = manualTransactions
                        .where((t) => t.type == FinanceTransactionType.expense)
                        .fold<double>(0.0, (sum, t) => sum + t.amount);

                      final totalIncome = totalManualIncome + totalSales;
                      final totalExpense = totalManualExpense + totalPurchases;
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                child: Padding(
                          padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                              Row(
                                children: [
                                  Icon(Icons.assessment, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Transaction Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                        ),
                                  ),
                                ],
                      ),
                      const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _showIncomeDetails(
                                    context,
                                    sales.where((t) => t.paymentStatus == PaymentStatus.paid).toList(),
                                    manualTransactions.where((t) => t.type == FinanceTransactionType.income).toList(),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                      Row(
                        children: [
                                          Icon(Icons.arrow_upward, 
                                            color: Colors.green[700],
                                            size: 20
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Total Income',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        CurrencyFormatter.format(totalIncome),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                      ),
                    ],
                  ),
                ),
              ),
                              const SizedBox(height: 12),
                              Container(
                  padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _showExpenseDetails(
                                    context,
                                    purchases.where((t) => t.paymentStatus == PaymentStatus.paid).toList(),
                                    manualTransactions.where((t) => t.type == FinanceTransactionType.expense).toList(),
                                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.arrow_downward, 
                                            color: Colors.red[700],
                                            size: 20
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Total Expense',
                        style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w500,
                        ),
                      ),
                                        ],
                      ),
                      const SizedBox(height: 8),
                                      Text(
                                        CurrencyFormatter.format(totalExpense),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                      ),
                    ],
                  ),
                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
              ),
              const SizedBox(height: 16),
          // Stock Status
          Consumer<InventoryProvider>(
            builder: (context, inventoryProvider, child) {
              if (inventoryProvider.products.isEmpty) {
                inventoryProvider.loadProducts();
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Stock Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showLowStockDetails(context, inventoryProvider.products),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.2),
                                    width: 1,
                                  ),
                              ),
                                child: Column(
                                  children: [
                                    Icon(Icons.warning,
                                      color: Colors.orange[700],
                                      size: 32
                      ),
                      const SizedBox(height: 8),
                                    Text(
                                      '${inventoryProvider.lowStockCount}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    Text(
                                      'Low Stock Items',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showOutOfStockDetails(context, inventoryProvider.products),
                              child: Container(
                  padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                  child: Column(
                    children: [
                                    Icon(Icons.error,
                                      color: Colors.red[700],
                                      size: 32
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${inventoryProvider.outOfStockCount}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    Text(
                                      'Out of Stock',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
              ),
              const SizedBox(height: 16),
          // AI Insights Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _showAIInsights,
                      onChanged: (value) {
                        setState(() {
                          _showAIInsights = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                if (_showAIInsights)
                  FutureBuilder<List<AIInsight>>(
                    future: _getAIInsights(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'AI Insights Unavailable',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'AI features are temporarily unavailable. Your system continues to work normally.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Analyzing Data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Generating insights from your business data...',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No insights available'),
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!
                            .map((insight) => AIInsightCard(
                                  insight: insight,
                                  onActionTap: () => _handleInsightAction(insight),
                                ))
                            .toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
                child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
                    children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncomeDetails(BuildContext context, List<TransactionModel> sales, List<FinanceTransaction> manualTransactions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Income Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sales Transactions
              const Text('Sales Income:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...sales.map((sale) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.customerSupplierName ?? 'Unknown Customer'),
                    Text(CurrencyFormatter.format(sale.total), 
                      style: const TextStyle(color: Colors.green)),
                    Text(DateFormat('dd MMM yyyy HH:mm').format(sale.createdAt)),
                  ],
                ),
              )),
              if (sales.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('No sales transactions'),
                ),
              
              const SizedBox(height: 16),
              
              // Manual Income Transactions
              const Text('Other Income:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
              ...manualTransactions.map((trx) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(trx.category),
                    Text(CurrencyFormatter.format(trx.amount),
                      style: const TextStyle(color: Colors.green)),
                    Text(DateFormat('dd MMM yyyy HH:mm').format(trx.date)),
                    if (trx.description.isNotEmpty)
                      Text(trx.description, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
              if (manualTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('No manual income transactions'),
                      ),
                    ],
                  ),
                ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, List<TransactionModel> purchases, List<FinanceTransaction> manualTransactions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
                    children: [
              // Purchase Transactions
              const Text('Purchase Expenses:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...purchases.map((purchase) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchase.customerSupplierName ?? 'Unknown Supplier'),
                    Text(CurrencyFormatter.format(purchase.total),
                      style: const TextStyle(color: Colors.red)),
                    Text(DateFormat('dd MMM yyyy HH:mm').format(purchase.createdAt)),
                  ],
                ),
              )),
              if (purchases.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('No purchase transactions'),
                              ),
              
              const SizedBox(height: 16),
              
              // Manual Expense Transactions
              const Text('Other Expenses:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
              ...manualTransactions.map((trx) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(trx.category),
                    Text(CurrencyFormatter.format(trx.amount),
                      style: const TextStyle(color: Colors.red)),
                    Text(DateFormat('dd MMM yyyy HH:mm').format(trx.date)),
                    if (trx.description.isNotEmpty)
                      Text(trx.description, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
              if (manualTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('No manual expense transactions'),
                      ),
                    ],
                  ),
                ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.08),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showTransactionListDialog(BuildContext context, List<TransactionModel> transactions, String type) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
      child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.8),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
                type == 'sale' ? 'Daftar Penjualan' : 'Daftar Pembelian',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: transactions.isEmpty
                    ? const Center(child: Text('Tidak ada data.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: transactions.length,
                        itemBuilder: (context, i) {
                          final t = transactions[i];
                          return ListTile(
                            title: Text(t.customerSupplierName),
                            subtitle: Text('Total: ${CurrencyFormatter.format(t.total)}'),
                            trailing: Text(DateFormat('dd/MM/yyyy').format(t.createdAt)),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Tutup'),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  void _showProductListDialog(BuildContext context, List<Map<String, dynamic>> products, {bool lowStock = false, bool outOfStock = false}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.8),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                outOfStock ? 'Produk Habis' : 'Stok Menipis',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Builder(
                  builder: (BuildContext listContext) {
                    final filtered = products.where((p) {
                      final stock = (p['stock'] ?? 0) as int;
                      final minStock = (p['minStock'] ?? 5) as int;
                      if (outOfStock) return stock == 0;
                      if (lowStock) return stock > 0 && stock <= minStock;
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              outOfStock ? Icons.inventory_2 : Icons.check_circle,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              outOfStock
                                  ? 'Tidak ada produk yang stoknya habis'
                                  : 'Tidak ada produk dengan stok menipis',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                        final p = filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              p['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stok: ${p['stock'] ?? 0}'),
                                Text('Kategori: ${p['category'] ?? '-'}'),
                                Text('Min Stok: ${p['minStock'] ?? 5}'),
                              ],
                            ),
                            leading: CircleAvatar(
                              backgroundColor: outOfStock ? Colors.red[100] : Colors.orange[100],
                              child: Icon(
                                outOfStock ? Icons.error : Icons.warning,
                                color: outOfStock ? Colors.red : Colors.orange,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
                ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  void _showManualTransactionListDialog(BuildContext context, List<FinanceTransaction> transactions, String type) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.8),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'income' ? 'Daftar Pemasukan Lainnya' : 'Daftar Pengeluaran Lainnya',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: transactions.isEmpty
                    ? const Center(child: Text('Tidak ada data.'))
              : ListView.builder(
                  shrinkWrap: true,
                        itemCount: transactions.length,
                  itemBuilder: (context, i) {
                          final t = transactions[i];
                    return ListTile(
                            title: Text(t.category),
                            subtitle: Text(t.description),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(CurrencyFormatter.format(t.amount)),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(t.date),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    );
                  },
                ),
        ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
              ),
        ],
          ),
        ),
      ),
    );
  }

  void _showKasUtamaDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Detail Kas Utama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Balance
                      StreamBuilder<FinanceBalance>(
                        stream: _financeService.getBalanceStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorCard('Error loading balance data');
                          }
                          
                          final balance = snapshot.data;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo Saat Ini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  balance != null 
                                    ? CurrencyFormatter.format(balance.kasUtama)
                                    : 'Loading...',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Recent Transactions
                      Text(
                        'Transaksi Terakhir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<FinanceTransaction>>(
                        stream: _financeService.getTransactionsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorCard('Error loading transaction data');
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final transactions = snapshot.data!;
                          if (transactions.isEmpty) {
                            return Center(
                              child: Text(
                                'Belum ada transaksi',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length > 5 ? 5 : transactions.length,
                            itemBuilder: (context, index) {
                              final trx = transactions[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  trx.type == FinanceTransactionType.income
                                    ? Icons.arrow_circle_up
                                    : Icons.arrow_circle_down,
                                  color: trx.type == FinanceTransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                                ),
                                title: Text(trx.category),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(trx.date),
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${trx.type == FinanceTransactionType.income ? "+" : "-"} ${CurrencyFormatter.format(trx.amount)}',
                                  style: TextStyle(
                                    color: trx.type == FinanceTransactionType.income
                                      ? Colors.green
                                      : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Balance Log History
                      Text(
                        'Riwayat Perubahan Saldo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<FinanceBalanceLog>>(
                        stream: _financeService.getBalanceLogsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorCard('Error loading balance log data');
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final logs = snapshot.data!;
                          if (logs.isEmpty) {
                            return Center(
                              child: Text(
                                'Belum ada riwayat perubahan saldo',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: logs.length > 5 ? 5 : logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              final difference = log.after - log.before;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(log.note),
                                subtitle: Text(
                                  '${DateFormat('dd/MM/yyyy HH:mm').format(log.date)} oleh ${log.userName}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${difference >= 0 ? "+" : ""} ${CurrencyFormatter.format(difference)}',
                                      style: TextStyle(
                                        color: difference >= 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(log.after),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Bank Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<FinanceTransaction>>(
                stream: _financeService.getTransactionsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final transactions = snapshot.data!
                      .where((t) => t.category == 'Bank Transfer')  // Only show bank transfers
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return Column(
                    children: [
                      for (var trx in transactions.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                trx.type == FinanceTransactionType.income
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: trx.type == FinanceTransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trx.description,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy HH:mm').format(trx.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(trx.amount),
                                style: TextStyle(
                                  color: trx.type == FinanceTransactionType.income
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLowStockDetails(BuildContext context, List<Map<String, dynamic>> products) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Low Stock Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: products
                        .where((p) {
                          final stock = (p['stock'] ?? 0) as int;
                          final minStock = (p['minStock'] ?? 5) as int;
                          return stock > 0 && stock <= minStock;
                        })
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: Colors.orange[700],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Category: ${p['category'] ?? '-'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock: ${p['stock']}',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Min: ${p['minStock'] ?? 5}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutOfStockDetails(BuildContext context, List<Map<String, dynamic>> products) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Out of Stock Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: products
                        .where((p) => (p['stock'] ?? 0) == 0)
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Category: ${p['category'] ?? '-'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock: 0',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Min: ${p['minStock'] ?? 5}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<AIInsight>> _getAIInsights() async {
    try {
      // Collect insights from different aspects
      final stockPrediction = await _aiService.predictStockLevels('all');
      final financialHealth = await _aiService.analyzeFinancialHealth();
      final salesPrediction = await _aiService.predictSales();
      final alerts = await _aiService.generateSmartAlerts();
      
      // Convert raw data to AIInsight objects
      List<AIInsight> insights = [];
      
      // Add stock predictions
      if (stockPrediction.isNotEmpty) {
        insights.add(AIInsight(
          id: DateTime.now().toString(),
          type: InsightType.stockPrediction,
          title: 'Stock Level Prediction',
          description: stockPrediction['description'] ?? '',
          data: stockPrediction,
          timestamp: DateTime.now(),
          priority: InsightPriority.medium,
          recommendedActions: List<String>.from(stockPrediction['actions'] ?? []),
          confidence: stockPrediction['confidence']?.toDouble(),
        ));
      }

      // Add financial insights
      if (financialHealth.isNotEmpty) {
        insights.add(AIInsight(
          id: DateTime.now().toString(),
          type: InsightType.financialHealth,
          title: 'Financial Health Analysis',
          description: financialHealth['description'] ?? '',
          data: financialHealth,
          timestamp: DateTime.now(),
          priority: InsightPriority.high,
          recommendedActions: List<String>.from(financialHealth['actions'] ?? []),
          confidence: financialHealth['confidence']?.toDouble(),
        ));
      }

      // Add sales predictions
      if (salesPrediction.isNotEmpty) {
        insights.add(AIInsight(
          id: DateTime.now().toString(),
          type: InsightType.salesForecast,
          title: 'Sales Forecast',
          description: salesPrediction['description'] ?? '',
          data: salesPrediction,
          timestamp: DateTime.now(),
          priority: InsightPriority.medium,
          recommendedActions: List<String>.from(salesPrediction['actions'] ?? []),
          confidence: salesPrediction['confidence']?.toDouble(),
        ));
      }

      // Add alerts
      for (final alert in alerts) {
        insights.add(AIInsight(
          id: DateTime.now().toString(),
          type: InsightType.smartAlert,
          title: alert['title'] ?? 'Smart Alert',
          description: alert['description'] ?? '',
          data: alert,
          timestamp: DateTime.now(),
          priority: _getPriorityFromAlert(alert['priority']),
          recommendedActions: List<String>.from(alert['actions'] ?? []),
          confidence: alert['confidence']?.toDouble(),
        ));
      }

      return insights;
    } catch (e) {
      debugPrint('Error getting AI insights: $e');
      return [];
    }
  }

  InsightPriority _getPriorityFromAlert(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return InsightPriority.critical;
      case 'high':
        return InsightPriority.high;
      case 'medium':
        return InsightPriority.medium;
      case 'low':
        return InsightPriority.low;
      default:
        return InsightPriority.medium;
    }
  }

  void _handleInsightAction(AIInsight insight) {
    // Handle insight action based on type
    switch (insight.type) {
      case InsightType.stockPrediction:
        // Navigate to inventory
        break;
      case InsightType.financialHealth:
        // Navigate to finance
        break;
      case InsightType.salesForecast:
        // Show sales details
        break;
      case InsightType.smartAlert:
        // Handle alert action
        break;
      default:
        // Default action
        break;
    }
  }
}
 
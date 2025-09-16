import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_model.dart';
import '../../services/finance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceBudgetsPage extends StatefulWidget {
  @override
  State<FinanceBudgetsPage> createState() => _FinanceBudgetsPageState();
}

class _FinanceBudgetsPageState extends State<FinanceBudgetsPage> {
  final _service = FinanceService();
  late int _month;
  late int _year;

  @override
  void initState() {
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinanceBudget>>(
      stream: _service.getBudgetsStream(month: _month, year: _year),
      builder: (context, snap) {
        final budgets = snap.data ?? [];
        return StreamBuilder<List<FinanceTransaction>>(
          stream: _service.getTransactionsStream(),
          builder: (context, trxSnap) {
            final trxs = (trxSnap.data ?? []).where((t) => t.date.month == _month && t.date.year == _year).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Anggaran Bulan Ini', style: Theme.of(context).textTheme.titleMedium),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Tambah'),
                      onPressed: () => _showBudgetDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...budgets.map((b) {
                  final realisasi = trxs.where((t) => t.category == b.category && t.type == FinanceTransactionType.expense).fold(0.0, (a, t) => a + t.amount);
                  final percent = b.amount == 0 ? 0.0 : (realisasi / b.amount).clamp(0.0, 1.0);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(b.category),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Anggaran: ${_formatRupiah(b.amount)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            color: percent >= 1.0 ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Realisasi: ${_formatRupiah(realisasi)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showBudgetDialog(context, budget: b),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteBudget(b.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (budgets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(child: Text('Belum ada anggaran bulan ini', style: TextStyle(color: Colors.grey))),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatRupiah(double n) {
    final f = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return f.format(n);
  }

  void _showBudgetDialog(BuildContext context, {FinanceBudget? budget}) async {
    final user = FirebaseAuth.instance.currentUser;
    final formKey = GlobalKey<FormState>();
    String _category = budget?.category ?? '';
    double _amount = budget?.amount ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget == null ? 'Tambah Anggaran' : 'Edit Anggaran'),
        content: Form(
          key: formKey,
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
                initialValue: _amount > 0 ? _amount.toStringAsFixed(0) : '',
                decoration: InputDecoration(labelText: 'Nominal Anggaran'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _amount = double.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Nominal harus > 0' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final b = FinanceBudget(
                id: budget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                category: _category,
                amount: _amount,
                month: _month,
                year: _year,
                createdBy: user?.uid ?? '',
              );
              final userId = user?.uid ?? '';
              final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
              if (budget == null) {
                await _service.addBudget(b, userId: userId, userName: userName);
              } else {
                await _service.updateBudget(b, userId: userId, userName: userName);
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
    await _service.deleteBudget(id, userId: userId, userName: userName);
  }
}
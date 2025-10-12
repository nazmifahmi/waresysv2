import 'package:flutter/material.dart';
import '../../models/crm/sales_model.dart';
import '../../services/crm/sales_repository.dart';
import 'sales_form_page.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final SalesRepository _repository = SalesRepository();
  DateTime? _startDate;
  DateTime? _endDate;

  void _openForm({SalesModel? sales}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalesFormPage(existing: sales)),
    );
    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari produk atau customer...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearDateFilter,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SalesModel>>(
              future: _repository.getAll(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
              builder: (context, snapshot) {
                final allData = snapshot.data ?? [];
                
                // Apply date filter
                final data = _startDate != null && _endDate != null
                    ? allData.where((sale) {
                        return sale.saleDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                               sale.saleDate.isBefore(_endDate!.add(const Duration(days: 1)));
                      }).toList()
                    : allData;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada data penjualan.'));
                }

                // Calculate total sales
                final totalSales = data.fold<double>(0, (sum, sale) => sum + sale.amount);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Penjualan: Rp ${totalSales.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, i) {
                          final sale = data[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(sale.productName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customer: ${sale.customerId}'),
                                  Text('Qty: ${sale.quantity} • Amount: Rp ${sale.amount.toStringAsFixed(0)}'),
                                  Text('Date: ${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: const Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Text('Hapus'),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _openForm(sales: sale);
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Konfirmasi'),
                                        content: const Text('Hapus data penjualan ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _repository.delete(sale.saleId);
                                      setState(() {});
                                    }
                                  }
                                },
                              ),
                              onTap: () => _openForm(sales: sale),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
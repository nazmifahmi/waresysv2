import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/product_model.dart';
import '../../services/transaction_service.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/finance_service.dart';

class TransactionFormPage extends StatefulWidget {
  final TransactionType type;
  const TransactionFormPage({super.key, required this.type});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _customerSupplierName;
  DateTime _date = DateTime.now();
  List<TransactionItem> _items = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _notes;
  bool _isLoading = false;
  List<Product> _products = [];
  bool _loadingProducts = true;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  DeliveryStatus _deliveryStatus = DeliveryStatus.pending;
  double? _currentKasUtama;

  double get _total => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadKasUtama();
  }

  Future<void> _loadKasUtama() async {
    final balance = await FinanceService().getBalance();
    setState(() {
      _currentKasUtama = balance.kasUtama;
    });
  }

  Future<void> _loadProducts() async {
    final products = await FirestoreService().getProducts();
    setState(() {
      _products = products;
      _loadingProducts = false;
    });
  }

  void _addItem() async {
    if (_loadingProducts) return;
    Product? selectedProduct;
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Produk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                value: null,
                items: _products
                    .where((p) => !_items.any((item) => item.productId == p.id))
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (Stok: ${p.stock})'),
                        ))
                    .toList(),
                onChanged: (val) {
                  setDialogState(() {
                    selectedProduct = val;
                    priceController.text = val?.price.toStringAsFixed(2) ?? '';
                  });
                },
                decoration: const InputDecoration(labelText: 'Pilih Produk'),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (qty <= 0 || price <= 0) return;
                // Validasi stok jika sales
                if (widget.type == TransactionType.sales && qty > selectedProduct!.stock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stok produk tidak cukup! (Stok: ${selectedProduct!.stock})')),
                  );
                  return;
                }
                setState(() {
                  _items.add(TransactionItem(
                    productId: selectedProduct!.id,
                    productName: selectedProduct!.name,
                    quantity: qty,
                    price: price,
                    subtotal: qty * price,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  // Validate if kas utama is sufficient for purchase transaction
  bool _validateKasUtama() {
    if (widget.type == TransactionType.purchase && 
        _paymentStatus == PaymentStatus.paid && 
        _currentKasUtama != null) {
      return _currentKasUtama! >= _total;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == TransactionType.sales ? 'Transaksi Penjualan' : 'Transaksi Pembelian'),
      ),
      body: _loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: widget.type == TransactionType.sales ? 'Customer' : 'Supplier',
                      ),
                      onChanged: (val) => _customerSupplierName = val,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Produk'),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Produk'),
                          onPressed: _addItem,
                        ),
                      ],
                    ),
                    ..._items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text('Qty: \\${item.quantity} x \\${item.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Subtotal: \\${item.subtotal.toStringAsFixed(2)}'),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Hapus produk',
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Belum ada produk', style: TextStyle(color: Colors.grey)),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethod>(
                      value: _paymentMethod,
                      items: PaymentMethod.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val ?? PaymentMethod.cash),
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentStatus>(
                      value: _paymentStatus,
                      items: PaymentStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _paymentStatus = val ?? PaymentStatus.unpaid);
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
                    if (widget.type == TransactionType.purchase && _currentKasUtama != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Saldo Kas Utama: ${_currentKasUtama!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _validateKasUtama() ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      onChanged: (val) => setState(() => _deliveryStatus = val ?? DeliveryStatus.pending),
                      decoration: const InputDecoration(labelText: 'Status Pengiriman'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                      onChanged: (val) => _notes = val,
                    ),
                    const SizedBox(height: 20),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        'Total: \${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading || !_validateKasUtama()
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate() || _items.isEmpty) return;
                              setState(() => _isLoading = true);
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                final trx = TransactionModel(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  type: widget.type,
                                  customerSupplierName: _customerSupplierName ?? '',
                                  items: _items,
                                  total: _total,
                                  paymentMethod: _paymentMethod,
                                  paymentStatus: _paymentStatus,
                                  deliveryStatus: _deliveryStatus,
                                  trackingNumber: null,
                                  notes: _notes,
                                  isDeleted: false,
                                  logHistory: [
                                    TransactionLog(
                                      action: 'create',
                                      userId: user?.uid ?? '',
                                      userName: user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User',
                                      timestamp: DateTime.now(),
                                      note: 'Transaksi dibuat',
                                    ),
                                  ],
                                  createdBy: user?.uid ?? '',
                                  createdAt: _date,
                                  updatedAt: DateTime.now(),
                                );

                                await TransactionService().addTransaction(
                                  trx,
                                  userId: user?.uid ?? '',
                                  userName: user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User',
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Transaksi berhasil disimpan')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan Transaksi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
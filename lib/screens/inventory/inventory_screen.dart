import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/profile_screen.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/floating_chat_bubble.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    InventoryProductPage(),
    InventoryStockMutationPage(),
    InventoryStockHistoryPage(),
    InventoryExportPage(),
    // Profile handled in _onItemTapped
  ];

  static const List<String> _titles = <String>[
    'Produk',
    'Mutasi Stok',
    'Riwayat Stok',
    'Export',
  ];

  static final List<Color> _colors = <Color>[
    AppTheme.accentOrange,  // Produk
    AppTheme.accentBlue,    // Mutasi Stok
    AppTheme.accentPurple,  // Riwayat Stok
    AppTheme.accentGreen,   // Export
    AppTheme.accentOrange,  // Profile
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            moduleName: 'Inventory',
            moduleColor: _colors[4],
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: _colors[_selectedIndex],
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundDark,
                  AppTheme.surfaceDark,
                ],
              ),
            ),
            child: _pages[_selectedIndex],
          ),
          const FloatingChatBubble(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderDark,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: _colors[_selectedIndex],
          unselectedItemColor: AppTheme.textTertiary,
          selectedLabelStyle: AppTheme.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTheme.labelSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: 'Mutasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_download_outlined),
              activeIcon: Icon(Icons.file_download),
              label: 'Export',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Produk Page -------------------
class InventoryProductPage extends StatefulWidget {
  @override
  State<InventoryProductPage> createState() => _InventoryProductPageState();
}

class _InventoryProductPageState extends State<InventoryProductPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _search = '';
  String _filterCategory = '';
  List<String> _categories = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;
  String get _userId => _currentUser?.uid ?? '';
  String get _userName => _currentUser?.displayName ?? _currentUser?.email?.split('@')[0] ?? 'User';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final products = await _firestoreService.getProducts();
    setState(() {
      _categories = products.map((p) => p.category).toSet().toList();
    });
  }

  void _showAddEditProductDialog([Product? product]) {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        product: product,
        onSaved: () {
          setState(() {});
          _loadCategories();
          context.read<InventoryProvider>().loadProducts();
        },
        categories: _categories,
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Detail Produk',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.accentOrange,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Nama', product.name),
            _detailRow('SKU', product.sku ?? '-'),
            _detailRow('Kategori', product.category),
            _detailRow('Stok', product.stock.toString()),
            _detailRow('Harga', product.price.toString()),
            _detailRow('Deskripsi', product.description),
            _detailRow('Dibuat', product.createdAt.toString()),
            _detailRow('Diupdate', product.updatedAt.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: AppTheme.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: (label == 'Harga' && value != null)
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatRupiah(double.tryParse(value) ?? 0),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  value ?? '-',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
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

  @override
  Widget build(BuildContext context) {
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
                child: CommonWidgets.buildTextField(
                   label: 'Pencarian',
                   hint: 'Cari produk...',
                   prefixIcon: Icons.search,
                   onChanged: (val) => setState(() => _search = val),
                 ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Container(
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
                  child: DropdownButton<String>(
                    value: _filterCategory.isEmpty ? null : _filterCategory,
                    hint: Text(
                      'Kategori',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    dropdownColor: AppTheme.surfaceDark,
                    style: AppTheme.bodyMedium,
                    items: ['']
                        .followedBy(_categories)
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat.isEmpty ? 'Semua' : cat,
                                style: AppTheme.bodyMedium,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _filterCategory = val ?? ''),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              CommonWidgets.buildPrimaryButton(
                text: 'Tambah',
                icon: Icons.add,
                onPressed: () => _showAddEditProductDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _firestoreService.getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = snapshot.data!
                  .where((p) => (_search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase())) &&
                      (_filterCategory.isEmpty || p.category == _filterCategory))
                  .toList();
              if (products.isEmpty) {
                return const Center(child: Text('Tidak ada produk'));
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStockStatusColor(p.stock),
                        child: Text(p.stock.toString()),
                      ),
                      title: Text(p.name),
                      subtitle: Text('SKU: ${p.sku ?? '-'} | Kategori: ${p.category}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditProductDialog(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await context.read<InventoryProvider>().deleteProduct(p.id, userId: _userId, userName: _userName);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      onTap: () => _showProductDetails(context, p),
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

  Color _getStockStatusColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }
}

class AddEditProductDialog extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;
  final List<String> categories;
  const AddEditProductDialog({this.product, required this.onSaved, required this.categories});
  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;
  late TextEditingController _skuController;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAddingNewCategory = false;
  late TextEditingController _newCategoryController;

  User? get _currentUser => _auth.currentUser;
  String get _userId => _currentUser?.uid ?? '';
  String get _userName => _currentUser?.displayName ?? _currentUser?.email?.split('@')[0] ?? 'User';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _newCategoryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
                readOnly: true,
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Pilih Kategori'),
                      children: [
                        ...widget.categories.map((cat) => SimpleDialogOption(
                              child: Text(cat),
                              onPressed: () => Navigator.pop(context, cat),
                            )),
                        const Divider(),
                        SimpleDialogOption(
                          child: const Text('+ Tambah Kategori Baru', style: TextStyle(color: Colors.teal)),
                          onPressed: () => Navigator.pop(context, '+new'),
                        ),
                      ],
                    ),
                  );
                  if (selected == '+new') {
                    setState(() {
                      _isAddingNewCategory = true;
                      _categoryController.clear();
                    });
                  } else if (selected != null) {
                    setState(() {
                      _isAddingNewCategory = false;
                      _categoryController.text = selected;
                    });
                  }
                },
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              if (_isAddingNewCategory)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(labelText: 'Kategori Baru'),
                    validator: (v) => v == null || v.isEmpty ? 'Kategori wajib diisi' : null,
                    onChanged: (val) {
                      _categoryController.text = val;
                    },
                  ),
                ),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU (Opsional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);
                  final provider = context.read<InventoryProvider>();
                  final productMap = {
                    'name': _nameController.text,
                    'description': _descController.text,
                    'price': double.tryParse(_priceController.text) ?? 0.0,
                    'stock': int.tryParse(_stockController.text) ?? 0,
                    'category': _categoryController.text,
                    'sku': _skuController.text.isEmpty ? null : _skuController.text,
                  };
                  if (widget.product == null) {
                    await provider.addProduct(productMap, userId: _userId, userName: _userName);
                  } else {
                    await provider.updateProduct(widget.product!.id, productMap, userId: _userId, userName: _userName);
                  }
                  setState(() => _isLoading = false);
                  widget.onSaved();
                  Navigator.pop(context);
                },
          child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ------------------- Mutasi Stok Page -------------------
class InventoryStockMutationPage extends StatefulWidget {
  @override
  State<InventoryStockMutationPage> createState() => _InventoryStockMutationPageState();
}

class _InventoryStockMutationPageState extends State<InventoryStockMutationPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedProductId;
  String _mutationType = 'in';
  final _qtyController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;
  String get _userId => _currentUser?.uid ?? '';
  String get _userName => _currentUser?.displayName ?? _currentUser?.email?.split('@')[0] ?? 'User';

  @override
  void dispose() {
    _qtyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mutasi Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          StreamBuilder<List<Product>>(
            stream: _firestoreService.getProductsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final products = snapshot.data!;
              return DropdownButtonFormField<String>(
                value: _selectedProductId,
                items: products
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProductId = val),
                decoration: const InputDecoration(labelText: 'Pilih Produk'),
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mutationType,
            items: const [
              DropdownMenuItem(value: 'in', child: Text('Stok Masuk')),
              DropdownMenuItem(value: 'out', child: Text('Stok Keluar')),
            ],
            onChanged: (val) => setState(() => _mutationType = val ?? 'in'),
            decoration: const InputDecoration(labelText: 'Tipe Mutasi'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Jumlah'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Keterangan'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_selectedProductId == null || _qtyController.text.isEmpty) return;
                    setState(() => _isLoading = true);
                    final qty = int.tryParse(_qtyController.text) ?? 0;
                    final isIn = _mutationType == 'in';
                    // Update stok produk
                    final product = await _firestoreService.getProduct(_selectedProductId!);
                    if (product != null) {
                      final before = product.stock;
                      final newStock = isIn ? product.stock + qty : product.stock - qty;
                      // Validasi stok keluar tidak boleh melebihi stok
                      if (!isIn && qty > product.stock) {
                        setState(() => _isLoading = false);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Stok Tidak Cukup'),
                            content: const Text('Jumlah stok keluar melebihi stok yang tersedia!'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                          ),
                        );
                        return;
                      }
                      final updatedProduct = product.copyWith(
                        stock: newStock,
                        updatedAt: DateTime.now(),
                      );
                      await context.read<InventoryProvider>().updateStock(product.id, isIn ? qty : -qty, userId: _userId, userName: _userName);
                      // Simpan ke stock_logs
                      await _firestoreService.addStockLog({
                        'productId': product.id,
                        'productName': product.name,
                        'category': product.category,
                        'type': isIn ? 'in' : 'out',
                        'qty': qty,
                        'before': before,
                        'after': newStock,
                        'userId': _userId,
                        'userName': _userName,
                        'desc': _descController.text,
                        'timestamp': DateTime.now(),
                      });
                    }
                    setState(() => _isLoading = false);
                    _qtyController.clear();
                    _descController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mutasi stok berhasil')),
                    );
                  },
            child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Mutasi'),
          ),
        ],
      ),
    );
  }
}

// ------------------- Riwayat Stok Page -------------------
class InventoryStockHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getStockLogsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return const Center(child: Text('Belum ada riwayat mutasi stok'));
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, i) {
            final log = logs[i];
            final dt = log['timestamp'] is DateTime
                ? log['timestamp']
                : (log['timestamp'] as Timestamp).toDate();
            final dateStr = '${dt.day}/${dt.month}/${dt.year}';
            final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Icon(log['type'] == 'in' ? Icons.arrow_downward : Icons.arrow_upward, color: log['type'] == 'in' ? Colors.green : Colors.red),
                title: Text('${log['productName']} (${log['category']})'),
                subtitle: Text('Jumlah: ${log['qty']} | Sebelum: ${log['before']} | Sesudah: ${log['after']}\nOleh: ${log['userName']}\n${log['desc'] ?? ''}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dateStr),
                    Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                onTap: () => _showLogDetails(context, log),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogDetails(BuildContext context, Map<String, dynamic> log) {
    final dt = log['timestamp'] is DateTime
        ? log['timestamp']
        : (log['timestamp'] as Timestamp).toDate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Riwayat Mutasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Produk', log['productName']),
            _detailRow('Kategori', log['category']),
            _detailRow('Tipe', log['type'] == 'in' ? 'Masuk' : 'Keluar'),
            _detailRow('Jumlah', log['qty'].toString()),
            _detailRow('Sebelum', log['before'].toString()),
            _detailRow('Sesudah', log['after'].toString()),
            _detailRow('User', log['userName']),
            _detailRow('Tanggal', '${dt.day}/${dt.month}/${dt.year}'),
            _detailRow('Jam', '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
            if ((log['desc'] ?? '').toString().isNotEmpty)
              _detailRow('Keterangan', log['desc']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(
            (label == 'Harga' && value != null)
              ? _formatRupiah(double.tryParse(value) ?? 0)
              : (value ?? '-')
          )),
        ],
      ),
    );
  }

  String _formatRupiah(double n) {
    final f = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return f.format(n);
  }
}

// ------------------- Export Page -------------------
class InventoryExportPage extends StatelessWidget {
  Future<void> _exportProductList(BuildContext context) async {
    final service = FirestoreService();
    final products = await service.getProducts();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Daftar Produk', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Nama', 'SKU', 'Kategori', 'Stok', 'Harga', 'Status'],
              data: products.map((p) => [
                p.name,
                p.sku ?? '-',
                p.category,
                p.stock.toString(),
                p.price.toString(),
                p.stock <= 0 ? 'Habis' : (p.stock < 10 ? 'Kritis' : 'Aman'),
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/daftar_produk.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
    await service.logActivity(
      userId: userId,
      userName: userName,
      type: 'inventory',
      action: 'export_pdf',
      description: 'Export daftar produk PDF',
      details: {'file': file.path},
    );
  }

  Future<void> _exportStockHistory(BuildContext context) async {
    final service = FirestoreService();
    final logs = await service.getStockLogsStream().first;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Riwayat Mutasi Stok', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'Produk', 'Kategori', 'Tipe', 'Qty', 'Sebelum', 'Sesudah', 'User', 'Keterangan'],
              data: logs.map((log) => [
                (log['timestamp'] is DateTime ? log['timestamp'] : (log['timestamp'] as Timestamp).toDate()).toString().split(' ')[0],
                log['productName'],
                log['category'],
                log['type'] == 'in' ? 'Masuk' : 'Keluar',
                log['qty'].toString(),
                log['before'].toString(),
                log['after'].toString(),
                log['userName'],
                log['desc'] ?? '',
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/riwayat_stok.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email?.split('@')[0] ?? 'User';
    await service.logActivity(
      userId: userId,
      userName: userName,
      type: 'inventory',
      action: 'export_pdf',
      description: 'Export riwayat mutasi stok PDF',
      details: {'file': file.path},
    );
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
              label: const Text('Export Daftar Produk (PDF)'),
              onPressed: () => _exportProductList(context),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export Riwayat Mutasi Stok (PDF)'),
              onPressed: () => _exportStockHistory(context),
            ),
          ],
        ),
      ),
    );
  }
}
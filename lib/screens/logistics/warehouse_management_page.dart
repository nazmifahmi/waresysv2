import 'package:flutter/material.dart';
import '../../models/logistics/warehouse_location_model.dart';
import '../../services/logistics/warehouse_repository.dart';
import 'warehouse_form_page.dart';

class WarehouseManagementPage extends StatefulWidget {
  const WarehouseManagementPage({super.key});

  @override
  State<WarehouseManagementPage> createState() => _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  final WarehouseRepository _repository = WarehouseRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _openForm([WarehouseModel? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarehouseFormPage(existing: existing),
      ),
    );
  }

  Future<void> _deleteWarehouse(WarehouseModel warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus gudang "${warehouse.name}"?'),
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

    if (confirmed == true) {
      try {
        await _repository.delete(warehouse.warehouseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gudang berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateStock(WarehouseModel warehouse, int delta) async {
    try {
      await _repository.updateStock(
        warehouseId: warehouse.warehouseId,
        deltaStock: delta,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok berhasil ${delta > 0 ? 'ditambah' : 'dikurangi'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getCapacityColor(WarehouseModel warehouse) {
    final ratio = warehouse.stockCount / warehouse.capacity;
    if (ratio >= 0.8) return Colors.red;
    if (ratio >= 0.6) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Gudang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari gudang...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WarehouseModel>>(
              stream: _repository.watchAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final warehouses = snapshot.data ?? [];
                final filteredWarehouses = warehouses.where((warehouse) {
                  return warehouse.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         warehouse.location.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredWarehouses.isEmpty) {
                  return const Center(child: Text('Tidak ada data gudang'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredWarehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = filteredWarehouses[index];
                    final capacityRatio = warehouse.stockCount / warehouse.capacity;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          warehouse.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lokasi: ${warehouse.location}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Stok: ${warehouse.stockCount}/${warehouse.capacity}'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: capacityRatio,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getCapacityColor(warehouse),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(capacityRatio * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _openForm(warehouse);
                                break;
                              case 'delete':
                                _deleteWarehouse(warehouse);
                                break;
                              case 'add_stock':
                                _updateStock(warehouse, 10);
                                break;
                              case 'remove_stock':
                                _updateStock(warehouse, -10);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_stock',
                              child: ListTile(
                                leading: Icon(Icons.add_circle, color: Colors.green),
                                title: Text('Tambah Stok (+10)'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove_stock',
                              child: ListTile(
                                leading: Icon(Icons.remove_circle, color: Colors.orange),
                                title: Text('Kurangi Stok (-10)'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Hapus'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
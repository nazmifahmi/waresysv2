import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/logistics/warehouse_location_model.dart';
import '../../services/logistics/warehouse_repository.dart';
import 'warehouse_form_page.dart';
import '../../services/logistics/bin_repository.dart';
import 'bin_management_page.dart';

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
    final confirmed = await CommonWidgets.showConfirmDialog(
      context: context,
      title: 'Konfirmasi Hapus',
      content: 'Apakah Anda yakin ingin menghapus gudang "${warehouse.name}"?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _repository.delete(warehouse.warehouseId);
        if (mounted) {
          CommonWidgets.showSnackBar(
            context: context,
            message: 'Gudang berhasil dihapus',
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          CommonWidgets.showSnackBar(
            context: context,
            message: 'Error: $e',
            type: SnackBarType.error,
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
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Stok berhasil ${delta > 0 ? 'ditambah' : 'dikurangi'}',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Error: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Color _getCapacityColor(WarehouseModel warehouse) {
    final ratio = warehouse.capacity == 0 ? 0.0 : warehouse.stockCount / warehouse.capacity;
    if (ratio >= 0.8) return AppTheme.errorColor;
    if (ratio >= 0.6) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: 'Manajemen Gudang',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: CommonWidgets.buildTextField(
              label: 'Cari gudang',
              hint: 'Nama atau lokasi gudang...',
              controller: _searchController,
              prefixIcon: Icons.search,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
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
                  return CommonWidgets.buildLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return CommonWidgets.buildErrorState(
                    title: 'Terjadi kesalahan',
                    subtitle: '${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                final warehouses = snapshot.data ?? [];
                final filteredWarehouses = warehouses.where((warehouse) {
                  return warehouse.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         warehouse.location.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredWarehouses.isEmpty) {
                  return CommonWidgets.buildEmptyState(
                    title: 'Tidak ada data gudang',
                    subtitle: 'Tambahkan gudang baru untuk mulai mengelola stok',
                    icon: Icons.warehouse,
                    action: CommonWidgets.buildPrimaryButton(
                      text: 'Tambah Gudang',
                      icon: Icons.add,
                      onPressed: () => _openForm(),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  itemCount: filteredWarehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = filteredWarehouses[index];
                    final capacityRatio = warehouse.capacity == 0
                        ? 0.0
                        : warehouse.stockCount / warehouse.capacity;

                    return CommonWidgets.buildCard(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          warehouse.name,
                          style: AppTheme.heading4,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lokasi: ${warehouse.location}', style: AppTheme.bodyMedium),
                              const SizedBox(height: AppTheme.spacingS),
                              Row(
                                children: [
                                  Text('Stok: ${warehouse.stockCount}/${warehouse.capacity}',
                                      style: AppTheme.bodySmall),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: capacityRatio,
                                      backgroundColor: AppTheme.borderDark,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCapacityColor(warehouse),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Text('${(capacityRatio * 100).toStringAsFixed(1)}%',
                                      style: AppTheme.labelMedium),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingS),
                              FutureBuilder<Map<String, dynamic>>(
                                future: BinRepository().computeWarehouseOccupancy(warehouse.warehouseId),
                                builder: (context, occSnap) {
                                  if (occSnap.connectionState == ConnectionState.waiting) {
                                    return const LinearProgressIndicator();
                                  }
                                  if (!occSnap.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final occ = occSnap.data!;
                                  final percent = (occ['percent'] ?? 0.0) as double;
                                  final usedM3 = (occ['totalUsedM3'] ?? 0.0) as double;
                                  final totalM3 = (occ['totalCapacityM3'] ?? 0.0) as double;
                                  final color = percent >= 0.8
                                      ? AppTheme.errorColor
                                      : percent >= 0.6
                                          ? AppTheme.warningColor
                                          : AppTheme.successColor;
                                  return Row(
                                    children: [
                                      Text(
                                        'Okupansi Volume: ${usedM3.toStringAsFixed(2)}/${totalM3.toStringAsFixed(2)} m3',
                                        style: AppTheme.bodySmall,
                                      ),
                                      const SizedBox(width: AppTheme.spacingM),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: totalM3 > 0 ? percent : 0,
                                          backgroundColor: AppTheme.borderDark,
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingM),
                                      Text('${(percent * 100).toStringAsFixed(1)}%', style: AppTheme.labelMedium),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: AppTheme.surfaceDark,
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
                              case 'manage_bins':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BinManagementPage(
                                      warehouseId: warehouse.warehouseId,
                                      warehouseName: warehouse.name,
                                    ),
                                  ),
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'add_stock',
                              child: ListTile(
                                leading: Icon(Icons.add_circle, color: AppTheme.successColor),
                                title: Text('Tambah Stok (+10)'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'remove_stock',
                              child: ListTile(
                                leading: Icon(Icons.remove_circle, color: AppTheme.warningColor),
                                title: Text('Kurangi Stok (-10)'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: AppTheme.errorColor),
                                title: Text('Hapus'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'manage_bins',
                              child: ListTile(
                                leading: Icon(Icons.view_list),
                                title: Text('Kelola Bin'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openForm(warehouse),
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
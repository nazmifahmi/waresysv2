import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/logistics/bin_repository.dart';
import '../../models/logistics/bin_model.dart';
import '../../utils/volume_conversion.dart';

class BinManagementPage extends StatefulWidget {
  final String warehouseId;
  final String warehouseName;
  const BinManagementPage({super.key, required this.warehouseId, required this.warehouseName});

  @override
  State<BinManagementPage> createState() => _BinManagementPageState();
}

class _BinManagementPageState extends State<BinManagementPage> {
  final BinRepository _repo = BinRepository();

  void _openCreateBin() {
    showDialog(
      context: context,
      builder: (context) => _BinFormDialog(
        onSubmit: (name, capacity, unit) async {
          final bin = BinModel(
            binId: '',
            warehouseId: widget.warehouseId,
            name: name,
            capacityVolume: capacity,
            capacityUnit: unit,
            createdAt: DateTime.now(),
            updatedAt: null,
          );
          await _repo.create(bin);
        },
      ),
    );
  }

  void _openEditBin(BinModel bin) {
    showDialog(
      context: context,
      builder: (context) => _BinFormDialog(
        initialName: bin.name,
        initialCapacity: bin.capacityVolume,
        initialUnit: bin.capacityUnit,
        onSubmit: (name, capacity, unit) async {
          final updated = BinModel(
            binId: bin.binId,
            warehouseId: bin.warehouseId,
            name: name,
            capacityVolume: capacity,
            capacityUnit: unit,
            createdAt: bin.createdAt,
            updatedAt: DateTime.now(),
          );
          await _repo.update(updated);
        },
      ),
    );
  }

  Future<void> _deleteBin(BinModel bin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Bin'),
        content: Text('Hapus bin "${bin.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(bin.binId);
    }
  }

  Future<double> _computeOccupancyPercent(BinModel bin) async {
    final usedM3 = await _repo.computeBinUsedVolumeM3(widget.warehouseId, bin.binId);
    final capacityM3 = VolumeConversion.convert(bin.capacityVolume, from: bin.capacityUnit, to: 'm3');
    if (capacityM3 <= 0) return 0.0;
    return usedM3 / capacityM3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: 'Kelola Bin - ${widget.warehouseName}',
        actions: [
          IconButton(onPressed: _openCreateBin, icon: const Icon(Icons.add, color: AppTheme.textPrimary)),
        ],
      ),
      body: StreamBuilder<List<BinModel>>(
        stream: _repo.watchByWarehouse(widget.warehouseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CommonWidgets.buildLoadingIndicator();
          }
          if (snapshot.hasError) {
            return CommonWidgets.buildErrorState(
              title: 'Terjadi kesalahan',
              subtitle: snapshot.error?.toString(),
            );
          }
          final bins = snapshot.data ?? const [];
          if (bins.isEmpty) {
            return CommonWidgets.buildEmptyState(
              title: 'Belum ada bin',
              subtitle: 'Tambahkan bin untuk mengelola stok per lokasi',
              icon: Icons.inventory_2,
              action: CommonWidgets.buildPrimaryButton(
                text: 'Tambah Bin',
                icon: Icons.add,
                onPressed: _openCreateBin,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            itemCount: bins.length,
            itemBuilder: (context, i) {
              final b = bins[i];
              return FutureBuilder<double>(
                future: _computeOccupancyPercent(b),
                builder: (context, occSnap) {
                  final percent = occSnap.data ?? 0.0;
                  final color = percent >= 0.8
                      ? AppTheme.errorColor
                      : percent >= 0.6
                          ? AppTheme.warningColor
                          : AppTheme.successColor;
                  final capacityStr = '${b.capacityVolume.toStringAsFixed(2)} ${b.capacityUnit}';
                  return CommonWidgets.buildCard(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.name, style: AppTheme.heading4),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacingXS),
                          Text('Kapasitas: $capacityStr', style: AppTheme.bodySmall),
                          const SizedBox(height: AppTheme.spacingS),
                          LinearProgressIndicator(
                            value: percent,
                            backgroundColor: AppTheme.borderDark,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text('${(percent * 100).toStringAsFixed(1)}% terpakai', style: AppTheme.labelMedium),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        color: AppTheme.surfaceDark,
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _openEditBin(b);
                              break;
                            case 'delete':
                              _deleteBin(b);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                          PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete), title: Text('Hapus'))),
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
    );
  }
}

class _BinFormDialog extends StatefulWidget {
  final String? initialName;
  final double? initialCapacity;
  final String? initialUnit;
  final Future<void> Function(String name, double capacity, String unit) onSubmit;
  const _BinFormDialog({
    required this.onSubmit,
    this.initialName,
    this.initialCapacity,
    this.initialUnit,
  });

  @override
  State<_BinFormDialog> createState() => _BinFormDialogState();
}

class _BinFormDialogState extends State<_BinFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  String _unit = 'm3';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _capacityController.text = widget.initialCapacity?.toString() ?? '';
    _unit = widget.initialUnit ?? 'm3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Tambah Bin' : 'Edit Bin'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Bin'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Kapasitas'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 0) return 'Masukkan angka >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'm3', child: Text('m3')),
                  DropdownMenuItem(value: 'liter', child: Text('liter')),
                  DropdownMenuItem(value: 'cm3', child: Text('cm3')),
                  DropdownMenuItem(value: 'ft3', child: Text('ft3')),
                ],
                onChanged: (val) => setState(() => _unit = val ?? 'm3'),
                decoration: const InputDecoration(labelText: 'Satuan Volume'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  final name = _nameController.text.trim();
                  final capacity = double.parse(_capacityController.text.trim());
                  await widget.onSubmit(name, capacity, _unit);
                  if (context.mounted) Navigator.pop(context);
                },
          child: _loading ? const CircularProgressIndicator() : const Text('Simpan'),
        ),
      ],
    );
  }
}
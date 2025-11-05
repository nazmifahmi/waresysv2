import 'package:flutter/material.dart';
import '../../models/logistics/warehouse_location_model.dart';
import '../../services/logistics/warehouse_repository.dart';

class WarehouseFormPage extends StatefulWidget {
  final WarehouseModel? existing;

  const WarehouseFormPage({super.key, this.existing});

  @override
  State<WarehouseFormPage> createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends State<WarehouseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _stockCountController = TextEditingController();
  final _capacityController = TextEditingController();
  final _volumeController = TextEditingController();
  String _volumeUnit = 'm3';
  final WarehouseRepository _repository = WarehouseRepository();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final warehouse = widget.existing!;
      _nameController.text = warehouse.name;
      _locationController.text = warehouse.location;
      _stockCountController.text = warehouse.stockCount.toString();
      _capacityController.text = warehouse.capacity.toString();
      _volumeController.text = warehouse.volume.toString();
      _volumeUnit = warehouse.volumeUnit;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final warehouse = WarehouseModel(
        warehouseId: widget.existing?.warehouseId ?? '',
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        stockCount: int.parse(_stockCountController.text.trim()),
        capacity: int.parse(_capacityController.text.trim()),
        volume: double.tryParse(_volumeController.text.trim()) ?? 0.0,
        volumeUnit: _volumeUnit,
      );

      if (widget.existing != null) {
        await _repository.update(warehouse);
      } else {
        await _repository.create(warehouse);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null 
                ? 'Data gudang berhasil diperbarui' 
                : 'Data gudang berhasil ditambahkan'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Gudang' : 'Tambah Gudang'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Gudang',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama gudang harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokasi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lokasi harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _volumeController,
              decoration: const InputDecoration(
                labelText: 'Volume Gudang',
                hintText: 'contoh: 120.5',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return null; // optional
                final vol = double.tryParse(value!.trim());
                if (vol == null || vol < 0) {
                  return 'Volume harus berupa angka >= 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _volumeUnit,
              decoration: const InputDecoration(
                labelText: 'Satuan Volume',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'm3', child: Text('m³')),
                DropdownMenuItem(value: 'ft3', child: Text('ft³')),
              ],
              onChanged: (val) => setState(() => _volumeUnit = val ?? 'm3'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockCountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok Saat Ini',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah stok harus diisi';
                }
                final stockCount = int.tryParse(value.trim());
                if (stockCount == null || stockCount < 0) {
                  return 'Jumlah stok harus berupa angka non-negatif';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Kapasitas Maksimal',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kapasitas harus diisi';
                }
                final capacity = int.tryParse(value.trim());
                if (capacity == null || capacity <= 0) {
                  return 'Kapasitas harus berupa angka positif';
                }
                
                // Validate that capacity is greater than or equal to current stock
                final stockCount = int.tryParse(_stockCountController.text.trim()) ?? 0;
                if (capacity < stockCount) {
                  return 'Kapasitas tidak boleh kurang dari stok saat ini';
                }
                
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.existing != null ? 'Perbarui' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _stockCountController.dispose();
    _capacityController.dispose();
    _volumeController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import '../../models/logistics/fleet_vehicle_model.dart';
import '../../services/logistics/fleet_repository.dart';

class FleetFormPage extends StatefulWidget {
  final FleetModel? existing;

  const FleetFormPage({super.key, this.existing});

  @override
  State<FleetFormPage> createState() => _FleetFormPageState();
}

class _FleetFormPageState extends State<FleetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final FleetRepository _repository = FleetRepository();
  
  VehicleStatus _status = VehicleStatus.AVAILABLE;
  DateTime? _lastMaintenance;
  bool _isLoading = false;

  final List<VehicleStatus> _statusOptions = [
    VehicleStatus.AVAILABLE,
    VehicleStatus.ON_DUTY,
    VehicleStatus.MAINTENANCE
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final fleet = widget.existing!;
      _vehicleNumberCtrl.text = fleet.vehicleNumber;
      _driverNameCtrl.text = fleet.driverName;
      _capacityCtrl.text = fleet.capacity.toString();
      _status = fleet.status;
      _lastMaintenance = fleet.lastServiceDate;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastMaintenance ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _lastMaintenance) {
      setState(() {
        _lastMaintenance = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fleet = FleetModel(
        fleetId: widget.existing?.fleetId ?? '',
        vehicleNumber: _vehicleNumberCtrl.text.trim(),
        driverName: _driverNameCtrl.text.trim(),
        capacity: double.parse(_capacityCtrl.text.trim()),
        status: _status,
        lastServiceDate: _lastMaintenance,
        nextServiceDate: _lastMaintenance?.add(Duration(days: 90)), // Example: next service in 90 days
      );

      await _repository.upsertFleet(fleet);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null 
                ? 'Data armada berhasil diperbarui' 
                : 'Data armada berhasil ditambahkan'),
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
        title: Text(widget.existing != null ? 'Edit Armada' : 'Tambah Armada'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _vehicleNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Nomor Kendaraan',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor kendaraan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _driverNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Driver',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama driver harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityCtrl,
              decoration: const InputDecoration(
                labelText: 'Kapasitas (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kapasitas harus diisi';
                }
                final capacity = double.tryParse(value.trim());
                if (capacity == null || capacity <= 0) {
                  return 'Kapasitas harus berupa angka positif';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VehicleStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Service Terakhir',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _lastMaintenance != null 
                    ? '${_lastMaintenance!.day}/${_lastMaintenance!.month}/${_lastMaintenance!.year}'
                    : 'Pilih tanggal service',
                ),
              ),
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
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }
}
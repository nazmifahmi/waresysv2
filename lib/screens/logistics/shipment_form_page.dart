import 'package:flutter/material.dart';
import '../../models/logistics/shipment_model.dart';
import '../../services/logistics/shipment_repository.dart';

class ShipmentFormPage extends StatefulWidget {
  final ShipmentModel? existing;

  const ShipmentFormPage({super.key, this.existing});

  @override
  State<ShipmentFormPage> createState() => _ShipmentFormPageState();
}

class _ShipmentFormPageState extends State<ShipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _trackingNumberCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _carrierCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final ShipmentRepository _repository = ShipmentRepository();
  
  String _status = 'pending';
  bool _isLoading = false;

  final List<String> _statusOptions = ['pending', 'in_transit', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final shipment = widget.existing!;
      _trackingNumberCtrl.text = shipment.trackingNumber;
      _originCtrl.text = shipment.origin;
      _destinationCtrl.text = shipment.destination;
      _carrierCtrl.text = shipment.carrier;
      _costCtrl.text = shipment.cost.toString();
      _status = shipment.status.name;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final statusEnum = ShipmentStatus.values.firstWhere(
        (e) => e.name == _status,
        orElse: () => ShipmentStatus.pending,
      );
      
      final shipment = ShipmentModel(
        shipmentId: widget.existing?.shipmentId ?? '',
        trackingNumber: _trackingNumberCtrl.text.trim(),
        origin: _originCtrl.text.trim(),
        destination: _destinationCtrl.text.trim(),
        carrier: _carrierCtrl.text.trim(),
        cost: double.parse(_costCtrl.text.trim()),
        status: statusEnum,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing != null) {
        await _repository.update(shipment);
      } else {
        await _repository.create(shipment);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null 
                ? 'Data pengiriman berhasil diperbarui' 
                : 'Data pengiriman berhasil ditambahkan'),
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
        title: Text(widget.existing != null ? 'Edit Pengiriman' : 'Tambah Pengiriman'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _trackingNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tracking number harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _originCtrl,
              decoration: const InputDecoration(
                labelText: 'Asal',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Asal harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                labelText: 'Tujuan',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tujuan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carrierCtrl,
              decoration: const InputDecoration(
                labelText: 'Kurir/Carrier',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kurir harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costCtrl,
              decoration: const InputDecoration(
                labelText: 'Biaya (Rp)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Biaya harus diisi';
                }
                final cost = double.tryParse(value.trim());
                if (cost == null || cost < 0) {
                  return 'Biaya harus berupa angka positif';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
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
    _trackingNumberCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _carrierCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }
}
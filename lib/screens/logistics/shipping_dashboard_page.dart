import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../models/logistics/shipment_model.dart';
import '../../services/logistics/shipment_repository.dart';
import 'shipment_form_page.dart';

class ShippingDashboardPage extends StatefulWidget {
  const ShippingDashboardPage({super.key});

  @override
  State<ShippingDashboardPage> createState() => _ShippingDashboardPageState();
}

class _ShippingDashboardPageState extends State<ShippingDashboardPage> {
  final ShipmentRepository _repository = ShipmentRepository();
  final _trackingNumberCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  @override
  void dispose() {
    _trackingNumberCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _openForm({ShipmentModel? shipment}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShipmentFormPage(existing: shipment)),
    );
    setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengiriman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _trackingNumberCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari berdasarkan tracking number...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _trackingNumberCtrl.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<ShipmentModel>>(
                future: _repository.getAll(search: _trackingNumberCtrl.text.trim().isEmpty ? null : _trackingNumberCtrl.text.trim()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return const Center(child: Text('Belum ada data pengiriman.'));
                  }
                  
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final shipment = list[i];
                      return Card(
                        child: ListTile(
                          title: Text('${shipment.trackingNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${shipment.origin} → ${shipment.destination}'),
                              Text('Carrier: ${shipment.carrier}'),
                              Text('Cost: Rp ${shipment.cost.toStringAsFixed(0)}'),
                            ],
                          ),
                          leading: _statusChip(shipment.status.name),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _openForm(shipment: shipment);
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi'),
                                    content: const Text('Hapus data pengiriman ini?'),
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
                                  await _repository.delete(shipment.shipmentId);
                                  setState(() {});
                                }
                              } else if (value.startsWith('status_')) {
                                final newStatusString = value.replaceFirst('status_', '');
                                final newStatus = ShipmentStatus.values.firstWhere(
                                  (e) => e.name == newStatusString,
                                  orElse: () => ShipmentStatus.pending,
                                );
                                final updatedShipment = ShipmentModel(
                                  shipmentId: shipment.shipmentId,
                                  trackingNumber: shipment.trackingNumber,
                                  origin: shipment.origin,
                                  destination: shipment.destination,
                                  carrier: shipment.carrier,
                                  cost: shipment.cost,
                                  status: newStatus,
                                  createdAt: shipment.createdAt,
                                  updatedAt: DateTime.now(),
                                );
                                await _repository.update(updatedShipment);
                                setState(() {});
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                              const PopupMenuItem(value: 'status_in_transit', child: Text('Set In Transit')),
                              const PopupMenuItem(value: 'status_delivered', child: Text('Set Delivered')),
                              const PopupMenuItem(value: 'status_cancelled', child: Text('Set Cancelled')),
                            ],
                          ),
                          onTap: () => _openForm(shipment: shipment),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
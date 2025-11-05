import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
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
    // Konsisten dengan enum ShipmentStatus: pending, inTransit, delivered, cancelled
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'intransit':
        return AppTheme.infoColor;
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'intransit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: 'Dashboard Pengiriman',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            CommonWidgets.buildTextField(
              label: 'Cari berdasarkan tracking number',
              hint: 'Masukkan nomor resi...',
              controller: _trackingNumberCtrl,
              prefixIcon: Icons.search,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _trackingNumberCtrl.clear();
                  setState(() {});
                },
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: FutureBuilder<List<ShipmentModel>>(
                future: _repository.getAll(
                  search: _trackingNumberCtrl.text.trim().isEmpty
                      ? null
                      : _trackingNumberCtrl.text.trim(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada data pengiriman.',
                        style: AppTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final shipment = list[i];
                      return CommonWidgets.buildCard(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            shipment.trackingNumber,
                            style: AppTheme.heading4,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${shipment.origin} → ${shipment.destination}', style: AppTheme.bodyMedium),
                                Text('Carrier: ${shipment.carrier}', style: AppTheme.bodySmall),
                                Text('Cost: Rp ${shipment.cost.toStringAsFixed(0)}', style: AppTheme.bodySmall),
                              ],
                            ),
                          ),
                          leading: _statusChip(shipment.status.name),
                          trailing: PopupMenuButton<String>(
                            color: AppTheme.surfaceDark,
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
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                              PopupMenuItem(value: 'status_inTransit', child: Text('Set In Transit')),
                              PopupMenuItem(value: 'status_delivered', child: Text('Set Delivered')),
                              PopupMenuItem(value: 'status_cancelled', child: Text('Set Cancelled')),
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
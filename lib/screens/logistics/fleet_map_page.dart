import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/logistics/fleet_vehicle_model.dart';
import '../../services/logistics/fleet_repository.dart';
import 'fleet_form_page.dart';

class FleetMapPage extends StatefulWidget {
  const FleetMapPage({super.key});

  @override
  State<FleetMapPage> createState() => _FleetMapPageState();
}

class _FleetMapPageState extends State<FleetMapPage> {
  final FleetRepository _repository = FleetRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  void _openForm({FleetModel? fleet}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FleetFormPage(existing: fleet)),
    );
    setState(() {});
  }

  Color _getStatusColor(String status) {
    // Konsisten dengan enum VehicleStatus: AVAILABLE, ON_DUTY, MAINTENANCE
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return AppTheme.successColor;
      case 'ON_DUTY':
        return AppTheme.infoColor;
      case 'MAINTENANCE':
        return AppTheme.warningColor;
      default:
        return AppTheme.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return 'Available';
      case 'ON_DUTY':
        return 'On Duty';
      case 'MAINTENANCE':
        return 'Maintenance';
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
        title: 'Manajemen Armada',
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
              label: 'Cari kendaraan',
              hint: 'Nomor kendaraan / driver',
              controller: _searchCtrl,
              prefixIcon: Icons.search,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FleetModel>>(
              future: _repository.getAll(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(child: Text('Belum ada data armada.', style: AppTheme.bodyMedium));
                }
                
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final fleet = list[i];
                    return CommonWidgets.buildCard(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(fleet.vehicleNumber, style: AppTheme.heading4),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Driver: ${fleet.driverName}', style: AppTheme.bodySmall),
                              Text('Capacity: ${fleet.capacity} kg', style: AppTheme.bodySmall),
                              if (fleet.lastServiceDate != null)
                                Text(
                                  'Last Service: ${fleet.lastServiceDate!.day}/${fleet.lastServiceDate!.month}/${fleet.lastServiceDate!.year}',
                                  style: AppTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        leading: _statusChip(fleet.status.name),
                        trailing: PopupMenuButton<String>(
                          color: AppTheme.surfaceDark,
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _openForm(fleet: fleet);
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi'),
                                  content: const Text('Hapus data armada ini?'),
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
                                await _repository.delete(fleet.fleetId);
                                setState(() {});
                              }
                            } else if (value.startsWith('status_')) {
                              final newStatusString = value.replaceFirst('status_', '');
                              final newStatus = VehicleStatus.values.firstWhere(
                                (status) => status.name == newStatusString,
                                orElse: () => VehicleStatus.AVAILABLE,
                              );
                              final updatedFleet = FleetModel(
                                fleetId: fleet.fleetId,
                                vehicleNumber: fleet.vehicleNumber,
                                driverName: fleet.driverName,
                                capacity: fleet.capacity,
                                status: newStatus,
                                lastServiceDate: fleet.lastServiceDate,
                                nextServiceDate: fleet.nextServiceDate,
                              );
                              await _repository.upsertFleet(updatedFleet);
                              setState(() {});
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            PopupMenuItem(value: 'status_AVAILABLE', child: Text('Set Available')),
                            PopupMenuItem(value: 'status_ON_DUTY', child: Text('Set On Duty')),
                            PopupMenuItem(value: 'status_MAINTENANCE', child: Text('Set Maintenance')),
                          ],
                        ),
                        onTap: () => _openForm(fleet: fleet),
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
    _searchCtrl.dispose();
    super.dispose();
  }
}
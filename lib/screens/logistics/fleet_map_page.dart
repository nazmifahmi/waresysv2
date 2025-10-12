import 'package:flutter/material.dart';
import '../../constants/theme.dart';
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
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
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
        title: const Text('Manajemen Armada'),
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari kendaraan...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                ),
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
                  return const Center(child: Text('Belum ada data armada.'));
                }
                
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final fleet = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text('${fleet.vehicleNumber}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Driver: ${fleet.driverName}'),
                            Text('Capacity: ${fleet.capacity} kg'),
                            if (fleet.lastServiceDate != null)
                              Text('Last Service: ${fleet.lastServiceDate!.day}/${fleet.lastServiceDate!.month}/${fleet.lastServiceDate!.year}'),
                          ],
                        ),
                        leading: _statusChip(fleet.status.name),
                        trailing: PopupMenuButton<String>(
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
                                (status) => status.name.toLowerCase() == newStatusString.toLowerCase(),
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
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            const PopupMenuItem(value: 'status_active', child: Text('Set Active')),
                            const PopupMenuItem(value: 'status_maintenance', child: Text('Set Maintenance')),
                            const PopupMenuItem(value: 'status_inactive', child: Text('Set Inactive')),
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
import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../models/logistics/warehouse_location_model.dart';
import '../../providers/logistics/warehouse_bloc.dart';
import '../../services/logistics/warehouse_repository.dart';

class WarehouseManagementPage extends StatefulWidget {
  final String warehouseId;
  const WarehouseManagementPage({super.key, required this.warehouseId});

  @override
  State<WarehouseManagementPage> createState() => _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  late final WarehouseBloc _bloc;
  final _productCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = WarehouseBloc(repository: WarehouseRepository());
    _bloc.load(widget.warehouseId);
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Gudang')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _productCtrl,
                    decoration: const InputDecoration(hintText: 'Filter productId'),
                    onSubmitted: (v) => _bloc.load(widget.warehouseId, productId: v.trim().isEmpty ? null : v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _bloc.load(widget.warehouseId, productId: _productCtrl.text.trim().isEmpty ? null : _productCtrl.text.trim()),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<WarehouseLocationModel>>(
                stream: _bloc.locations,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (data.isEmpty) return const Center(child: Text('Tidak ada lokasi.'));
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final l = data[i];
                      return ListTile(
                        title: Text('${l.zone}-${l.rack}-${l.binCode} (${l.productId})'),
                        subtitle: Text('Qty: ${l.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _bloc.updateStock(l.locationId, -1)),
                            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _bloc.updateStock(l.locationId, 1)),
                          ],
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
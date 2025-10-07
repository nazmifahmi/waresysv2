import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../models/logistics/delivery_order_model.dart';
import '../../providers/logistics/shipping_dashboard_bloc.dart';
import '../../services/logistics/shipping_repository.dart';

class ShippingDashboardPage extends StatefulWidget {
  const ShippingDashboardPage({super.key});

  @override
  State<ShippingDashboardPage> createState() => _ShippingDashboardPageState();
}

class _ShippingDashboardPageState extends State<ShippingDashboardPage> {
  late final ShippingDashboardBloc _bloc;
  final _salesIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = ShippingDashboardBloc(repository: ShippingRepository());
    _bloc.watch();
  }

  @override
  void dispose() {
    _salesIdCtrl.dispose();
    _bloc.dispose();
    super.dispose();
  }

  Widget _statusChip(DeliveryStatus s) {
    final map = {
      DeliveryStatus.PENDING: Colors.grey,
      DeliveryStatus.PACKING: Colors.orange,
      DeliveryStatus.SHIPPED: Colors.blue,
      DeliveryStatus.DELIVERED: Colors.green,
    };
    return Chip(label: Text(s.name), backgroundColor: map[s]!.withOpacity(0.15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Pengiriman')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _salesIdCtrl, decoration: const InputDecoration(hintText: 'Sales Order ID'))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _bloc.createFromSales(_salesIdCtrl.text.trim()),
                  child: const Text('Buat DO'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<DeliveryOrderModel>>(
                stream: _bloc.deliveryOrders,
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.isEmpty) return const Center(child: Text('Belum ada Delivery Order.'));
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final d = list[i];
                      return ListTile(
                        title: Text('DO ${d.deliveryId} • Sales ${d.salesOrderId}'),
                        subtitle: Text('${d.courierName ?? '-'} • ${d.trackingNumber ?? '-'}'),
                        leading: _statusChip(d.status),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'PACKING') _bloc.setStatus(d.deliveryId, DeliveryStatus.PACKING);
                            if (v == 'SHIPPED') _bloc.setStatus(d.deliveryId, DeliveryStatus.SHIPPED);
                            if (v == 'DELIVERED') _bloc.setStatus(d.deliveryId, DeliveryStatus.DELIVERED);
                            if (v == 'LABEL') _bloc.printWaybill(d.deliveryId);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'PACKING', child: Text('Set PACKING')),
                            PopupMenuItem(value: 'SHIPPED', child: Text('Set SHIPPED')),
                            PopupMenuItem(value: 'DELIVERED', child: Text('Set DELIVERED')),
                            PopupMenuItem(value: 'LABEL', child: Text('Cetak Label')),
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
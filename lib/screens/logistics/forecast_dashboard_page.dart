import 'package:flutter/material.dart';
import '../../models/logistics/forecast_result_model.dart';
import '../../providers/logistics/demand_forecast_bloc.dart';
import '../../services/logistics/forecast_service.dart';

class ForecastDashboardPage extends StatefulWidget {
  final String productId;
  const ForecastDashboardPage({super.key, required this.productId});

  @override
  State<ForecastDashboardPage> createState() => _ForecastDashboardPageState();
}

class _ForecastDashboardPageState extends State<ForecastDashboardPage> {
  late final DemandForecastBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = DemandForecastBloc(service: ForecastService());
    _bloc.run(widget.productId);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Widget _tile(String label, String value) {
    return ListTile(title: Text(label), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Peramalan')),
      body: StreamBuilder<ForecastResultModel?>(
        stream: _bloc.result,
        builder: (context, snapshot) {
          final r = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting || r == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              _tile('Produk', r.productId),
              _tile('Forecast 30 hari', r.forecastedDemand.toStringAsFixed(1)),
              _tile('Stok saat ini', r.currentStock.toString()),
              _tile('Safety Stock', r.safetyStockLevel.toString()),
              _tile('Rekomendasi Pembelian', r.recommendedPurchaseQuantity.toString()),
            ],
          );
        },
      ),
    );
  }
}
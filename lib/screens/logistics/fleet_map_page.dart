import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/logistics/fleet_tracking_bloc.dart';
import '../../services/logistics/fleet_repository.dart';

class FleetMapPage extends StatefulWidget {
  final String routeId;
  const FleetMapPage({super.key, required this.routeId});

  @override
  State<FleetMapPage> createState() => _FleetMapPageState();
}

class _FleetMapPageState extends State<FleetMapPage> {
  late final FleetTrackingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = FleetTrackingBloc(repository: FleetRepository());
    _bloc.start(widget.routeId);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: To use Google Maps widget, ensure plugin setup; here we show coordinates for simplicity.
    return Scaffold(
      appBar: AppBar(title: const Text('Pelacakan Armada')),
      body: Center(
        child: StreamBuilder<GeoPoint?>(
          stream: _bloc.location,
          builder: (context, snapshot) {
            final loc = snapshot.data;
            if (loc == null) return const Text('Menunggu lokasi kendaraan...');
            return Text('Posisi: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}');
          },
        ),
      ),
    );
  }
}
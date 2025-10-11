import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/fleet_vehicle_model.dart';
import '../../models/logistics/fleet_route_model.dart';

class FleetRepository {
  final FirebaseFirestore _firestore;
  FleetRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vehicles => _firestore.collection('fleet_vehicles');
  CollectionReference<Map<String, dynamic>> get _routes => _firestore.collection('fleet_routes');

  Future<String> upsertVehicle(FleetVehicleModel v) async {
    if (v.vehicleId.isEmpty) {
      final ref = await _vehicles.add(v.toMap());
      await _vehicles.doc(ref.id).update({'vehicleId': ref.id});
      return ref.id;
    } else {
      await _vehicles.doc(v.vehicleId).set(v.toMap(), SetOptions(merge: true));
      return v.vehicleId;
    }
  }

  Future<String> assignDriverToRoute({
    required String deliveryOrderId,
    required String vehicleId,
    required String driverId,
    required DateTime departure,
    required DateTime eta,
  }) async {
    final ref = await _routes.add({
      'deliveryOrderId': deliveryOrderId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'departureTime': Timestamp.fromDate(departure),
      'estimatedArrivalTime': Timestamp.fromDate(eta),
      'currentLocation': null,
    });
    await _routes.doc(ref.id).update({'routeId': ref.id});
    await _vehicles.doc(vehicleId).update({'status': VehicleStatus.ON_DUTY.name});
    return ref.id;
  }

  Stream<GeoPoint?> updateVehicleLocationStream(String routeId) {
    return _routes.doc(routeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return data['currentLocation'] as GeoPoint?;
    });
  }

  Future<void> setVehicleLocation(String routeId, GeoPoint location) async {
    await _routes.doc(routeId).update({'currentLocation': location});
  }

  Future<List<FleetVehicleModel>> getMaintenanceSchedule({DateTime? until}) async {
    final now = DateTime.now();
    final limitDate = until ?? now.add(const Duration(days: 30));
    final snap = await _vehicles.where('nextServiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now)).get();
    return snap.docs
        .map((d) => FleetVehicleModel.fromDoc(d))
        .where((v) => (v.nextServiceDate ?? limitDate).isBefore(limitDate))
        .toList();
  }
}
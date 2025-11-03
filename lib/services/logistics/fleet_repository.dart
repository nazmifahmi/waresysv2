import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/fleet_vehicle_model.dart';

class FleetRepository {
  final FirebaseFirestore _firestore;
  FleetRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _fleets => _firestore.collection('fleets');

  Future<String> upsertFleet(FleetModel fleet) async {
    if (fleet.fleetId.isEmpty) {
      final ref = await _fleets.add({
        ...fleet.toMap(),
        'vehicleNumberLower': fleet.vehicleNumber.toLowerCase(),
        'driverNameLower': fleet.driverName.toLowerCase(),
      });
      await _fleets.doc(ref.id).update({'fleetId': ref.id});
      return ref.id;
    } else {
      await _fleets.doc(fleet.fleetId).set({
        ...fleet.toMap(),
        'vehicleNumberLower': fleet.vehicleNumber.toLowerCase(),
        'driverNameLower': fleet.driverName.toLowerCase(),
      }, SetOptions(merge: true));
      return fleet.fleetId;
    }
  }

  Future<List<FleetModel>> getAll({String? search}) async {
    Query query = _fleets.orderBy('vehicleNumber');
    if (search != null && search.trim().isNotEmpty) {
      query = _fleets.where('vehicleNumberLower', isGreaterThanOrEqualTo: search.toLowerCase())
                    .where('vehicleNumberLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => FleetModel.fromDoc(d)).toList();
  }

  Stream<List<FleetModel>> watchAll() {
    return _fleets.orderBy('vehicleNumber').snapshots().map((s) => s.docs.map((d) => FleetModel.fromDoc(d)).toList());
  }

  Future<FleetModel?> getById(String id) async {
    final doc = await _fleets.doc(id).get();
    if (!doc.exists) return null;
    return FleetModel.fromDoc(doc);
  }

  Future<void> updateStatus(String fleetId, VehicleStatus status) async {
    await _fleets.doc(fleetId).update({'status': status.name});
  }

  Stream<List<FleetModel>> watchByStatus(VehicleStatus status) {
    return _fleets.where('status', isEqualTo: status.name).orderBy('vehicleNumber').snapshots().map(
          (s) => s.docs.map((d) => FleetModel.fromDoc(d)).toList(),
        );
  }

  Future<void> delete(String id) async {
    await _fleets.doc(id).delete();
  }

  // Fleet tracking methods
  Stream<GeoPoint?> updateVehicleLocationStream(String routeId) {
    return _fleets.doc(routeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || !data.containsKey('currentLocation')) return null;
      return data['currentLocation'] as GeoPoint?;
    });
  }

  Future<void> setVehicleLocation(String routeId, GeoPoint location) async {
    await _fleets.doc(routeId).update({
      'currentLocation': location,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
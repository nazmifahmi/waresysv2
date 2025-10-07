import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/logistics/fleet_repository.dart';

class FleetTrackingBloc {
  final FleetRepository _repo;
  final _locationCtrl = StreamController<GeoPoint?>.broadcast();

  Stream<GeoPoint?> get location => _locationCtrl.stream;

  FleetTrackingBloc({required FleetRepository repository}) : _repo = repository;

  StreamSubscription? _sub;

  void start(String routeId) {
    _sub?.cancel();
    _sub = _repo.updateVehicleLocationStream(routeId).listen(_locationCtrl.add);
  }

  Future<void> update(String routeId, GeoPoint loc) => _repo.setVehicleLocation(routeId, loc);

  void dispose() {
    _sub?.cancel();
    _locationCtrl.close();
  }
}
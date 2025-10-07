import 'dart:async';
import '../../models/logistics/warehouse_location_model.dart';
import '../../services/logistics/warehouse_repository.dart';

class WarehouseBloc {
  final WarehouseRepository _repo;
  final _locationsCtrl = StreamController<List<WarehouseLocationModel>>.broadcast();
  final _loadingCtrl = StreamController<bool>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();

  Stream<List<WarehouseLocationModel>> get locations => _locationsCtrl.stream;
  Stream<bool> get loading => _loadingCtrl.stream;
  Stream<String?> get error => _errorCtrl.stream;

  WarehouseBloc({required WarehouseRepository repository}) : _repo = repository;

  Future<void> load(String warehouseId, {String? productId}) async {
    _loadingCtrl.add(true);
    try {
      final list = await _repo.getLocations(warehouseId: warehouseId, productId: productId);
      _locationsCtrl.add(list);
      _errorCtrl.add(null);
    } catch (e) {
      _errorCtrl.add(e.toString());
    } finally {
      _loadingCtrl.add(false);
    }
  }

  Future<WarehouseLocationModel?> findOptimalBin(String warehouseId, String productId) {
    return _repo.findOptimalBin(warehouseId: warehouseId, productId: productId);
  }

  Future<void> updateStock(String locationId, int delta) => _repo.updateStockLocation(locationId: locationId, deltaQty: delta);

  void dispose() {
    _locationsCtrl.close();
    _loadingCtrl.close();
    _errorCtrl.close();
  }
}
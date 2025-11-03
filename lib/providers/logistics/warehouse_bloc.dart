import 'dart:async';
import '../../models/logistics/warehouse_location_model.dart';
import '../../services/logistics/warehouse_repository.dart';

class WarehouseBloc {
  final WarehouseRepository _repo;
  final _locationsCtrl = StreamController<List<WarehouseModel>>.broadcast();
  final _loadingCtrl = StreamController<bool>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();

  Stream<List<WarehouseModel>> get locations => _locationsCtrl.stream;
  Stream<bool> get loading => _loadingCtrl.stream;
  Stream<String?> get error => _errorCtrl.stream;

  WarehouseBloc({required WarehouseRepository repository}) : _repo = repository;

  Future<void> load(String warehouseId, {String? productId}) async {
    _loadingCtrl.add(true);
    try {
      final list = await _repo.getAll();
      _locationsCtrl.add(list);
      _errorCtrl.add(null);
    } catch (e) {
      _errorCtrl.add(e.toString());
    } finally {
      _loadingCtrl.add(false);
    }
  }

  Future<WarehouseModel?> findOptimalWarehouse(String productId) async {
    try {
      final warehouses = await _repo.getAll();
      // Find warehouse with most available capacity
      if (warehouses.isEmpty) return null;
      
      warehouses.sort((a, b) => (b.capacity - b.stockCount).compareTo(a.capacity - a.stockCount));
      return warehouses.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateStock(String locationId, int delta) => _repo.updateStock(warehouseId: locationId, deltaStock: delta);

  void dispose() {
    _locationsCtrl.close();
    _loadingCtrl.close();
    _errorCtrl.close();
  }
}
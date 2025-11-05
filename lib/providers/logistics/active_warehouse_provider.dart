import 'package:flutter/foundation.dart';
import '../../models/logistics/warehouse_location_model.dart';

class ActiveWarehouseProvider with ChangeNotifier {
  WarehouseModel? _activeWarehouse;

  WarehouseModel? get activeWarehouse => _activeWarehouse;
  String? get activeWarehouseId => _activeWarehouse?.warehouseId;

  void setActiveWarehouse(WarehouseModel? warehouse) {
    _activeWarehouse = warehouse;
    notifyListeners();
  }

  void clear() {
    setActiveWarehouse(null);
  }
}
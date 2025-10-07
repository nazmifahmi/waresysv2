import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/delivery_order_model.dart';
import '../../services/logistics/shipping_repository.dart';

class ShippingDashboardBloc {
  final ShippingRepository _repo;
  final FirebaseFirestore _firestore;

  final _listCtrl = StreamController<List<DeliveryOrderModel>>.broadcast();
  final _loadingCtrl = StreamController<bool>.broadcast();

  Stream<List<DeliveryOrderModel>> get deliveryOrders => _listCtrl.stream;
  Stream<bool> get loading => _loadingCtrl.stream;

  ShippingDashboardBloc({required ShippingRepository repository, FirebaseFirestore? firestore})
      : _repo = repository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  StreamSubscription? _sub;

  void watch() {
    _loadingCtrl.add(true);
    _sub?.cancel();
    _sub = _firestore.collection('delivery_orders').orderBy('salesOrderId', descending: true).snapshots().listen((snap) {
      final list = snap.docs.map((d) => DeliveryOrderModel.fromDoc(d)).toList();
      _listCtrl.add(list);
      _loadingCtrl.add(false);
    });
  }

  Future<void> createFromSales(String salesOrderId) => _repo.createDeliveryOrderFromSale(salesOrderId);

  Future<void> setStatus(String deliveryId, DeliveryStatus status) => _repo.updateStatus(deliveryId, status);

  Future<void> setCourier(String deliveryId, String courier) => _repo.assignCourier(deliveryId: deliveryId, courierName: courier);

  Future<String> printWaybill(String deliveryId) => _repo.printWaybill(deliveryId);

  void dispose() {
    _sub?.cancel();
    _listCtrl.close();
    _loadingCtrl.close();
  }
}
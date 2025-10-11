import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/delivery_order_model.dart' as logistics;
import '../../models/transaction_model.dart'; // Sales/Purchase model in project

class ShippingRepository {
  final FirebaseFirestore _firestore;
  ShippingRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _delivery => _firestore.collection('delivery_orders');

  Future<String> generateTrackingNumber() async {
    final rnd = Random().nextInt(999999);
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'WS$ts$rnd';
    // In prod: call courier API and return their tracking code
  }

  Future<String> createDeliveryOrderFromSale(String salesOrderId) async {
    // Load transaction and ensure it's a sales order
    final doc = await _firestore.collection('transactions').doc(salesOrderId).get();
    if (!doc.exists) throw Exception('Sales order tidak ditemukan');
    final tx = TransactionModel.fromFirestore(doc);
    if (tx.type != TransactionType.sales) throw Exception('Hanya sales order yang dapat dibuat DO');

    final ref = await _delivery.add({
      'salesOrderId': salesOrderId,
      'status': logistics.DeliveryStatus.PENDING.name,
      'courierName': null,
      'trackingNumber': null,
      'shippingLabelUrl': null,
    });
    await _delivery.doc(ref.id).update({'deliveryId': ref.id});
    return ref.id;
  }

  Future<void> updateStatus(String deliveryId, logistics.DeliveryStatus status) async {
    await _delivery.doc(deliveryId).update({'status': status.name});
  }

  Future<void> assignCourier({
    required String deliveryId,
    required String courierName,
  }) async {
    await _delivery.doc(deliveryId).update({'courierName': courierName});
  }

  Future<String> printWaybill(String deliveryId) async {
    // Mock integration: generate fake URL
    final url = 'https://example.com/waybill/$deliveryId.pdf';
    await _delivery.doc(deliveryId).update({'shippingLabelUrl': url});
    return url;
  }
}
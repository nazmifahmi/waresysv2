import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/shipment_model.dart';

class ShipmentRepository {
  final FirebaseFirestore _firestore;

  ShipmentRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('shipments');

  Future<List<ShipmentModel>> getAll({String? search}) async {
    Query query = _col.orderBy('createdAt', descending: true);
    if (search != null && search.trim().isNotEmpty) {
      query = _col.where('trackingNumberLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('trackingNumberLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => ShipmentModel.fromDoc(d)).toList();
  }

  Stream<List<ShipmentModel>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map((d) => ShipmentModel.fromDoc(d)).toList());
  }

  Future<ShipmentModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ShipmentModel.fromDoc(doc);
  }

  Future<String> create(ShipmentModel shipment) async {
    final ref = await _col.add({
      ...shipment.toMap(),
      'trackingNumberLower': shipment.trackingNumber.toLowerCase(),
      'originLower': shipment.origin.toLowerCase(),
      'destinationLower': shipment.destination.toLowerCase(),
      'carrierLower': shipment.carrier.toLowerCase(),
    });
    await _col.doc(ref.id).update({'shipmentId': ref.id});
    return ref.id;
  }

  Future<void> update(ShipmentModel shipment) async {
    await _col.doc(shipment.shipmentId).update({
      ...shipment.toMap(),
      'trackingNumberLower': shipment.trackingNumber.toLowerCase(),
      'originLower': shipment.origin.toLowerCase(),
      'destinationLower': shipment.destination.toLowerCase(),
      'carrierLower': shipment.carrier.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> updateStatus(String shipmentId, ShipmentStatus status) async {
    await _col.doc(shipmentId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ShipmentModel>> getByStatus(ShipmentStatus status) async {
    final snap = await _col
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ShipmentModel.fromDoc(d)).toList();
  }

  Future<List<ShipmentModel>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final snap = await _col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ShipmentModel.fromDoc(d)).toList();
  }

  Future<double> getTotalShippingCost({DateTime? startDate, DateTime? endDate}) async {
    Query query = _col;
    
    if (startDate != null && endDate != null) {
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    final snap = await query.get();
    double total = 0;
    for (final doc in snap.docs) {
      final shipment = ShipmentModel.fromDoc(doc);
      total += shipment.cost;
    }
    return total;
  }
}
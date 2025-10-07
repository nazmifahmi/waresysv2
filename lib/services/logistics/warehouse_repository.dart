import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/warehouse_location_model.dart';

class WarehouseRepository {
  final FirebaseFirestore _firestore;
  WarehouseRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _locations => _firestore.collection('warehouse_locations');

  Future<List<WarehouseLocationModel>> getLocations({String? warehouseId, String? productId}) async {
    Query q = _locations;
    if (warehouseId != null) q = q.where('warehouseId', isEqualTo: warehouseId);
    if (productId != null) q = q.where('productId', isEqualTo: productId);
    final snap = await q.get();
    return snap.docs.map((d) => WarehouseLocationModel.fromDoc(d)).toList();
  }

  Future<String> upsertLocation(WarehouseLocationModel m) async {
    if (m.locationId.isEmpty) {
      final ref = await _locations.add(m.toMap());
      await _locations.doc(ref.id).update({'locationId': ref.id});
      return ref.id;
    } else {
      await _locations.doc(m.locationId).set(m.toMap(), SetOptions(merge: true));
      return m.locationId;
    }
  }

  Future<void> updateStockLocation({
    required String locationId,
    required int deltaQty,
  }) async {
    final ref = _locations.doc(locationId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data = doc.data() as Map<String, dynamic>;
      final current = (data['quantity'] ?? 0) as int;
      final next = current + deltaQty;
      if (next < 0) throw Exception('Stok lokasi tidak mencukupi');
      tx.update(ref, {'quantity': next});
    });
  }

  Future<WarehouseLocationModel?> findOptimalBin({
    required String warehouseId,
    required String productId,
    int requiredQty = 1,
  }) async {
    // Simple heuristic: choose bin with highest free capacity (mock: highest current quantity for same product)
    final snap = await _locations
        .where('warehouseId', isEqualTo: warehouseId)
        .where('productId', isEqualTo: productId)
        .orderBy('quantity', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return WarehouseLocationModel.fromDoc(snap.docs.first);
  }

  Future<List<WarehouseLocationModel>> getPickAndPackRoute({
    required String warehouseId,
    required List<String> productIdsInOrder,
  }) async {
    // Returns bins ordered by zone-rack-bin to minimize walking distance
    final snap = await _locations.where('warehouseId', isEqualTo: warehouseId).where('productId', whereIn: productIdsInOrder).get();
    final list = snap.docs.map((d) => WarehouseLocationModel.fromDoc(d)).toList();
    list.sort((a, b) {
      final ka = '${a.zone}:${a.rack}:${a.binCode}';
      final kb = '${b.zone}:${b.rack}:${b.binCode}';
      return ka.compareTo(kb);
    });
    return list;
  }
}
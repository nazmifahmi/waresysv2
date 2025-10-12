import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/warehouse_location_model.dart';

class WarehouseRepository {
  final FirebaseFirestore _firestore;
  WarehouseRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _warehouses => _firestore.collection('warehouses');

  Future<List<WarehouseModel>> getAll({String? search}) async {
    Query query = _warehouses.orderBy('name');
    if (search != null && search.trim().isNotEmpty) {
      query = _warehouses.where('nameLower', isGreaterThanOrEqualTo: search.toLowerCase())
                          .where('nameLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => WarehouseModel.fromDoc(d)).toList();
  }

  Stream<List<WarehouseModel>> watchAll() {
    return _warehouses.orderBy('name').snapshots().map((s) => s.docs.map((d) => WarehouseModel.fromDoc(d)).toList());
  }

  Future<WarehouseModel?> getById(String id) async {
    final doc = await _warehouses.doc(id).get();
    if (!doc.exists) return null;
    return WarehouseModel.fromDoc(doc);
  }

  Future<String> create(WarehouseModel warehouse) async {
    final ref = await _warehouses.add({
      ...warehouse.toMap(),
      'nameLower': warehouse.name.toLowerCase(),
    });
    await _warehouses.doc(ref.id).update({'warehouseId': ref.id});
    return ref.id;
  }

  Future<void> update(WarehouseModel warehouse) async {
    await _warehouses.doc(warehouse.warehouseId).update({
      ...warehouse.toMap(),
      'nameLower': warehouse.name.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _warehouses.doc(id).delete();
  }

  Future<void> updateStock({
    required String warehouseId,
    required int deltaStock,
  }) async {
    final ref = _warehouses.doc(warehouseId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data = doc.data() as Map<String, dynamic>;
      final current = (data['stockCount'] ?? 0) as int;
      final next = current + deltaStock;
      if (next < 0) throw Exception('Stock tidak mencukupi');
      tx.update(ref, {'stockCount': next});
    });
  }

  Future<List<WarehouseModel>> getLowStockWarehouses({double threshold = 0.2}) async {
    final snap = await _warehouses.get();
    return snap.docs
        .map((d) => WarehouseModel.fromDoc(d))
        .where((w) => w.stockCount / w.capacity < threshold)
        .toList();
  }
}
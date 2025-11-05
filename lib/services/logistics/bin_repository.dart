import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/bin_model.dart';
import '../../utils/volume_conversion.dart';

class BinRepository {
  final FirebaseFirestore _firestore;
  BinRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bins => _firestore.collection('warehouse_bins');
  CollectionReference<Map<String, dynamic>> get _items => _firestore.collection('inventory_items');
  CollectionReference<Map<String, dynamic>> get _products => _firestore.collection('products');

  Future<List<BinModel>> getByWarehouse(String warehouseId) async {
    final snap = await _bins.where('warehouseId', isEqualTo: warehouseId).orderBy('nameLower').get();
    return snap.docs.map((d) => BinModel.fromDoc(d)).toList();
  }

  Stream<List<BinModel>> watchByWarehouse(String warehouseId) {
    return _bins
        .where('warehouseId', isEqualTo: warehouseId)
        .orderBy('nameLower')
        .snapshots()
        .map((s) => s.docs.map((d) => BinModel.fromDoc(d)).toList());
  }

  Future<String> create(BinModel bin) async {
    final ref = await _bins.add({
      ...bin.toMap(),
      'nameLower': bin.name.toLowerCase(),
      'warehouseIdLower': bin.warehouseId.toLowerCase(),
    });
    await _bins.doc(ref.id).update({'binId': ref.id});
    return ref.id;
  }

  Future<void> update(BinModel bin) async {
    await _bins.doc(bin.binId).update({
      ...bin.toMap(),
      'nameLower': bin.name.toLowerCase(),
      'warehouseIdLower': bin.warehouseId.toLowerCase(),
    });
  }

  Future<void> delete(String binId) async {
    await _bins.doc(binId).delete();
  }

  // Hitung occupancy volume bin dalam m3
  Future<double> computeBinUsedVolumeM3(String warehouseId, String binId) async {
    final itemsSnap = await _items
        .where('warehouseId', isEqualTo: warehouseId)
        .where('binId', isEqualTo: binId)
        .get();
    double usedM3 = 0.0;
    for (final doc in itemsSnap.docs) {
      final data = doc.data();
      final qty = (data['onHand'] ?? 0) as int;
      final productId = data['productId'] as String?;
      if (productId == null || qty <= 0) continue;
      final prod = await _products.doc(productId).get();
      if (!prod.exists) continue;
      final p = prod.data()!;
      final unitVol = ((p['volumePerUnit'] ?? 0) as num).toDouble();
      final unit = p['volumeUnit'] ?? 'm3';
      final total = unitVol * qty;
      usedM3 += VolumeConversion.convert(total, from: unit, to: 'm3');
    }
    return usedM3;
  }

  // Hitung occupancy gudang: total used m3 / total capacity m3
  Future<Map<String, dynamic>> computeWarehouseOccupancy(String warehouseId) async {
    final bins = await getByWarehouse(warehouseId);
    double totalCapacityM3 = 0.0;
    double totalUsedM3 = 0.0;
    for (final b in bins) {
      final capM3 = VolumeConversion.convert(b.capacityVolume, from: b.capacityUnit, to: 'm3');
      totalCapacityM3 += capM3;
      final usedM3 = await computeBinUsedVolumeM3(warehouseId, b.binId);
      totalUsedM3 += usedM3;
    }
    final percent = totalCapacityM3 > 0 ? (totalUsedM3 / totalCapacityM3) : 0.0;
    return {
      'warehouseId': warehouseId,
      'totalCapacityM3': totalCapacityM3,
      'totalUsedM3': totalUsedM3,
      'percent': percent,
    };
  }
}
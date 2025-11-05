import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/inventory_item_model.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore;
  InventoryRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items => _firestore.collection('inventory_items');

  // --------- Operasi berbasis BIN ---------
  Future<InventoryItemModel?> getItemInBin(String warehouseId, String binId, String productId) async {
    final snap = await _items
        .where('warehouseId', isEqualTo: warehouseId)
        .where('binId', isEqualTo: binId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InventoryItemModel.fromDoc(snap.docs.first);
  }

  Future<String> upsertItemInBin({
    required String warehouseId,
    required String binId,
    required String productId,
    required int onHand,
    required int reserved,
  }) async {
    final existing = await getItemInBin(warehouseId, binId, productId);
    if (existing == null) {
      final ref = await _items.add({
        'warehouseId': warehouseId,
        'binId': binId,
        'productId': productId,
        'onHand': onHand,
        'reserved': reserved,
        'updatedAt': FieldValue.serverTimestamp(),
        'warehouseIdLower': warehouseId.toLowerCase(),
        'binIdLower': binId.toLowerCase(),
        'productIdLower': productId.toLowerCase(),
      });
      await _items.doc(ref.id).update({'inventoryId': ref.id});
      return ref.id;
    } else {
      await _items.doc(existing.inventoryId).update({
        'onHand': onHand,
        'reserved': reserved,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return existing.inventoryId;
    }
  }

  Future<void> receiveStockInBin({
    required String warehouseId,
    required String binId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('binId', isEqualTo: binId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      DocumentReference? ref;
      Map<String, dynamic> data = {};
      if (q.docs.isEmpty) {
        ref = await _items.add({
          'warehouseId': warehouseId,
          'binId': binId,
          'productId': productId,
          'onHand': 0,
          'reserved': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'warehouseIdLower': warehouseId.toLowerCase(),
          'binIdLower': binId.toLowerCase(),
          'productIdLower': productId.toLowerCase(),
        });
        await _items.doc(ref.id).update({'inventoryId': ref.id});
        data = {'onHand': 0, 'reserved': 0};
      } else {
        ref = q.docs.first.reference;
        data = q.docs.first.data();
      }
      final onHand = (data['onHand'] ?? 0) as int;
      tx.update(ref!, {
        'onHand': onHand + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> issueStockInBin({
    required String warehouseId,
    required String binId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('binId', isEqualTo: binId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) throw Exception('Item inventory tidak ditemukan di bin');
      final ref = q.docs.first.reference;
      final data = q.docs.first.data();
      final onHand = (data['onHand'] ?? 0) as int;
      final reserved = (data['reserved'] ?? 0) as int;
      final available = onHand - reserved;
      if (available < quantity) throw Exception('Stok tidak mencukupi di bin');
      tx.update(ref, {
        'onHand': onHand - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> transferStockBetweenBins({
    required String warehouseId,
    required String fromBinId,
    required String toBinId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      // Reduce from source bin
      final srcQ = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('binId', isEqualTo: fromBinId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      if (srcQ.docs.isEmpty) throw Exception('Stok sumber tidak ditemukan pada bin');
      final srcRef = srcQ.docs.first.reference;
      final srcData = srcQ.docs.first.data();
      final srcOnHand = (srcData['onHand'] ?? 0) as int;
      final srcReserved = (srcData['reserved'] ?? 0) as int;
      if (srcOnHand - srcReserved < quantity) throw Exception('Stok tersedia sumber tidak cukup di bin');
      tx.update(srcRef, {
        'onHand': srcOnHand - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to destination bin
      final dstQ = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('binId', isEqualTo: toBinId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      DocumentReference? dstRef;
      Map<String, dynamic> dstData = {};
      if (dstQ.docs.isEmpty) {
        dstRef = await _items.add({
          'warehouseId': warehouseId,
          'binId': toBinId,
          'productId': productId,
          'onHand': 0,
          'reserved': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'warehouseIdLower': warehouseId.toLowerCase(),
          'binIdLower': toBinId.toLowerCase(),
          'productIdLower': productId.toLowerCase(),
        });
        await _items.doc(dstRef.id).update({'inventoryId': dstRef.id});
        dstData = {'onHand': 0, 'reserved': 0};
      } else {
        dstRef = dstQ.docs.first.reference;
        dstData = dstQ.docs.first.data();
      }
      final dstOnHand = (dstData['onHand'] ?? 0) as int;
      tx.update(dstRef!, {
        'onHand': dstOnHand + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<InventoryItemModel?> getItem(String warehouseId, String productId) async {
    final snap = await _items
        .where('warehouseId', isEqualTo: warehouseId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InventoryItemModel.fromDoc(snap.docs.first);
  }

  Future<String> upsertItem({
    required String warehouseId,
    required String productId,
    required int onHand,
    required int reserved,
  }) async {
    final existing = await getItem(warehouseId, productId);
    if (existing == null) {
      final ref = await _items.add({
        'warehouseId': warehouseId,
        'productId': productId,
        'onHand': onHand,
        'reserved': reserved,
        'updatedAt': FieldValue.serverTimestamp(),
        'warehouseIdLower': warehouseId.toLowerCase(),
        'productIdLower': productId.toLowerCase(),
      });
      await _items.doc(ref.id).update({'inventoryId': ref.id});
      return ref.id;
    } else {
      await _items.doc(existing.inventoryId).update({
        'onHand': onHand,
        'reserved': reserved,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return existing.inventoryId;
    }
  }

  Future<void> reserveStock({
    required String warehouseId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      DocumentReference? ref;
      Map<String, dynamic> data = {};
      if (q.docs.isEmpty) {
        ref = await _items.add({
          'warehouseId': warehouseId,
          'productId': productId,
          'onHand': 0,
          'reserved': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'warehouseIdLower': warehouseId.toLowerCase(),
          'productIdLower': productId.toLowerCase(),
        });
        await _items.doc(ref.id).update({'inventoryId': ref.id});
        data = {
          'onHand': 0,
          'reserved': 0,
        };
      } else {
        ref = q.docs.first.reference;
        data = q.docs.first.data();
      }
      final onHand = (data['onHand'] ?? 0) as int;
      final reserved = (data['reserved'] ?? 0) as int;
      final available = onHand - reserved;
      if (available < quantity) {
        throw Exception('Stok tidak mencukupi untuk reservasi');
      }
      tx.update(ref!, {
        'reserved': reserved + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> releaseReservation({
    required String warehouseId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return;
      final ref = q.docs.first.reference;
      final data = q.docs.first.data();
      final reserved = (data['reserved'] ?? 0) as int;
      final next = reserved - quantity;
      tx.update(ref, {
        'reserved': next < 0 ? 0 : next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> consumeReservedOnShipping({
    required String warehouseId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) throw Exception('Item inventory tidak ditemukan');
      final ref = q.docs.first.reference;
      final data = q.docs.first.data();
      final onHand = (data['onHand'] ?? 0) as int;
      final reserved = (data['reserved'] ?? 0) as int;
      if (reserved < quantity) throw Exception('Reserved tidak mencukupi');
      final nextOnHand = onHand - quantity;
      if (nextOnHand < 0) throw Exception('OnHand tidak mencukupi');
      tx.update(ref, {
        'onHand': nextOnHand,
        'reserved': reserved - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> receiveStock({
    required String warehouseId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      DocumentReference? ref;
      Map<String, dynamic> data = {};
      if (q.docs.isEmpty) {
        ref = await _items.add({
          'warehouseId': warehouseId,
          'productId': productId,
          'onHand': 0,
          'reserved': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'warehouseIdLower': warehouseId.toLowerCase(),
          'productIdLower': productId.toLowerCase(),
        });
        await _items.doc(ref.id).update({'inventoryId': ref.id});
        data = {'onHand': 0, 'reserved': 0};
      } else {
        ref = q.docs.first.reference;
        data = q.docs.first.data();
      }
      final onHand = (data['onHand'] ?? 0) as int;
      tx.update(ref!, {
        'onHand': onHand + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> issueStock({
    required String warehouseId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      final q = await _items
          .where('warehouseId', isEqualTo: warehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) throw Exception('Item inventory tidak ditemukan');
      final ref = q.docs.first.reference;
      final data = q.docs.first.data();
      final onHand = (data['onHand'] ?? 0) as int;
      final reserved = (data['reserved'] ?? 0) as int;
      final available = onHand - reserved;
      if (available < quantity) throw Exception('Stok tidak mencukupi');
      tx.update(ref, {
        'onHand': onHand - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> transferStock({
    required String fromWarehouseId,
    required String toWarehouseId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    await _firestore.runTransaction((tx) async {
      // Reduce from source
      final srcQ = await _items
          .where('warehouseId', isEqualTo: fromWarehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      if (srcQ.docs.isEmpty) throw Exception('Stok sumber tidak ditemukan');
      final srcRef = srcQ.docs.first.reference;
      final srcData = srcQ.docs.first.data();
      final srcOnHand = (srcData['onHand'] ?? 0) as int;
      final srcReserved = (srcData['reserved'] ?? 0) as int;
      if (srcOnHand - srcReserved < quantity) throw Exception('Stok tersedia sumber tidak cukup');
      tx.update(srcRef, {
        'onHand': srcOnHand - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to destination
      final dstQ = await _items
          .where('warehouseId', isEqualTo: toWarehouseId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      DocumentReference? dstRef;
      Map<String, dynamic> dstData = {};
      if (dstQ.docs.isEmpty) {
        dstRef = await _items.add({
          'warehouseId': toWarehouseId,
          'productId': productId,
          'onHand': 0,
          'reserved': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'warehouseIdLower': toWarehouseId.toLowerCase(),
          'productIdLower': productId.toLowerCase(),
        });
        await _items.doc(dstRef.id).update({'inventoryId': dstRef.id});
        dstData = {'onHand': 0, 'reserved': 0};
      } else {
        dstRef = dstQ.docs.first.reference;
        dstData = dstQ.docs.first.data();
      }
      final dstOnHand = (dstData['onHand'] ?? 0) as int;
      tx.update(dstRef!, {
        'onHand': dstOnHand + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
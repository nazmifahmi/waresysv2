import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String inventoryId;
  final String warehouseId;
  final String? binId;
  final String productId;
  final int onHand;
  final int reserved;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.inventoryId,
    required this.warehouseId,
    this.binId,
    required this.productId,
    required this.onHand,
    required this.reserved,
    required this.updatedAt,
  }) : assert(warehouseId.isNotEmpty, 'warehouseId harus diisi'),
       assert(productId.isNotEmpty, 'productId harus diisi'),
       assert(onHand >= 0, 'onHand tidak boleh negatif'),
       assert(reserved >= 0, 'reserved tidak boleh negatif');

  int get available => onHand - reserved;

  Map<String, dynamic> toMap() => {
        'inventoryId': inventoryId,
        'warehouseId': warehouseId,
        if (binId != null) 'binId': binId,
        'productId': productId,
        'onHand': onHand,
        'reserved': reserved,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'warehouseIdLower': warehouseId.toLowerCase(),
        if (binId != null) 'binIdLower': binId!.toLowerCase(),
        'productIdLower': productId.toLowerCase(),
      };

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) => InventoryItemModel(
        inventoryId: map['inventoryId'] ?? '',
        warehouseId: map['warehouseId'] ?? '',
        binId: map['binId'],
        productId: map['productId'] ?? '',
        onHand: (map['onHand'] ?? 0) as int,
        reserved: (map['reserved'] ?? 0) as int,
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory InventoryItemModel.fromDoc(DocumentSnapshot doc) =>
      InventoryItemModel.fromMap({...doc.data() as Map<String, dynamic>, 'inventoryId': doc.id});
}
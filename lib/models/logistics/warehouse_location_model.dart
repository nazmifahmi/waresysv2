
import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseLocationModel {
  final String locationId;
  final String warehouseId;
  final String zone;
  final String rack;
  final String binCode;
  final String productId;
  final int quantity;

  WarehouseLocationModel({
    required this.locationId,
    required this.warehouseId,
    required this.zone,
    required this.rack,
    required this.binCode,
    required this.productId,
    required this.quantity,
  }) : assert(quantity >= 0);

  Map<String, dynamic> toMap() => {
        'locationId': locationId,
        'warehouseId': warehouseId,
        'zone': zone,
        'rack': rack,
        'binCode': binCode,
        'productId': productId,
        'quantity': quantity,
        'binKey': '$warehouseId|$zone|$rack|$binCode',
      };

  factory WarehouseLocationModel.fromMap(Map<String, dynamic> map) => WarehouseLocationModel(
        locationId: map['locationId'],
        warehouseId: map['warehouseId'],
        zone: map['zone'],
        rack: map['rack'],
        binCode: map['binCode'],
        productId: map['productId'],
        quantity: (map['quantity'] ?? 0) as int,
      );

  factory WarehouseLocationModel.fromDoc(DocumentSnapshot doc) =>
      WarehouseLocationModel.fromMap({...doc.data() as Map<String, dynamic>, 'locationId': doc.id});
}

import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseModel {
  final String warehouseId;
  final String name;
  final String location;
  final int stockCount;
  final int capacity;

  WarehouseModel({
    required this.warehouseId,
    required this.name,
    required this.location,
    required this.stockCount,
    required this.capacity,
  }) : assert(warehouseId.isNotEmpty, 'warehouseId cannot be empty'),
       assert(name.isNotEmpty, 'name cannot be empty'),
       assert(location.isNotEmpty, 'location cannot be empty'),
       assert(stockCount >= 0, 'stockCount must be >= 0'),
       assert(capacity > 0, 'capacity must be greater than 0');

  Map<String, dynamic> toMap() => {
        'warehouseId': warehouseId,
        'name': name,
        'location': location,
        'stockCount': stockCount,
        'capacity': capacity,
        'nameLower': name.toLowerCase(),
      };

  factory WarehouseModel.fromMap(Map<String, dynamic> map) => WarehouseModel(
        warehouseId: map['warehouseId'],
        name: map['name'],
        location: map['location'],
        stockCount: (map['stockCount'] ?? 0) as int,
        capacity: (map['capacity'] ?? 0) as int,
      );

  factory WarehouseModel.fromDoc(DocumentSnapshot doc) =>
      WarehouseModel.fromMap({...doc.data() as Map<String, dynamic>, 'warehouseId': doc.id});
}
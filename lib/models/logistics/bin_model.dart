import 'package:cloud_firestore/cloud_firestore.dart';

class BinModel {
  final String binId;
  final String warehouseId;
  final String name; // kode/nama bin
  final double capacityVolume; // kapasitas bin dalam satuan capacityUnit
  final String capacityUnit; // m3, liter, cm3, ft3
  final DateTime createdAt;
  final DateTime? updatedAt;

  BinModel({
    required this.binId,
    required this.warehouseId,
    required this.name,
    required this.capacityVolume,
    required this.capacityUnit,
    required this.createdAt,
    this.updatedAt,
  }) : assert(warehouseId.isNotEmpty, 'warehouseId harus diisi'),
       assert(name.isNotEmpty, 'name bin harus diisi'),
       assert(capacityVolume >= 0, 'capacityVolume tidak boleh negatif');

  Map<String, dynamic> toMap() => {
        'binId': binId,
        'warehouseId': warehouseId,
        'name': name,
        'capacityVolume': capacityVolume,
        'capacityUnit': capacityUnit,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'nameLower': name.toLowerCase(),
        'warehouseIdLower': warehouseId.toLowerCase(),
      };

  factory BinModel.fromMap(Map<String, dynamic> map) => BinModel(
        binId: map['binId'] ?? '',
        warehouseId: map['warehouseId'] ?? '',
        name: map['name'] ?? '',
        capacityVolume: ((map['capacityVolume'] ?? 0) as num).toDouble(),
        capacityUnit: map['capacityUnit'] ?? 'm3',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  factory BinModel.fromDoc(DocumentSnapshot doc) =>
      BinModel.fromMap({...doc.data() as Map<String, dynamic>, 'binId': doc.id});
}
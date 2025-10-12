import 'package:cloud_firestore/cloud_firestore.dart';

enum ShipmentStatus { pending, inTransit, delivered, cancelled }

class ShipmentModel {
  final String shipmentId;
  final String trackingNumber;
  final String origin;
  final String destination;
  final String carrier;
  final ShipmentStatus status;
  final double cost;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShipmentModel({
    required this.shipmentId,
    required this.trackingNumber,
    required this.origin,
    required this.destination,
    required this.carrier,
    required this.status,
    required this.cost,
    required this.createdAt,
    this.updatedAt,
  }) : assert(shipmentId.isNotEmpty, 'shipmentId cannot be empty'),
       assert(trackingNumber.isNotEmpty, 'trackingNumber cannot be empty'),
       assert(origin.isNotEmpty, 'origin cannot be empty'),
       assert(destination.isNotEmpty, 'destination cannot be empty'),
       assert(carrier.isNotEmpty, 'carrier cannot be empty'),
       assert(cost >= 0, 'cost must be >= 0');

  Map<String, dynamic> toMap() => {
        'shipmentId': shipmentId,
        'trackingNumber': trackingNumber,
        'origin': origin,
        'destination': destination,
        'carrier': carrier,
        'status': status.name,
        'cost': cost,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory ShipmentModel.fromMap(Map<String, dynamic> map) => ShipmentModel(
        shipmentId: map['shipmentId'] ?? '',
        trackingNumber: map['trackingNumber'] ?? '',
        origin: map['origin'] ?? '',
        destination: map['destination'] ?? '',
        carrier: map['carrier'] ?? '',
        status: ShipmentStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ShipmentStatus.pending,
        ),
        cost: (map['cost'] ?? 0).toDouble(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  factory ShipmentModel.fromDoc(DocumentSnapshot doc) =>
      ShipmentModel.fromMap({...doc.data() as Map<String, dynamic>, 'shipmentId': doc.id});
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleStatus { AVAILABLE, ON_DUTY, MAINTENANCE }

class FleetModel {
  final String fleetId;
  final String vehicleNumber;
  final String driverName;
  final double capacity;
  final VehicleStatus status;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;

  FleetModel({
    required this.fleetId,
    required this.vehicleNumber,
    required this.driverName,
    required this.capacity,
    this.status = VehicleStatus.AVAILABLE,
    this.lastServiceDate,
    this.nextServiceDate,
  }) : assert(vehicleNumber.isNotEmpty, 'vehicleNumber cannot be empty'),
       assert(driverName.isNotEmpty, 'driverName cannot be empty'),
       assert(capacity > 0, 'capacity must be greater than 0');

  Map<String, dynamic> toMap() => {
        'fleetId': fleetId,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'capacity': capacity,
        'status': status.name,
        'lastServiceDate': lastServiceDate != null ? Timestamp.fromDate(lastServiceDate!) : null,
        'nextServiceDate': nextServiceDate != null ? Timestamp.fromDate(nextServiceDate!) : null,
      };

  factory FleetModel.fromMap(Map<String, dynamic> map) => FleetModel(
        fleetId: map['fleetId'],
        vehicleNumber: map['vehicleNumber'],
        driverName: map['driverName'],
        capacity: (map['capacity'] as num).toDouble(),
        status: VehicleStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => VehicleStatus.AVAILABLE),
        lastServiceDate: (map['lastServiceDate'] as Timestamp?)?.toDate(),
        nextServiceDate: (map['nextServiceDate'] as Timestamp?)?.toDate(),
      );

  factory FleetModel.fromDoc(DocumentSnapshot doc) =>
      FleetModel.fromMap({...doc.data() as Map<String, dynamic>, 'fleetId': doc.id});
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleStatus { AVAILABLE, ON_DUTY, MAINTENANCE }

class FleetVehicleModel {
  final String vehicleId;
  final String licensePlate;
  final String model;
  final VehicleStatus status;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;

  FleetVehicleModel({
    required this.vehicleId,
    required this.licensePlate,
    required this.model,
    this.status = VehicleStatus.AVAILABLE,
    this.lastServiceDate,
    this.nextServiceDate,
  });

  Map<String, dynamic> toMap() => {
        'vehicleId': vehicleId,
        'licensePlate': licensePlate,
        'model': model,
        'status': status.name,
        'lastServiceDate': lastServiceDate != null ? Timestamp.fromDate(lastServiceDate!) : null,
        'nextServiceDate': nextServiceDate != null ? Timestamp.fromDate(nextServiceDate!) : null,
      };

  factory FleetVehicleModel.fromMap(Map<String, dynamic> map) => FleetVehicleModel(
        vehicleId: map['vehicleId'],
        licensePlate: map['licensePlate'],
        model: map['model'],
        status: VehicleStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => VehicleStatus.AVAILABLE),
        lastServiceDate: (map['lastServiceDate'] as Timestamp?)?.toDate(),
        nextServiceDate: (map['nextServiceDate'] as Timestamp?)?.toDate(),
      );

  factory FleetVehicleModel.fromDoc(DocumentSnapshot doc) =>
      FleetVehicleModel.fromMap({...doc.data() as Map<String, dynamic>, 'vehicleId': doc.id});
}
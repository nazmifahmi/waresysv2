import 'package:cloud_firestore/cloud_firestore.dart';

class FleetRouteModel {
  final String routeId;
  final String deliveryOrderId;
  final String vehicleId;
  final String driverId; // EmployeeModel.id
  final DateTime departureTime;
  final DateTime estimatedArrivalTime;
  final GeoPoint? currentLocation;

  FleetRouteModel({
    required this.routeId,
    required this.deliveryOrderId,
    required this.vehicleId,
    required this.driverId,
    required this.departureTime,
    required this.estimatedArrivalTime,
    this.currentLocation,
  });

  Map<String, dynamic> toMap() => {
        'routeId': routeId,
        'deliveryOrderId': deliveryOrderId,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'departureTime': Timestamp.fromDate(departureTime),
        'estimatedArrivalTime': Timestamp.fromDate(estimatedArrivalTime),
        'currentLocation': currentLocation,
      };

  factory FleetRouteModel.fromMap(Map<String, dynamic> map) => FleetRouteModel(
        routeId: map['routeId'],
        deliveryOrderId: map['deliveryOrderId'],
        vehicleId: map['vehicleId'],
        driverId: map['driverId'],
        departureTime: (map['departureTime'] as Timestamp).toDate(),
        estimatedArrivalTime: (map['estimatedArrivalTime'] as Timestamp).toDate(),
        currentLocation: map['currentLocation'],
      );

  factory FleetRouteModel.fromDoc(DocumentSnapshot doc) =>
      FleetRouteModel.fromMap({...doc.data() as Map<String, dynamic>, 'routeId': doc.id});
}
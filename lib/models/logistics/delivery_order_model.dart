import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus { PENDING, PACKING, SHIPPED, DELIVERED }

class DeliveryOrderModel {
  final String deliveryId;
  final String salesOrderId;
  final DeliveryStatus status;
  final String? courierName;
  final String? trackingNumber;
  final String? shippingLabelUrl;

  DeliveryOrderModel({
    required this.deliveryId,
    required this.salesOrderId,
    this.status = DeliveryStatus.PENDING,
    this.courierName,
    this.trackingNumber,
    this.shippingLabelUrl,
  });

  Map<String, dynamic> toMap() => {
        'deliveryId': deliveryId,
        'salesOrderId': salesOrderId,
        'status': status.name,
        'courierName': courierName,
        'trackingNumber': trackingNumber,
        'shippingLabelUrl': shippingLabelUrl,
      };

  factory DeliveryOrderModel.fromMap(Map<String, dynamic> map) => DeliveryOrderModel(
        deliveryId: map['deliveryId'],
        salesOrderId: map['salesOrderId'],
        status: DeliveryStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => DeliveryStatus.PENDING),
        courierName: map['courierName'],
        trackingNumber: map['trackingNumber'],
        shippingLabelUrl: map['shippingLabelUrl'],
      );

  factory DeliveryOrderModel.fromDoc(DocumentSnapshot doc) =>
      DeliveryOrderModel.fromMap({...doc.data() as Map<String, dynamic>, 'deliveryId': doc.id});
}
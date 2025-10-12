import 'package:cloud_firestore/cloud_firestore.dart';

class SalesModel {
  final String salesId;
  final String customerId;
  final String productName;
  final int quantity;
  final double totalPrice;
  final DateTime date;

  SalesModel({
    required this.salesId,
    required this.customerId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.date,
  }) : assert(salesId.isNotEmpty, 'salesId cannot be empty'),
       assert(customerId.isNotEmpty, 'customerId cannot be empty'),
       assert(productName.isNotEmpty, 'productName cannot be empty'),
       assert(quantity > 0, 'quantity must be greater than 0'),
       assert(totalPrice >= 0, 'totalPrice must be >= 0');

  Map<String, dynamic> toMap() => {
        'salesId': salesId,
        'customerId': customerId,
        'productName': productName,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'date': Timestamp.fromDate(date),
        'productNameLower': productName.toLowerCase(),
      };

  factory SalesModel.fromMap(Map<String, dynamic> map) => SalesModel(
        salesId: map['salesId'],
        customerId: map['customerId'],
        productName: map['productName'],
        quantity: (map['quantity'] as num).toInt(),
        totalPrice: (map['totalPrice'] as num).toDouble(),
        date: (map['date'] as Timestamp).toDate(),
      );

  factory SalesModel.fromDoc(DocumentSnapshot doc) =>
      SalesModel.fromMap({...doc.data() as Map<String, dynamic>, 'salesId': doc.id});
}
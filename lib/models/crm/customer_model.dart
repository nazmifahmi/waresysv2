import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerStatus { active, inactive }

class CustomerModel {
  final String customerId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime joinedDate;
  final CustomerStatus status;

  CustomerModel({
    required this.customerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.joinedDate,
    this.status = CustomerStatus.active,
  }) : assert(customerId.isNotEmpty, 'customerId cannot be empty'),
       assert(name.isNotEmpty, 'name cannot be empty'),
       assert(email.isNotEmpty, 'email cannot be empty'),
       assert(phone.isNotEmpty, 'phone cannot be empty'),
       assert(address.isNotEmpty, 'address cannot be empty');

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'joinedDate': Timestamp.fromDate(joinedDate),
        'status': status.name,
        'nameLower': name.toLowerCase(),
      };

  factory CustomerModel.fromMap(Map<String, dynamic> map) => CustomerModel(
        customerId: map['customerId'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        address: map['address'],
        joinedDate: (map['joinedDate'] as Timestamp).toDate(),
        status: CustomerStatus.values.firstWhere(
          (e) => e.name == (map['status'] ?? CustomerStatus.active.name),
          orElse: () => CustomerStatus.active,
        ),
      );

  factory CustomerModel.fromDoc(DocumentSnapshot doc) =>
      CustomerModel.fromMap({...doc.data() as Map<String, dynamic>, 'customerId': doc.id});
}
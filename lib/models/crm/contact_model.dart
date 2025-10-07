import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  final String contactId;
  final String name;
  final String? email;
  final String? phone;
  final String? position;
  final String? companyId;

  ContactModel({
    required this.contactId,
    required this.name,
    this.email,
    this.phone,
    this.position,
    this.companyId,
  }) : assert(contactId.isNotEmpty),
       assert(name.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'contactId': contactId,
        'name': name,
        'email': email,
        'phone': phone,
        'position': position,
        'companyId': companyId,
        'nameLower': name.toLowerCase(),
      };

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
        contactId: map['contactId'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        position: map['position'],
        companyId: map['companyId'],
      );

  factory ContactModel.fromDoc(DocumentSnapshot doc) =>
      ContactModel.fromMap({...doc.data() as Map<String, dynamic>, 'contactId': doc.id});
}



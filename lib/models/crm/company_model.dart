import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String companyId;
  final String name;
  final String? address;
  final String? website;
  final String? industry;

  CompanyModel({
    required this.companyId,
    required this.name,
    this.address,
    this.website,
    this.industry,
  }) : assert(companyId.isNotEmpty), assert(name.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'name': name,
        'address': address,
        'website': website,
        'industry': industry,
        'nameLower': name.toLowerCase(),
      };

  factory CompanyModel.fromMap(Map<String, dynamic> map) => CompanyModel(
        companyId: map['companyId'],
        name: map['name'],
        address: map['address'],
        website: map['website'],
        industry: map['industry'],
      );

  factory CompanyModel.fromDoc(DocumentSnapshot doc) =>
      CompanyModel.fromMap({...doc.data() as Map<String, dynamic>, 'companyId': doc.id});
}



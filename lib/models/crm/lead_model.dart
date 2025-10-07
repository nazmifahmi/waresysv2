import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadStatus { NEW, CONTACTED, QUALIFIED, CLOSED_WON, CLOSED_LOST }

class LeadModel {
  final String leadId;
  final String leadName;
  final String? companyName;
  final String? source;
  final LeadStatus status;
  final String? assignedTo; // userId
  final double? estimatedValue;

  LeadModel({
    required this.leadId,
    required this.leadName,
    this.companyName,
    this.source,
    this.status = LeadStatus.NEW,
    this.assignedTo,
    this.estimatedValue,
  }) : assert(leadId.isNotEmpty),
       assert(leadName.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'leadId': leadId,
        'leadName': leadName,
        'companyName': companyName,
        'source': source,
        'status': status.name,
        'assignedTo': assignedTo,
        'estimatedValue': estimatedValue,
        'leadNameLower': leadName.toLowerCase(),
      };

  factory LeadModel.fromMap(Map<String, dynamic> map) => LeadModel(
        leadId: map['leadId'],
        leadName: map['leadName'],
        companyName: map['companyName'],
        source: map['source'],
        status: LeadStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => LeadStatus.NEW),
        assignedTo: map['assignedTo'],
        estimatedValue: (map['estimatedValue'] as num?)?.toDouble(),
      );

  factory LeadModel.fromDoc(DocumentSnapshot doc) =>
      LeadModel.fromMap({...doc.data() as Map<String, dynamic>, 'leadId': doc.id});
}



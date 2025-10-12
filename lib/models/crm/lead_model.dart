import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadStatus { NEW, CONTACTED, QUALIFIED, CLOSED_WON, CLOSED_LOST }

class LeadModel {
  final String leadId;
  final String source;
  final String interestLevel;
  final String notes;
  final LeadStatus status;
  final String? assignedTo; // userId
  final double? estimatedValue;

  LeadModel({
    required this.leadId,
    required this.source,
    required this.interestLevel,
    required this.notes,
    this.status = LeadStatus.NEW,
    this.assignedTo,
    this.estimatedValue,
  }) : assert(leadId.isNotEmpty),
       assert(source.isNotEmpty),
       assert(interestLevel.isNotEmpty),
       assert(notes.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'leadId': leadId,
        'source': source,
        'interestLevel': interestLevel,
        'notes': notes,
        'status': status.name,
        'assignedTo': assignedTo,
        'estimatedValue': estimatedValue,
      };

  factory LeadModel.fromMap(Map<String, dynamic> map) => LeadModel(
        leadId: map['leadId'],
        source: map['source'],
        interestLevel: map['interestLevel'],
        notes: map['notes'],
        status: LeadStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => LeadStatus.NEW),
        assignedTo: map['assignedTo'],
        estimatedValue: (map['estimatedValue'] as num?)?.toDouble(),
      );

  factory LeadModel.fromDoc(DocumentSnapshot doc) =>
      LeadModel.fromMap({...doc.data() as Map<String, dynamic>, 'leadId': doc.id});
}



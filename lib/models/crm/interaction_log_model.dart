import 'package:cloud_firestore/cloud_firestore.dart';

enum InteractionType { CALL, EMAIL, MEETING }

class InteractionLogModel {
  final String logId;
  final String contactId;
  final DateTime timestamp;
  final InteractionType type;
  final String? notes;

  InteractionLogModel({
    required this.logId,
    required this.contactId,
    required this.timestamp,
    required this.type,
    this.notes,
  }) : assert(logId.isNotEmpty), assert(contactId.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'logId': logId,
        'contactId': contactId,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type.name,
        'notes': notes,
      };

  factory InteractionLogModel.fromMap(Map<String, dynamic> map) => InteractionLogModel(
        logId: map['logId'],
        contactId: map['contactId'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        type: InteractionType.values.firstWhere((e) => e.name == map['type']),
        notes: map['notes'],
      );

  factory InteractionLogModel.fromDoc(DocumentSnapshot doc) => InteractionLogModel.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'logId': doc.id,
      });
}



import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { TASK, MEETING }
enum ActivityStatus { SCHEDULED, COMPLETED }

class ActivityModel {
  final String activityId;
  final String title;
  final String? description;
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? relatedToContactId;
  final ActivityStatus status;

  ActivityModel({
    required this.activityId,
    required this.title,
    this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.relatedToContactId,
    this.status = ActivityStatus.SCHEDULED,
  }) : assert(activityId.isNotEmpty), assert(title.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'activityId': activityId,
        'title': title,
        'description': description,
        'type': type.name,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'relatedToContactId': relatedToContactId,
        'status': status.name,
      };

  factory ActivityModel.fromMap(Map<String, dynamic> map) => ActivityModel(
        activityId: map['activityId'],
        title: map['title'],
        description: map['description'],
        type: ActivityType.values.firstWhere((e) => e.name == map['type']),
        startTime: (map['startTime'] as Timestamp).toDate(),
        endTime: (map['endTime'] as Timestamp).toDate(),
        relatedToContactId: map['relatedToContactId'],
        status: ActivityStatus.values.firstWhere((e) => e.name == map['status']),
      );

  factory ActivityModel.fromDoc(DocumentSnapshot doc) =>
      ActivityModel.fromMap({...doc.data() as Map<String, dynamic>, 'activityId': doc.id});
}



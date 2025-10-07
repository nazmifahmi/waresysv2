import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveStatus { pending, approved, rejected }

class LeaveRequestModel {
  final String requestId;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;

  LeaveRequestModel({
    required this.requestId,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
  }) : assert(requestId.isNotEmpty, 'requestId cannot be empty'),
       assert(employeeId.isNotEmpty, 'employeeId cannot be empty'),
       assert(reason.isNotEmpty, 'reason cannot be empty');

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'employeeId': employeeId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'status': status.name,
      };

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) => LeaveRequestModel(
        requestId: map['requestId'],
        employeeId: map['employeeId'],
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        reason: map['reason'],
        status: LeaveStatus.values.firstWhere((e) => e.name == map['status']),
      );

  factory LeaveRequestModel.fromDoc(DocumentSnapshot doc) =>
      LeaveRequestModel.fromMap({...doc.data() as Map<String, dynamic>, 'requestId': doc.id});
}
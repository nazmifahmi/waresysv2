import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveStatus { pending, approved, rejected }
enum LeaveType { annual, sick, emergency, maternity, paternity, lainnya }

class LeaveRequestModel {
  final String requestId;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final LeaveType leaveType;
  final DateTime submissionDate;
  final String? approvedBy;
  final DateTime? approvalDate;

  LeaveRequestModel({
    required this.requestId,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    required this.leaveType,
    required this.submissionDate,
    this.approvedBy,
    this.approvalDate,
  }) : assert(reason.isNotEmpty, 'reason cannot be empty');

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'employeeId': employeeId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'status': status.name,
        'leaveType': leaveType.name,
        'submissionDate': Timestamp.fromDate(submissionDate),
        'approvedBy': approvedBy,
        'approvalDate': approvalDate != null ? Timestamp.fromDate(approvalDate!) : null,
      };

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) => LeaveRequestModel(
        requestId: map['requestId'],
        employeeId: map['employeeId'],
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        reason: map['reason'],
        status: LeaveStatus.values.firstWhere(
          (e) => e.name == (map['status'] ?? LeaveStatus.pending.name),
          orElse: () => LeaveStatus.pending,
        ),
        leaveType: LeaveType.values.firstWhere(
          (e) => e.name == (map['leaveType'] ?? LeaveType.annual.name),
          orElse: () => LeaveType.annual,
        ),
        submissionDate: (map['submissionDate'] as Timestamp).toDate(),
        approvedBy: map['approvedBy'],
        approvalDate: (map['approvalDate'] as Timestamp?)?.toDate(),
      );

  factory LeaveRequestModel.fromDoc(DocumentSnapshot doc) =>
      LeaveRequestModel.fromMap({...doc.data() as Map<String, dynamic>, 'requestId': doc.id});
}
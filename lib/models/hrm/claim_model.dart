import 'package:cloud_firestore/cloud_firestore.dart';

enum ClaimStatus { pending, approved, rejected }

class ClaimModel {
  final String claimId;
  final String employeeId;
  final DateTime submissionDate;
  final String description;
  final double amount;
  final String? receiptImageUrl;
  final ClaimStatus status;

  ClaimModel({
    required this.claimId,
    required this.employeeId,
    required this.submissionDate,
    required this.description,
    required this.amount,
    this.receiptImageUrl,
    this.status = ClaimStatus.pending,
  }) : assert(claimId.isNotEmpty),
       assert(employeeId.isNotEmpty),
       assert(description.isNotEmpty),
       assert(amount >= 0);

  Map<String, dynamic> toMap() => {
        'claimId': claimId,
        'employeeId': employeeId,
        'submissionDate': Timestamp.fromDate(submissionDate),
        'description': description,
        'amount': amount,
        'receiptImageUrl': receiptImageUrl,
        'status': status.name,
      };

  factory ClaimModel.fromMap(Map<String, dynamic> map) => ClaimModel(
        claimId: map['claimId'],
        employeeId: map['employeeId'],
        submissionDate: (map['submissionDate'] as Timestamp).toDate(),
        description: map['description'],
        amount: (map['amount'] as num).toDouble(),
        receiptImageUrl: map['receiptImageUrl'],
        status: ClaimStatus.values.firstWhere((e) => e.name == map['status']),
      );

  factory ClaimModel.fromDoc(DocumentSnapshot doc) =>
      ClaimModel.fromMap({...doc.data() as Map<String, dynamic>, 'claimId': doc.id});
}
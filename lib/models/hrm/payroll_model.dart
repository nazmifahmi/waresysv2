import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollModel {
  final String payrollId;
  final String employeeId;
  final double amount;
  final String month;
  final String status;
  final DateTime? paymentDate;
  final double baseSalary;
  final double totalDeductions;
  final double totalAllowances;
  final double netSalary;
  final String? payslipUrl;

  PayrollModel({
    required this.payrollId,
    required this.employeeId,
    required this.amount,
    required this.month,
    required this.status,
    this.paymentDate,
    required this.baseSalary,
    required this.totalDeductions,
    required this.totalAllowances,
    required this.netSalary,
    this.payslipUrl,
  }) : assert(payrollId.isNotEmpty, 'payrollId cannot be empty'),
       assert(employeeId.isNotEmpty, 'employeeId cannot be empty'),
       assert(month.isNotEmpty, 'month cannot be empty'),
       assert(status.isNotEmpty, 'status cannot be empty'),
       assert(amount >= 0 && baseSalary >= 0 && totalDeductions >= 0 && totalAllowances >= 0 && netSalary >= 0);

  Map<String, dynamic> toMap() => {
        'payrollId': payrollId,
        'employeeId': employeeId,
        'amount': amount,
        'month': month,
        'status': status,
        'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
        'baseSalary': baseSalary,
        'totalDeductions': totalDeductions,
        'totalAllowances': totalAllowances,
        'netSalary': netSalary,
        'payslipUrl': payslipUrl,
      };

  factory PayrollModel.fromMap(Map<String, dynamic> map) => PayrollModel(
        payrollId: map['payrollId'],
        employeeId: map['employeeId'],
        amount: (map['amount'] as num).toDouble(),
        month: map['month'],
        status: map['status'],
        paymentDate: (map['paymentDate'] as Timestamp?)?.toDate(),
        baseSalary: (map['baseSalary'] as num).toDouble(),
        totalDeductions: (map['totalDeductions'] as num).toDouble(),
        totalAllowances: (map['totalAllowances'] as num).toDouble(),
        netSalary: (map['netSalary'] as num).toDouble(),
        payslipUrl: map['payslipUrl'],
      );

  factory PayrollModel.fromDoc(DocumentSnapshot doc) =>
      PayrollModel.fromMap({...doc.data() as Map<String, dynamic>, 'payrollId': doc.id});
}
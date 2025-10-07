import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollModel {
  final String payrollId;
  final String employeeId;
  final String period; // e.g., "Oktober 2025"
  final double baseSalary;
  final double totalDeductions;
  final double totalAllowances;
  final double netSalary;
  final String? payslipUrl;

  PayrollModel({
    required this.payrollId,
    required this.employeeId,
    required this.period,
    required this.baseSalary,
    required this.totalDeductions,
    required this.totalAllowances,
    required this.netSalary,
    this.payslipUrl,
  }) : assert(payrollId.isNotEmpty, 'payrollId cannot be empty'),
       assert(employeeId.isNotEmpty, 'employeeId cannot be empty'),
       assert(period.isNotEmpty, 'period cannot be empty'),
       assert(baseSalary >= 0 && totalDeductions >= 0 && totalAllowances >= 0 && netSalary >= 0);

  Map<String, dynamic> toMap() => {
        'payrollId': payrollId,
        'employeeId': employeeId,
        'period': period,
        'baseSalary': baseSalary,
        'totalDeductions': totalDeductions,
        'totalAllowances': totalAllowances,
        'netSalary': netSalary,
        'payslipUrl': payslipUrl,
      };

  factory PayrollModel.fromMap(Map<String, dynamic> map) => PayrollModel(
        payrollId: map['payrollId'],
        employeeId: map['employeeId'],
        period: map['period'],
        baseSalary: (map['baseSalary'] as num).toDouble(),
        totalDeductions: (map['totalDeductions'] as num).toDouble(),
        totalAllowances: (map['totalAllowances'] as num).toDouble(),
        netSalary: (map['netSalary'] as num).toDouble(),
        payslipUrl: map['payslipUrl'],
      );

  factory PayrollModel.fromDoc(DocumentSnapshot doc) =>
      PayrollModel.fromMap({...doc.data() as Map<String, dynamic>, 'payrollId': doc.id});
}
import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String position;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double netSalary;
  final DateTime payrollDate;
  final String status; // 'pending', 'approved', 'paid'
  final DateTime createdAt;
  final DateTime? updatedAt;

  PayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.position,
    required this.baseSalary,
    this.allowances = 0.0,
    this.deductions = 0.0,
    required this.netSalary,
    required this.payrollDate,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate net salary automatically
  factory PayrollModel.create({
    required String employeeId,
    required String employeeName,
    required String position,
    required double baseSalary,
    double allowances = 0.0,
    double deductions = 0.0,
    required DateTime payrollDate,
  }) {
    final netSalary = baseSalary + allowances - deductions;
    return PayrollModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: employeeId,
      employeeName: employeeName,
      position: position,
      baseSalary: baseSalary,
      allowances: allowances,
      deductions: deductions,
      netSalary: netSalary,
      payrollDate: payrollDate,
      createdAt: DateTime.now(),
    );
  }

  // From Firestore
  factory PayrollModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayrollModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      position: data['position'] ?? '',
      baseSalary: (data['baseSalary'] ?? 0.0).toDouble(),
      allowances: (data['allowances'] ?? 0.0).toDouble(),
      deductions: (data['deductions'] ?? 0.0).toDouble(),
      netSalary: (data['netSalary'] ?? 0.0).toDouble(),
      payrollDate: (data['payrollDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'position': position,
      'baseSalary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': netSalary,
      'payrollDate': Timestamp.fromDate(payrollDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Copy with method for updates
  PayrollModel copyWith({
    String? employeeId,
    String? employeeName,
    String? position,
    double? baseSalary,
    double? allowances,
    double? deductions,
    double? netSalary,
    DateTime? payrollDate,
    String? status,
    DateTime? updatedAt,
  }) {
    return PayrollModel(
      id: id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      position: position ?? this.position,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      netSalary: netSalary ?? this.netSalary,
      payrollDate: payrollDate ?? this.payrollDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PayrollModel(id: $id, employeeName: $employeeName, netSalary: $netSalary, status: $status)';
  }
}
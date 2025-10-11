import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/payroll_model.dart';
import '../../models/hrm/attendance_model.dart';

class PayrollService {
  final FirebaseFirestore _firestore;

  PayrollService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _payrollCol => _firestore.collection('payrolls');
  CollectionReference get _attendanceCol => _firestore.collection('attendance');
  CollectionReference get _claimsCol => _firestore.collection('claims');

  // Business rule example:
  // - Late deduction: 1% of baseSalary per late day
  // - Approved claim adds to allowance
  Future<PayrollModel> calculateSalary({
    required String employeeId,
    required String periodLabel, // e.g., "Oktober 2025"
    required double baseSalary,
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final attendanceSnap = await _attendanceCol
        .where('employeeId', isEqualTo: employeeId)
        .where('checkInTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('checkInTimestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    final claimsSnap = await _claimsCol
        .where('employeeId', isEqualTo: employeeId)
        .where('submissionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('submissionDate', isLessThan: Timestamp.fromDate(end))
        .where('status', isEqualTo: 'approved')
        .get();

    int lateDays = 0;
    for (final d in attendanceSnap.docs) {
      final att = AttendanceModel.fromDoc(d);
      if (att.status == AttendanceStatus.late) {
        lateDays += 1;
      }
    }

    final double lateDeduction = baseSalary * 0.01 * lateDays;

    double approvedClaimsTotal = 0.0;
    for (final c in claimsSnap.docs) {
      final data = c.data() as Map<String, dynamic>;
      approvedClaimsTotal += (data['amount'] as num).toDouble();
    }

    final totalDeductions = max(0.0, lateDeduction);
    final totalAllowances = max(0.0, approvedClaimsTotal);
    final netSalary = baseSalary - totalDeductions + totalAllowances;

    return PayrollModel(
      payrollId: '',
      employeeId: employeeId,
      period: periodLabel,
      baseSalary: baseSalary,
      totalDeductions: totalDeductions,
      totalAllowances: totalAllowances,
      netSalary: netSalary,
      payslipUrl: null,
    );
  }

  Future<String> savePayroll(PayrollModel model) async {
    final ref = await _payrollCol.add(model.toMap());
    await _payrollCol.doc(ref.id).update({'payrollId': ref.id});
    return ref.id;
  }

  Stream<List<PayrollModel>> watchByEmployee(String employeeId) {
    return _payrollCol.where('employeeId', isEqualTo: employeeId).orderBy('period', descending: true).snapshots().map(
          (s) => s.docs.map((d) => PayrollModel.fromDoc(d)).toList(),
        );
  }
}
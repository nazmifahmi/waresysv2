import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/hrm/payroll_model.dart';
import '../../models/hrm/employee_model.dart';

class PayrollService {
  static const String _collection = 'payrolls';
  
  // Lazy initialization with Firebase check
  CollectionReference<Map<String, dynamic>>? get _payrollsCollection {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance.collection(_collection);
  }

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  // Create payroll for an employee
  Future<String?> createPayroll({
    required String employeeId,
    required String employeeName,
    required String position,
    required double baseSalary,
    double allowances = 0.0,
    double deductions = 0.0,
    required DateTime payrollDate,
  }) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for payroll creation');
        return null;
      }

      final payroll = PayrollModel.create(
        employeeId: employeeId,
        employeeName: employeeName,
        position: position,
        baseSalary: baseSalary,
        allowances: allowances,
        deductions: deductions,
        payrollDate: payrollDate,
      );

      final docRef = await _payrollsCollection!.add(payroll.toFirestore());
      print('✅ Payroll created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating payroll: $e');
      return null;
    }
  }

  // Create payroll from employee data
  Future<String?> createPayrollFromEmployee(EmployeeModel employee, DateTime payrollDate) async {
    return await createPayroll(
      employeeId: employee.employeeId,
      employeeName: employee.fullName,
      position: employee.position,
      baseSalary: employee.salary,
      payrollDate: payrollDate,
    );
  }

  // Get all payrolls
  Future<List<PayrollModel>> getAllPayrolls() async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for fetching payrolls');
        return [];
      }

      final snapshot = await _payrollsCollection!
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PayrollModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching payrolls: $e');
      return [];
    }
  }

  // Get payrolls by employee
  Future<List<PayrollModel>> getPayrollsByEmployee(String employeeId) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for fetching employee payrolls');
        return [];
      }

      final snapshot = await _payrollsCollection!
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('payrollDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PayrollModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching employee payrolls: $e');
      return [];
    }
  }

  // Get payrolls by status
  Future<List<PayrollModel>> getPayrollsByStatus(String status) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for fetching payrolls by status');
        return [];
      }

      final snapshot = await _payrollsCollection!
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PayrollModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching payrolls by status: $e');
      return [];
    }
  }

  // Update payroll status
  Future<bool> updatePayrollStatus(String payrollId, String status) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for updating payroll status');
        return false;
      }

      await _payrollsCollection!.doc(payrollId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      print('✅ Payroll status updated: $payrollId -> $status');
      return true;
    } catch (e) {
      print('❌ Error updating payroll status: $e');
      return false;
    }
  }

  // Update payroll
  Future<bool> updatePayroll(String payrollId, PayrollModel payroll) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for updating payroll');
        return false;
      }

      final updatedPayroll = payroll.copyWith(updatedAt: DateTime.now());
      await _payrollsCollection!.doc(payrollId).update(updatedPayroll.toFirestore());

      print('✅ Payroll updated successfully: $payrollId');
      return true;
    } catch (e) {
      print('❌ Error updating payroll: $e');
      return false;
    }
  }

  // Delete payroll
  Future<bool> deletePayroll(String payrollId) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for deleting payroll');
        return false;
      }

      await _payrollsCollection!.doc(payrollId).delete();
      print('✅ Payroll deleted successfully: $payrollId');
      return true;
    } catch (e) {
      print('❌ Error deleting payroll: $e');
      return false;
    }
  }

  // Get payroll by ID
  Future<PayrollModel?> getPayrollById(String payrollId) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for fetching payroll by ID');
        return null;
      }

      final doc = await _payrollsCollection!.doc(payrollId).get();
      if (doc.exists) {
        return PayrollModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching payroll by ID: $e');
      return null;
    }
  }

  // Approve payroll
  Future<bool> approvePayroll(String payrollId) async {
    return await updatePayrollStatus(payrollId, 'approved');
  }

  // Mark payroll as paid
  Future<bool> markPayrollAsPaid(String payrollId) async {
    return await updatePayrollStatus(payrollId, 'paid');
  }

  // Get monthly payroll summary
  Future<Map<String, dynamic>> getMonthlyPayrollSummary(DateTime month) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for monthly payroll summary');
        return {
          'totalPayrolls': 0,
          'totalAmount': 0.0,
          'pendingCount': 0,
          'approvedCount': 0,
          'paidCount': 0,
        };
      }

      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final snapshot = await _payrollsCollection!
          .where('payrollDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('payrollDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final payrolls = snapshot.docs.map((doc) => PayrollModel.fromFirestore(doc)).toList();

      double totalAmount = 0.0;
      int pendingCount = 0;
      int approvedCount = 0;
      int paidCount = 0;

      for (final payroll in payrolls) {
        totalAmount += payroll.netSalary;
        switch (payroll.status) {
          case 'pending':
            pendingCount++;
            break;
          case 'approved':
            approvedCount++;
            break;
          case 'paid':
            paidCount++;
            break;
        }
      }

      return {
        'totalPayrolls': payrolls.length,
        'totalAmount': totalAmount,
        'pendingCount': pendingCount,
        'approvedCount': approvedCount,
        'paidCount': paidCount,
      };
    } catch (e) {
      print('❌ Error getting monthly payroll summary: $e');
      return {
        'totalPayrolls': 0,
        'totalAmount': 0.0,
        'pendingCount': 0,
        'approvedCount': 0,
        'paidCount': 0,
      };
    }
  }
}
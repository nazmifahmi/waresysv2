import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/leave_request_model.dart';
import '../../models/hrm/employee_model.dart';
import 'employee_repository.dart';
import '../notification_service.dart';

class LeaveRepository {
  final FirebaseFirestore _firestore;
  final EmployeeRepository _employeeRepository;
  final NotificationService _notificationService;

  LeaveRepository({
    FirebaseFirestore? firestore,
    EmployeeRepository? employeeRepository,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _employeeRepository = employeeRepository ?? EmployeeRepository(),
        _notificationService = notificationService ?? NotificationService();

  CollectionReference get _col => _firestore.collection('leave_requests');

  /// Calculate the number of leave days between start and end date (inclusive)
  int _calculateLeaveDays(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Validate if employee has sufficient leave balance
  Future<bool> validateLeaveBalance(String employeeId, DateTime startDate, DateTime endDate) async {
    final employee = await _employeeRepository.getById(employeeId);
    if (employee == null) throw Exception('Employee not found');
    
    final requestedDays = _calculateLeaveDays(startDate, endDate);
    return employee.leaveBalance >= requestedDays;
  }

  /// Get employee's current leave balance
  Future<int> getEmployeeLeaveBalance(String employeeId) async {
    final employee = await _employeeRepository.getById(employeeId);
    if (employee == null) throw Exception('Employee not found');
    return employee.leaveBalance;
  }

  /// Create a new leave request with validation
  Future<String> create(LeaveRequestModel model) async {
    // Validate leave balance before creating request
    final hasBalance = await validateLeaveBalance(model.employeeId, model.startDate, model.endDate);
    if (!hasBalance) {
      final currentBalance = await getEmployeeLeaveBalance(model.employeeId);
      final requestedDays = _calculateLeaveDays(model.startDate, model.endDate);
      throw Exception('Insufficient leave balance. Current: $currentBalance days, Requested: $requestedDays days');
    }

    final ref = await _col.add(model.toMap());
    await _col.doc(ref.id).update({'requestId': ref.id});
    return ref.id;
  }

  /// Update leave request status and adjust employee leave balance if approved
  Future<void> updateStatus(String requestId, LeaveStatus status, {String? approvedBy}) async {
    final doc = await _col.doc(requestId).get();
    if (!doc.exists) throw Exception('Leave request not found');
    
    final leaveRequest = LeaveRequestModel.fromDoc(doc);
    
    // Update request status
    final updateData = {
      'status': status.name,
      'approvalDate': status != LeaveStatus.pending ? Timestamp.fromDate(DateTime.now()) : null,
    };
    
    if (approvedBy != null) {
      updateData['approvedBy'] = approvedBy;
    }
    
    await _col.doc(requestId).update(updateData);
    
    // If approved, deduct from employee's leave balance
    if (status == LeaveStatus.approved && leaveRequest.status != LeaveStatus.approved) {
      final employee = await _employeeRepository.getById(leaveRequest.employeeId);
      if (employee != null) {
        final leaveDays = _calculateLeaveDays(leaveRequest.startDate, leaveRequest.endDate);
        final newBalance = employee.leaveBalance - leaveDays;
        
        final updatedEmployee = EmployeeModel(
          employeeId: employee.employeeId,
          userId: employee.userId,
          fullName: employee.fullName,
          position: employee.position,
          department: employee.department,
          joinDate: employee.joinDate,
          salary: employee.salary,
          contractUrl: employee.contractUrl,
          status: employee.status,
          role: employee.role,
          leaveBalance: newBalance >= 0 ? newBalance : 0,
        );
        
        await _employeeRepository.update(updatedEmployee);
      }
    }

    // Send notification based on status
    if (status == LeaveStatus.approved) {
      await _notificationService.sendLeaveApprovedNotification(
        employeeId: leaveRequest.employeeId,
        leaveType: leaveRequest.leaveType.name,
        startDate: leaveRequest.startDate,
        endDate: leaveRequest.endDate,
        approvedBy: approvedBy ?? 'System',
      );
    } else if (status == LeaveStatus.rejected) {
      await _notificationService.sendLeaveRejectedNotification(
        employeeId: leaveRequest.employeeId,
        leaveType: leaveRequest.leaveType.name,
        startDate: leaveRequest.startDate,
        endDate: leaveRequest.endDate,
        rejectedBy: approvedBy ?? 'System',
      );
    }
  }

  Stream<List<LeaveRequestModel>> watchByEmployee(String employeeId) {
    return _col.where('employeeId', isEqualTo: employeeId).orderBy('startDate', descending: true).snapshots().map(
          (s) => s.docs.map((d) => LeaveRequestModel.fromDoc(d)).toList(),
        );
  }

  Stream<List<LeaveRequestModel>> watchPending() {
    return _col.where('status', isEqualTo: LeaveStatus.pending.name).orderBy('startDate').snapshots().map(
          (s) => s.docs.map((d) => LeaveRequestModel.fromDoc(d)).toList(),
        );
  }
}
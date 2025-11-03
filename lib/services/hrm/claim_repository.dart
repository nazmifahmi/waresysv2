import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/claim_model.dart';
import '../../models/hrm/employee_model.dart';
import 'employee_repository.dart';
import '../notification_service.dart';

class ClaimRepository {
  final FirebaseFirestore _firestore;
  final EmployeeRepository _employeeRepository;
  final NotificationService _notificationService;

  ClaimRepository({
    FirebaseFirestore? firestore,
    EmployeeRepository? employeeRepository,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _employeeRepository = employeeRepository ?? EmployeeRepository(),
        _notificationService = notificationService ?? NotificationService();

  CollectionReference get _col => _firestore.collection('claims');

  Future<String> create(ClaimModel model) async {
    final ref = await _col.add(model.toMap());
    await _col.doc(ref.id).update({'claimId': ref.id});
    return ref.id;
  }

  Future<void> updateStatus(String claimId, ClaimStatus status, {String? approvedBy}) async {
    final doc = await _col.doc(claimId).get();
    if (!doc.exists) throw Exception('Claim not found');
    
    final claim = ClaimModel.fromDoc(doc);
    
    await _col.doc(claimId).update({'status': status.name});
    
    // Send notification based on status
    if (status == ClaimStatus.approved) {
      await _notificationService.sendClaimApprovedNotification(
        employeeId: claim.employeeId,
        claimType: claim.claimType,
        amount: claim.amount,
        approvedBy: approvedBy ?? 'System',
        claimId: claimId,
      );
    } else if (status == ClaimStatus.rejected) {
      await _notificationService.sendClaimRejectedNotification(
        employeeId: claim.employeeId,
        claimType: claim.claimType,
        amount: claim.amount,
        rejectedBy: approvedBy ?? 'System',
        claimId: claimId,
      );
    }
  }

  Stream<List<ClaimModel>> watchByEmployee(String employeeId) {
    return _col.where('employeeId', isEqualTo: employeeId).orderBy('submissionDate', descending: true).snapshots().map(
          (s) => s.docs.map((d) => ClaimModel.fromDoc(d)).toList(),
        );
  }

  Stream<List<ClaimModel>> watchPending() {
    return _col.where('status', isEqualTo: ClaimStatus.pending.name).orderBy('submissionDate').snapshots().map(
          (s) => s.docs.map((d) => ClaimModel.fromDoc(d)).toList(),
        );
  }
}
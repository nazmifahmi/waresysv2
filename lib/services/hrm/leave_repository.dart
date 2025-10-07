import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/leave_request_model.dart';

class LeaveRepository {
  final FirebaseFirestore _firestore;

  LeaveRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('leave_requests');

  Future<String> create(LeaveRequestModel model) async {
    final ref = await _col.add(model.toMap());
    await _col.doc(ref.id).update({'requestId': ref.id});
    return ref.id;
  }

  Future<void> updateStatus(String requestId, LeaveStatus status) async {
    await _col.doc(requestId).update({'status': status.name});
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
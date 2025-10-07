import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/claim_model.dart';

class ClaimRepository {
  final FirebaseFirestore _firestore;

  ClaimRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('claims');

  Future<String> create(ClaimModel model) async {
    final ref = await _col.add(model.toMap());
    await _col.doc(ref.id).update({'claimId': ref.id});
    return ref.id;
  }

  Future<void> updateStatus(String claimId, ClaimStatus status) async {
    await _col.doc(claimId).update({'status': status.name});
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
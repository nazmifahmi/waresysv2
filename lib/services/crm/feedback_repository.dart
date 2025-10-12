import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/feedback_model.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('feedback');

  Future<List<FeedbackModel>> getAll({String? search}) async {
    Query query = _col.orderBy('date', descending: true);
    if (search != null && search.trim().isNotEmpty) {
      query = _col.where('messageLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('messageLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => FeedbackModel.fromDoc(d)).toList();
  }

  Stream<List<FeedbackModel>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map((s) => s.docs.map((d) => FeedbackModel.fromDoc(d)).toList());
  }

  Future<FeedbackModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return FeedbackModel.fromDoc(doc);
  }

  Future<String> create(FeedbackModel feedback) async {
    final ref = await _col.add({
      ...feedback.toMap(),
      'messageLower': feedback.message.toLowerCase(),
    });
    await _col.doc(ref.id).update({'feedbackId': ref.id});
    return ref.id;
  }

  Future<void> update(FeedbackModel feedback) async {
    await _col.doc(feedback.feedbackId).update({
      ...feedback.toMap(),
      'messageLower': feedback.message.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<FeedbackModel>> watchByCustomer(String customerId) {
    return _col.where('customerId', isEqualTo: customerId).orderBy('date', descending: true).snapshots().map(
          (s) => s.docs.map((d) => FeedbackModel.fromDoc(d)).toList(),
        );
  }

  Stream<List<FeedbackModel>> watchByRating(int rating) {
    return _col.where('rating', isEqualTo: rating).orderBy('date', descending: true).snapshots().map(
          (s) => s.docs.map((d) => FeedbackModel.fromDoc(d)).toList(),
        );
  }

  Future<double> getAverageRating() async {
    final snap = await _col.get();
    if (snap.docs.isEmpty) return 0.0;
    
    double totalRating = 0.0;
    for (final doc in snap.docs) {
      final feedback = FeedbackModel.fromDoc(doc);
      totalRating += feedback.rating;
    }
    return totalRating / snap.docs.length;
  }
}
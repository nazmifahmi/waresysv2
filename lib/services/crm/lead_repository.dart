import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/lead_model.dart';

class LeadRepository {
  final FirebaseFirestore _firestore;

  LeadRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('leads');

  Future<List<LeadModel>> getAll({String? search}) async {
    Query query = _col.orderBy('source');
    if (search != null && search.trim().isNotEmpty) {
      query = _col.where('sourceLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('sourceLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => LeadModel.fromDoc(d)).toList();
  }

  Stream<List<LeadModel>> watchAll() {
    return _col.orderBy('source').snapshots().map((s) => s.docs.map((d) => LeadModel.fromDoc(d)).toList());
  }

  Future<LeadModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return LeadModel.fromDoc(doc);
  }

  Future<String> create(LeadModel lead) async {
    final ref = await _col.add({
      ...lead.toMap(),
      'sourceLower': lead.source.toLowerCase(),
    });
    await _col.doc(ref.id).update({'leadId': ref.id});
    return ref.id;
  }

  Future<void> update(LeadModel lead) async {
    await _col.doc(lead.leadId).update({
      ...lead.toMap(),
      'sourceLower': lead.source.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> updateStatus(String leadId, LeadStatus status) async {
    await _col.doc(leadId).update({'status': status.name});
  }

  Stream<List<LeadModel>> watchByStatus(LeadStatus status) {
    return _col.where('status', isEqualTo: status.name).orderBy('source').snapshots().map(
          (s) => s.docs.map((d) => LeadModel.fromDoc(d)).toList(),
        );
  }

  Stream<List<LeadModel>> watchByAssignedTo(String assignedTo) {
    return _col.where('assignedTo', isEqualTo: assignedTo).orderBy('source').snapshots().map(
          (s) => s.docs.map((d) => LeadModel.fromDoc(d)).toList(),
        );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/contact_model.dart';

class ContactRepository {
  final FirebaseFirestore _firestore;

  ContactRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('contacts');

  Future<List<ContactModel>> getAll({String? search}) async {
    Query query = _col.orderBy('name');
    if (search != null && search.trim().isNotEmpty) {
      query = _col.where('nameLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('nameLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => ContactModel.fromDoc(d)).toList();
  }

  Stream<List<ContactModel>> watchAll() {
    return _col.orderBy('name').snapshots().map((s) => s.docs.map((d) => ContactModel.fromDoc(d)).toList());
  }

  Future<ContactModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ContactModel.fromDoc(doc);
  }

  Future<String> create(ContactModel contact) async {
    final ref = await _col.add({
      ...contact.toMap(),
      'nameLower': contact.name.toLowerCase(),
    });
    await _col.doc(ref.id).update({'contactId': ref.id});
    return ref.id;
  }

  Future<void> update(ContactModel contact) async {
    await _col.doc(contact.contactId).update({
      ...contact.toMap(),
      'nameLower': contact.name.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<ContactModel>> watchByCompany(String companyId) {
    return _col.where('companyId', isEqualTo: companyId).orderBy('name').snapshots().map(
          (s) => s.docs.map((d) => ContactModel.fromDoc(d)).toList(),
        );
  }

  Future<List<ContactModel>> searchByEmail(String email) async {
    final snap = await _col.where('email', isEqualTo: email).get();
    return snap.docs.map((d) => ContactModel.fromDoc(d)).toList();
  }

  Future<List<ContactModel>> searchByPhone(String phone) async {
    final snap = await _col.where('phone', isEqualTo: phone).get();
    return snap.docs.map((d) => ContactModel.fromDoc(d)).toList();
  }
}
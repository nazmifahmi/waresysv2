import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/customer_model.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore;

  CustomerRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('customers');

  Future<List<CustomerModel>> getAll({String? search}) async {
    Query query = _col.orderBy('name');
    if (search != null && search.trim().isNotEmpty) {
      query = _col.where('nameLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('nameLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => CustomerModel.fromDoc(d)).toList();
  }

  Stream<List<CustomerModel>> watchAll() {
    return _col.orderBy('name').snapshots().map((s) => s.docs.map((d) => CustomerModel.fromDoc(d)).toList());
  }

  Future<CustomerModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CustomerModel.fromDoc(doc);
  }

  Future<String> create(CustomerModel customer) async {
    final ref = await _col.add({
      ...customer.toMap(),
      'nameLower': customer.name.toLowerCase(),
    });
    await _col.doc(ref.id).update({'customerId': ref.id});
    return ref.id;
  }

  Future<void> update(CustomerModel customer) async {
    await _col.doc(customer.customerId).update({
      ...customer.toMap(),
      'nameLower': customer.name.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<CustomerModel>> watchByStatus(CustomerStatus status) {
    return _col.where('status', isEqualTo: status.name).orderBy('name').snapshots().map(
          (s) => s.docs.map((d) => CustomerModel.fromDoc(d)).toList(),
        );
  }
}
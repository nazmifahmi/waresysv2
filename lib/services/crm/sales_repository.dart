import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/sales_model.dart';

class SalesRepository {
  final FirebaseFirestore _firestore;

  SalesRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('sales');

  Future<List<SalesModel>> getAll({String? search}) async {
    Query query = _col.orderBy('date', descending: true);
    if (search != null && search.trim().isNotEmpty) {
      query = _col.where('productNameLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('productNameLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => SalesModel.fromDoc(d)).toList();
  }

  Stream<List<SalesModel>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map((s) => s.docs.map((d) => SalesModel.fromDoc(d)).toList());
  }

  Future<SalesModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return SalesModel.fromDoc(doc);
  }

  Future<String> create(SalesModel sales) async {
    final ref = await _col.add({
      ...sales.toMap(),
      'productNameLower': sales.productName.toLowerCase(),
    });
    await _col.doc(ref.id).update({'salesId': ref.id});
    return ref.id;
  }

  Future<void> update(SalesModel sales) async {
    await _col.doc(sales.salesId).update({
      ...sales.toMap(),
      'productNameLower': sales.productName.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<SalesModel>> watchByCustomer(String customerId) {
    return _col.where('customerId', isEqualTo: customerId).orderBy('date', descending: true).snapshots().map(
          (s) => s.docs.map((d) => SalesModel.fromDoc(d)).toList(),
        );
  }

  Future<double> getTotalSalesForPeriod(DateTime start, DateTime end) async {
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    
    double total = 0.0;
    for (final doc in snap.docs) {
      final sales = SalesModel.fromDoc(doc);
      total += sales.totalPrice;
    }
    return total;
  }
}
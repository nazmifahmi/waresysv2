import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/employee_model.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore;

  EmployeeRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('employees');

  Future<List<EmployeeModel>> getAll({String? search}) async {
    Query query = _col.orderBy('fullName');
    if (search != null && search.trim().isNotEmpty) {
      // Basic search using where + startAt/endAt would require index with array or dedicated search fields.
      query = _col.where('fullNameLower', isGreaterThanOrEqualTo: search.toLowerCase())
                  .where('fullNameLower', isLessThanOrEqualTo: '${search.toLowerCase()}\uf8ff');
    }
    final snap = await query.get();
    return snap.docs.map((d) => EmployeeModel.fromDoc(d)).toList();
  }

  Stream<List<EmployeeModel>> watchAll() {
    return _col.orderBy('fullName').snapshots().map((s) => s.docs.map((d) => EmployeeModel.fromDoc(d)).toList());
  }

  Future<EmployeeModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return EmployeeModel.fromDoc(doc);
  }

  Future<String> create(EmployeeModel employee) async {
    final ref = await _col.add({
      ...employee.toMap(),
      'fullNameLower': employee.fullName.toLowerCase(),
      'departmentLower': employee.department.toLowerCase(),
    });
    await _col.doc(ref.id).update({'employeeId': ref.id});
    return ref.id;
  }

  Future<void> update(EmployeeModel employee) async {
    await _col.doc(employee.employeeId).update({
      ...employee.toMap(),
      'fullNameLower': employee.fullName.toLowerCase(),
      'departmentLower': employee.department.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
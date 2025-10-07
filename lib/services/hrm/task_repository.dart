import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('tasks');

  Future<String> create(TaskModel model) async {
    final ref = await _col.add(model.toMap());
    await _col.doc(ref.id).update({'taskId': ref.id});
    return ref.id;
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    await _col.doc(taskId).update({'status': status.name});
  }

  Stream<List<TaskModel>> watchMyTasks(String employeeId) {
    return _col.where('assigneeId', isEqualTo: employeeId).orderBy('dueDate').snapshots().map(
          (s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList(),
        );
  }

  Stream<List<TaskModel>> watchAll() {
    return _col.orderBy('dueDate').snapshots().map(
          (s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList(),
        );
  }
}
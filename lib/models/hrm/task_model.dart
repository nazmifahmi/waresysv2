import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { todo, inProgress, done }

class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String assigneeId; // employeeId
  final String reporterId; // adminId
  final DateTime dueDate;
  final TaskStatus status;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.reporterId,
    required this.dueDate,
    this.status = TaskStatus.todo,
  }) : assert(taskId.isNotEmpty),
       assert(title.isNotEmpty),
       assert(description.isNotEmpty),
       assert(assigneeId.isNotEmpty),
       assert(reporterId.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'title': title,
        'description': description,
        'assigneeId': assigneeId,
        'reporterId': reporterId,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': status.name,
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        taskId: map['taskId'],
        title: map['title'],
        description: map['description'],
        assigneeId: map['assigneeId'],
        reporterId: map['reporterId'],
        dueDate: (map['dueDate'] as Timestamp).toDate(),
        status: TaskStatus.values.firstWhere((e) => e.name == map['status']),
      );

  factory TaskModel.fromDoc(DocumentSnapshot doc) =>
      TaskModel.fromMap({...doc.data() as Map<String, dynamic>, 'taskId': doc.id});
}
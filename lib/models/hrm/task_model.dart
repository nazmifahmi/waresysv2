import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, in_progress, completed, cancelled }
enum TaskPriority { low, medium, high, urgent }

class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String assigneeId; // employeeId
  final String reporterId; // adminId
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskModel({
    this.taskId = '',
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.reporterId,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    this.completedAt,
  }) : assert(title.isNotEmpty),
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
        'priority': priority.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final title = map['title']?.toString().trim() ?? 'Untitled Task';
    final description = map['description']?.toString().trim() ?? 'No description';
    final assigneeId = map['assigneeId']?.toString() ?? 'unknown';
    final reporterId = map['reporterId']?.toString() ?? 'unknown';
    
    return TaskModel(
      taskId: map['taskId'] ?? '',
      title: title.isEmpty ? 'Untitled Task' : title,
      description: description.isEmpty ? 'No description' : description,
      assigneeId: assigneeId.isEmpty ? 'unknown' : assigneeId,
      reporterId: reporterId.isEmpty ? 'unknown' : reporterId,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? TaskStatus.pending.name),
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == (map['priority'] ?? TaskPriority.medium.name),
        orElse: () => TaskPriority.medium,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory TaskModel.fromDoc(DocumentSnapshot doc) =>
      TaskModel.fromMap({...doc.data() as Map<String, dynamic>, 'taskId': doc.id});
}
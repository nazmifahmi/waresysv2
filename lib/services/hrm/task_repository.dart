import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/task_model.dart';
import '../../models/hrm/employee_model.dart';
import 'employee_repository.dart';
import '../notification_service.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final EmployeeRepository _employeeRepository;
  final NotificationService _notificationService;

  TaskRepository({
    FirebaseFirestore? firestore,
    EmployeeRepository? employeeRepository,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _employeeRepository = employeeRepository ?? EmployeeRepository(),
        _notificationService = notificationService ?? NotificationService();

  CollectionReference get _col => _firestore.collection('tasks');

  /// Create a new task with validation
  Future<String> create(TaskModel model) async {
    // Validate assignee exists
    final assignee = await _employeeRepository.getById(model.assigneeId);
    if (assignee == null) throw Exception('Assignee not found');
    
    // Validate reporter exists
    final reporter = await _employeeRepository.getById(model.reporterId);
    if (reporter == null) throw Exception('Reporter not found');
    
    final ref = await _col.add(model.toMap());
    await _col.doc(ref.id).update({'taskId': ref.id});
    
    // Send task assignment notification
    await _notificationService.sendTaskAssignedNotification(
      assigneeId: model.assigneeId,
      taskTitle: model.title,
      dueDate: model.dueDate,
      assignedBy: reporter.fullName,
      taskId: ref.id,
    );
    
    return ref.id;
  }

  /// Update task status with completion tracking
  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final task = await getById(taskId);
    if (task == null) throw Exception('Task not found');
    
    final updateData = <String, dynamic>{
      'status': status.name,
    };
    
    // Set completion date if task is completed
    if (status == TaskStatus.completed) {
      updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
    }
    
    await _col.doc(taskId).update(updateData);
    
    // Send notification for task completion
    if (status == TaskStatus.completed) {
      final assignee = await _employeeRepository.getById(task.assigneeId);
      await _notificationService.sendTaskCompletedNotification(
        reporterId: task.reporterId,
        taskTitle: task.title,
        completedBy: assignee?.fullName ?? 'Unknown',
        taskId: taskId,
      );
    }
  }

  /// Update task details (title, description, due date, priority)
  Future<void> updateTask(TaskModel model) async {
    await _col.doc(model.taskId).update(model.toMap());
  }

  /// Reassign task to a different employee
  Future<void> reassignTask(String taskId, String newAssigneeId) async {
    // Get current task details
    final task = await getById(taskId);
    if (task == null) throw Exception('Task not found');
    
    // Validate new assignee exists
    final assignee = await _employeeRepository.getById(newAssigneeId);
    if (assignee == null) throw Exception('New assignee not found');
    
    // Get reporter details for notification
    final reporter = await _employeeRepository.getById(task.reporterId);
    
    await _col.doc(taskId).update({'assigneeId': newAssigneeId});
    
    // Send task assignment notification to new assignee
    await _notificationService.sendTaskAssignedNotification(
      assigneeId: newAssigneeId,
      taskTitle: task.title,
      dueDate: task.dueDate,
      assignedBy: reporter?.fullName ?? 'System',
      taskId: taskId,
    );
  }

  /// Delete a task
  Future<void> delete(String taskId) async {
    await _col.doc(taskId).delete();
  }

  /// Get task by ID
  Future<TaskModel?> getById(String taskId) async {
    final doc = await _col.doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromDoc(doc);
  }

  /// Watch tasks assigned to a specific employee
  Stream<List<TaskModel>> watchMyTasks(String employeeId) {
    return _col
        .where('assigneeId', isEqualTo: employeeId)
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  /// Watch tasks created by a specific reporter
  Stream<List<TaskModel>> watchMyCreatedTasks(String reporterId) {
    return _col
        .where('reporterId', isEqualTo: reporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  /// Watch all tasks (for managers/admins)
  Stream<List<TaskModel>> watchAll() {
    return _col
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  /// Watch tasks by status
  Stream<List<TaskModel>> watchByStatus(TaskStatus status) {
    return _col
        .where('status', isEqualTo: status.name)
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  /// Watch tasks by priority
  Stream<List<TaskModel>> watchByPriority(TaskPriority priority) {
    return _col
        .where('priority', isEqualTo: priority.name)
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  /// Watch overdue tasks
  Stream<List<TaskModel>> watchOverdueTasks() {
    return _col
        .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .where('status', whereIn: [TaskStatus.pending.name, TaskStatus.in_progress.name])
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  /// Get task statistics for an employee
  Future<Map<String, int>> getTaskStats(String employeeId) async {
    final tasks = await _col.where('assigneeId', isEqualTo: employeeId).get();
    
    int pending = 0;
    int inProgress = 0;
    int completed = 0;
    int overdue = 0;
    
    final now = DateTime.now();
    
    for (final doc in tasks.docs) {
      final task = TaskModel.fromDoc(doc);
      
      switch (task.status) {
        case TaskStatus.pending:
          pending++;
          if (task.dueDate.isBefore(now)) overdue++;
          break;
        case TaskStatus.in_progress:
          inProgress++;
          if (task.dueDate.isBefore(now)) overdue++;
          break;
        case TaskStatus.completed:
          completed++;
          break;
        case TaskStatus.cancelled:
          // Don't count cancelled tasks
          break;
      }
    }
    
    return {
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'overdue': overdue,
      'total': pending + inProgress + completed,
    };
  }
}
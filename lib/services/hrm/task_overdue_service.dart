import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/task_model.dart';
import '../notification_service.dart';
import 'task_repository.dart';

/// Service to handle overdue task notifications and monitoring
class TaskOverdueService {
  final TaskRepository _taskRepository;
  final NotificationService _notificationService;
  Timer? _overdueCheckTimer;

  TaskOverdueService({
    TaskRepository? taskRepository,
    NotificationService? notificationService,
  }) : _taskRepository = taskRepository ?? TaskRepository(),
        _notificationService = notificationService ?? NotificationService();

  /// Start monitoring for overdue tasks
  void startOverdueMonitoring() {
    // Check for overdue tasks every hour
    _overdueCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndNotifyOverdueTasks(),
    );
  }

  /// Stop monitoring for overdue tasks
  void stopOverdueMonitoring() {
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = null;
  }

  /// Check for overdue tasks and send notifications
  Future<void> _checkAndNotifyOverdueTasks() async {
    try {
      // Get all overdue tasks
      final overdueTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
          .where('status', whereIn: [TaskStatus.pending.name, TaskStatus.in_progress.name])
          .get();

      for (final doc in overdueTasksSnapshot.docs) {
        final task = TaskModel.fromDoc(doc);
        
        // Check if we've already sent an overdue notification for this task
        final lastNotificationCheck = await _getLastOverdueNotification(task.taskId);
        final now = DateTime.now();
        
        // Send notification if:
        // 1. No previous overdue notification was sent, OR
        // 2. Last notification was sent more than 24 hours ago
        if (lastNotificationCheck == null || 
            now.difference(lastNotificationCheck).inHours >= 24) {
          
          await _notificationService.sendTaskOverdueNotification(
            assigneeId: task.assigneeId,
            taskTitle: task.title,
            dueDate: task.dueDate,
            taskId: task.taskId,
          );

          // Record that we sent an overdue notification
          await _recordOverdueNotification(task.taskId);
        }
      }
    } catch (e) {
      print('Error checking overdue tasks: $e');
    }
  }

  /// Get the last time an overdue notification was sent for a task
  Future<DateTime?> _getLastOverdueNotification(String taskId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('task_overdue_notifications')
          .doc(taskId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['lastNotificationSent'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      print('Error getting last overdue notification: $e');
      return null;
    }
  }

  /// Record that an overdue notification was sent
  Future<void> _recordOverdueNotification(String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('task_overdue_notifications')
          .doc(taskId)
          .set({
        'taskId': taskId,
        'lastNotificationSent': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error recording overdue notification: $e');
    }
  }

  /// Manually check for overdue tasks (can be called from UI)
  Future<List<TaskModel>> getOverdueTasks() async {
    try {
      final overdueTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
          .where('status', whereIn: [TaskStatus.pending.name, TaskStatus.in_progress.name])
          .orderBy('dueDate')
          .get();

      return overdueTasksSnapshot.docs
          .map((doc) => TaskModel.fromDoc(doc))
          .toList();
    } catch (e) {
      print('Error getting overdue tasks: $e');
      return [];
    }
  }

  /// Get overdue tasks for a specific employee
  Future<List<TaskModel>> getOverdueTasksForEmployee(String employeeId) async {
    try {
      final overdueTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assigneeId', isEqualTo: employeeId)
          .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
          .where('status', whereIn: [TaskStatus.pending.name, TaskStatus.in_progress.name])
          .orderBy('dueDate')
          .get();

      return overdueTasksSnapshot.docs
          .map((doc) => TaskModel.fromDoc(doc))
          .toList();
    } catch (e) {
      print('Error getting overdue tasks for employee: $e');
      return [];
    }
  }

  /// Send immediate overdue notification for a specific task
  Future<void> sendImmediateOverdueNotification(String taskId) async {
    try {
      final task = await _taskRepository.getById(taskId);
      if (task == null) return;

      // Check if task is actually overdue
      if (task.dueDate.isBefore(DateTime.now()) && 
          (task.status == TaskStatus.pending || task.status == TaskStatus.in_progress)) {
        
        await _notificationService.sendTaskOverdueNotification(
          assigneeId: task.assigneeId,
          taskTitle: task.title,
          dueDate: task.dueDate,
          taskId: task.taskId,
        );

        await _recordOverdueNotification(task.taskId);
      }
    } catch (e) {
      print('Error sending immediate overdue notification: $e');
    }
  }
}
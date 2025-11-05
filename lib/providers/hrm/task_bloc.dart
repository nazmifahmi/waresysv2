import 'dart:async';
import '../../models/hrm/task_model.dart';
import '../../models/hrm/employee_model.dart';
import '../../services/hrm/task_repository.dart';

class TaskBloc {
  final TaskRepository _repo;
  final StreamController<String?> _errorController = StreamController.broadcast();
  
  Stream<String?> get error => _errorController.stream;

  TaskBloc({required TaskRepository repository}) : _repo = repository;

  Stream<List<TaskModel>> watchMyTasks(String employeeId) => _repo.watchMyTasks(employeeId);

  Stream<List<TaskModel>> watchAll() => _repo.watchAll();

  /// Watch all tasks with filters
  Stream<List<TaskModel>> watchAllWithFilters({
    String? assigneeId,
    String? reporterId,
    TaskStatus? status,
    TaskPriority? priority,
    bool? isOverdue,
    String orderBy = 'dueDate',
    bool descending = false,
  }) => _repo.watchAllWithFilters(
    assigneeId: assigneeId,
    reporterId: reporterId,
    status: status,
    priority: priority,
    isOverdue: isOverdue,
    orderBy: orderBy,
    descending: descending,
  );

  /// Get all task assignees for filter dropdown
  Future<List<EmployeeModel>> getAllTaskAssignees() => _repo.getAllTaskAssignees();

  /// Get all task reporters for filter dropdown
  Future<List<EmployeeModel>> getAllTaskReporters() => _repo.getAllTaskReporters();

  Future<void> create(TaskModel model) async {
    try {
      await _repo.create(model);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal membuat tugas';
      
      if (e.toString().contains('Assignee not found')) {
        errorMessage = 'Karyawan yang ditugaskan tidak ditemukan';
      } else if (e.toString().contains('Reporter not found')) {
        errorMessage = 'Data pembuat tugas tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  Future<void> setStatus(String taskId, TaskStatus status) async {
    try {
      await _repo.updateStatus(taskId, status);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal mengubah status tugas';
      
      if (e.toString().contains('Task not found')) {
        errorMessage = 'Tugas tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  Future<void> reassignTask(String taskId, String newAssigneeId) async {
    try {
      await _repo.reassignTask(taskId, newAssigneeId);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal mengalihkan tugas';
      
      if (e.toString().contains('Task not found')) {
        errorMessage = 'Tugas tidak ditemukan';
      } else if (e.toString().contains('New assignee not found')) {
        errorMessage = 'Karyawan baru tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel model) async {
    try {
      await _repo.updateTask(model);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal memperbarui tugas';
      
      if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  void dispose() {
    _errorController.close();
  }
}
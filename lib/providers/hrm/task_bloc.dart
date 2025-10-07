import '../../models/hrm/task_model.dart';
import '../../services/hrm/task_repository.dart';

class TaskBloc {
  final TaskRepository _repo;

  TaskBloc({required TaskRepository repository}) : _repo = repository;

  Stream<List<TaskModel>> watchMyTasks(String employeeId) => _repo.watchMyTasks(employeeId);

  Stream<List<TaskModel>> watchAll() => _repo.watchAll();

  Future<void> create(TaskModel model) async {
    await _repo.create(model);
  }

  Future<void> setStatus(String taskId, TaskStatus status) async {
    await _repo.updateStatus(taskId, status);
  }
}
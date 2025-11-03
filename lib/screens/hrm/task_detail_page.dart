import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/hrm/task_model.dart';
import '../../models/hrm/employee_model.dart';
import '../../services/hrm/task_repository.dart';
import '../../services/hrm/employee_repository.dart';
import '../../providers/auth_provider.dart';
import '../../utils/role_utils.dart';
import '../../constants/theme.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;

  const TaskDetailPage({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskRepository _taskRepository;
  late EmployeeRepository _employeeRepository;
  late TaskModel _currentTask;
  List<EmployeeModel> _employees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taskRepository = TaskRepository();
    _employeeRepository = EmployeeRepository();
    _currentTask = widget.task;
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeRepository.getAll();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading employees: $e')),
      );
    }
  }

  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    setState(() => _isLoading = true);
    try {
      final updatedTask = TaskModel(
        taskId: _currentTask.taskId,
        title: _currentTask.title,
        description: _currentTask.description,
        assigneeId: _currentTask.assigneeId,
        reporterId: _currentTask.reporterId,
        dueDate: _currentTask.dueDate,
        priority: _currentTask.priority,
        status: newStatus,
        createdAt: _currentTask.createdAt,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : _currentTask.completedAt,
      );

      await _taskRepository.updateTask(updatedTask);
      setState(() {
        _currentTask = updatedTask;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task status updated to ${newStatus.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task status: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskPriority(TaskPriority newPriority) async {
    setState(() => _isLoading = true);
    try {
      final updatedTask = TaskModel(
        taskId: _currentTask.taskId,
        title: _currentTask.title,
        description: _currentTask.description,
        assigneeId: _currentTask.assigneeId,
        reporterId: _currentTask.reporterId,
        dueDate: _currentTask.dueDate,
        priority: newPriority,
        status: _currentTask.status,
        createdAt: _currentTask.createdAt,
        completedAt: _currentTask.completedAt,
      );

      await _taskRepository.updateTask(updatedTask);
      setState(() {
        _currentTask = updatedTask;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task priority updated to ${newPriority.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task priority: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reassignTask(String newAssigneeId) async {
    setState(() => _isLoading = true);
    try {
      await _taskRepository.reassignTask(_currentTask.taskId, newAssigneeId);
      
      final updatedTask = TaskModel(
        taskId: _currentTask.taskId,
        title: _currentTask.title,
        description: _currentTask.description,
        assigneeId: newAssigneeId,
        reporterId: _currentTask.reporterId,
        dueDate: _currentTask.dueDate,
        priority: _currentTask.priority,
        status: _currentTask.status,
        createdAt: _currentTask.createdAt,
        completedAt: _currentTask.completedAt,
      );

      setState(() {
        _currentTask = updatedTask;
      });

      final assignee = _employees.firstWhere((e) => e.employeeId == newAssigneeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task reassigned to ${assignee.fullName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reassigning task: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Task Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            return ListTile(
              title: Text(status.name.toUpperCase()),
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateTaskStatus(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPriorityUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Task Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) {
            return ListTile(
              title: Text(priority.name.toUpperCase()),
              leading: Icon(
                Icons.flag,
                color: _getPriorityColor(priority),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateTaskPriority(priority);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReassignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Task'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _employees.length,
            itemBuilder: (context, index) {
              final employee = _employees[index];
              final isCurrentAssignee = employee.employeeId == _currentTask.assigneeId;
              
              return ListTile(
                title: Text(employee.fullName),
                subtitle: Text('${employee.position} - ${employee.department}'),
                leading: CircleAvatar(
                  backgroundColor: isCurrentAssignee ? Colors.green : Colors.grey,
                  child: Text(employee.fullName[0]),
                ),
                trailing: isCurrentAssignee ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: isCurrentAssignee ? null : () {
                  Navigator.pop(context);
                  _reassignTask(employee.employeeId);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.in_progress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.in_progress:
        return Icons.work;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignee = _employees.firstWhere(
      (e) => e.employeeId == _currentTask.assigneeId,
      orElse: () => EmployeeModel(
        employeeId: '',
        userId: '',
        fullName: 'Unknown',
        position: '',
        department: '',
        joinDate: DateTime.now(),
        salary: 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'status':
                  _showStatusUpdateDialog();
                  break;
                case 'priority':
                  _showPriorityUpdateDialog();
                  break;
                case 'reassign':
                  _showReassignDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: Icon(Icons.update),
                  title: Text('Update Status'),
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: ListTile(
                  leading: Icon(Icons.flag),
                  title: Text('Update Priority'),
                ),
              ),
              const PopupMenuItem(
                value: 'reassign',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Reassign Task'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentTask.title,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_currentTask.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getStatusColor(_currentTask.status),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(_currentTask.status),
                                      size: 16,
                                      color: _getStatusColor(_currentTask.status),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentTask.status.name.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(_currentTask.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.flag,
                                color: _getPriorityColor(_currentTask.priority),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentTask.priority.name.toUpperCase()} Priority',
                                style: TextStyle(
                                  color: _getPriorityColor(_currentTask.priority),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_currentTask.description),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned to',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          child: Text(assignee.fullName.isNotEmpty ? assignee.fullName[0] : '?'),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                assignee.fullName,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              Text(
                                                assignee.position,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Due Date',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: _currentTask.dueDate.isBefore(DateTime.now()) 
                                              ? Colors.red 
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(_currentTask.dueDate),
                                          style: TextStyle(
                                            color: _currentTask.dueDate.isBefore(DateTime.now()) 
                                                ? Colors.red 
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task Actions for Assignee
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final currentUserId = authProvider.currentUser?.uid;
                      final isAssignee = _employees.any((e) => 
                          e.userId == currentUserId && e.employeeId == _currentTask.assigneeId);
                      
                      if (!isAssignee) return const SizedBox.shrink();
                      
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (_currentTask.status == TaskStatus.pending)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateTaskStatus(TaskStatus.in_progress),
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Start Task'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  if (_currentTask.status == TaskStatus.in_progress) ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateTaskStatus(TaskStatus.completed),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Complete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateTaskStatus(TaskStatus.pending),
                                        icon: const Icon(Icons.pause),
                                        label: const Text('Pause'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
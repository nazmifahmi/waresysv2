import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/task_model.dart';
import '../../providers/hrm/task_bloc.dart';
import '../../providers/theme_provider.dart';
import '../../services/hrm/task_repository.dart';
import '../../constants/theme.dart';
import 'task_detail_page.dart';

class MyTasksPage extends StatefulWidget {
  final String employeeId;
  const MyTasksPage({super.key, required this.employeeId});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late TaskBloc _bloc;
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  bool _showOverdueOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bloc = TaskBloc(repository: TaskRepository());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Menunggu';
      case TaskStatus.in_progress:
        return 'Dikerjakan';
      case TaskStatus.completed:
        return 'Selesai';
      case TaskStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 'Mendesak';
      case TaskPriority.high:
        return 'Tinggi';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.low:
        return 'Rendah';
    }
  }

  bool _isOverdue(TaskModel task) {
    return task.dueDate.isBefore(DateTime.now()) && 
           task.status != TaskStatus.completed && 
           task.status != TaskStatus.cancelled;
  }

  Future<void> _updateTaskStatus(TaskModel task, TaskStatus newStatus) async {
    try {
      await _bloc.setStatus(task.taskId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status tugas berhasil diubah ke ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTaskDetails(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, ThemeProvider themeProvider) {
    final isOverdue = _isOverdue(task);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : null,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeProvider.isDarkMode ? AppTheme.textSecondary : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isOverdue 
                        ? AppTheme.errorColor 
                        : (themeProvider.isDarkMode ? AppTheme.textTertiary : Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(task.dueDate),
                    style: TextStyle(
                      color: isOverdue 
                          ? AppTheme.errorColor 
                          : (themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600]),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(task.status),
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (isOverdue) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 14,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TERLAMBAT',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks, TaskStatus status) {
    var filtered = tasks.where((t) => t.status == status).toList();
    
    if (_filterPriority != null) {
      filtered = filtered.where((t) => t.priority == _filterPriority).toList();
    }
    
    if (_showOverdueOnly) {
      filtered = filtered.where((t) => _isOverdue(t)).toList();
    }
    
    return filtered;
  }

  Widget _buildTaskList(List<TaskModel> tasks, TaskStatus status, ThemeProvider themeProvider) {
    final filteredTasks = _filterTasks(tasks, status);
    
    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: themeProvider.isDarkMode ? AppTheme.textTertiary : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada tugas ${_getStatusText(status).toLowerCase()}',
              style: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) => _buildTaskCard(filteredTasks[index], themeProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : Colors.grey[50],
          appBar: AppBar(
            title: const Text('Tugas Saya'),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Menunggu'),
                Tab(text: 'Dikerjakan'),
                Tab(text: 'Selesai'),
                Tab(text: 'Semua'),
              ],
            ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'priority_urgent':
                    _filterPriority = TaskPriority.urgent;
                    break;
                  case 'priority_high':
                    _filterPriority = TaskPriority.high;
                    break;
                  case 'priority_medium':
                    _filterPriority = TaskPriority.medium;
                    break;
                  case 'priority_low':
                    _filterPriority = TaskPriority.low;
                    break;
                  case 'overdue':
                    _showOverdueOnly = !_showOverdueOnly;
                    break;
                  case 'clear':
                    _filterPriority = null;
                    _showOverdueOnly = false;
                    break;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'priority_urgent',
                child: Text('Prioritas Mendesak'),
              ),
              const PopupMenuItem(
                value: 'priority_high',
                child: Text('Prioritas Tinggi'),
              ),
              const PopupMenuItem(
                value: 'priority_medium',
                child: Text('Prioritas Sedang'),
              ),
              const PopupMenuItem(
                value: 'priority_low',
                child: Text('Prioritas Rendah'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'overdue',
                child: Row(
                  children: [
                    Icon(
                      _showOverdueOnly ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Hanya Terlambat'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Hapus Filter'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _bloc.watchMyTasks(widget.employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          
          final tasks = snapshot.data ?? [];
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(tasks, TaskStatus.pending, themeProvider),
              _buildTaskList(tasks, TaskStatus.in_progress, themeProvider),
              _buildTaskList(tasks, TaskStatus.completed, themeProvider),
              // All tasks tab
              tasks.isEmpty
                  ? const Center(child: Text('Tidak ada tugas'))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => _buildTaskCard(tasks[index], themeProvider),
                    ),
            ],
          );
        },
      ),
        );
      },
    );
  }
}
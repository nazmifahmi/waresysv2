import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/task_model.dart';
import '../../providers/hrm/task_bloc.dart';
import '../../providers/theme_provider.dart';
import '../../services/hrm/task_repository.dart';
import '../../constants/theme.dart';
import 'task_detail_page.dart';

class TaskDashboardPage extends StatefulWidget {
  final String employeeId;
  final bool isManager;
  
  const TaskDashboardPage({
    super.key, 
    required this.employeeId,
    this.isManager = false,
  });

  @override
  State<TaskDashboardPage> createState() => _TaskDashboardPageState();
}

class _TaskDashboardPageState extends State<TaskDashboardPage> {
  late TaskBloc _bloc;
  late TaskRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = TaskRepository();
    _bloc = TaskBloc(repository: _repository);
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeProvider themeProvider,
    VoidCallback? onTap,
  }) {
    return Card(
      color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, ThemeProvider themeProvider) {
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && 
                     task.status != TaskStatus.completed && 
                     task.status != TaskStatus.cancelled;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(task: task),
            ),
          );
        },
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isOverdue 
                ? AppTheme.errorColor 
                : (themeProvider.isDarkMode ? AppTheme.textPrimary : null),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenggat: ${DateFormat('dd MMM yyyy').format(task.dueDate)}',
              style: TextStyle(
                color: isOverdue 
                    ? AppTheme.errorColor 
                    : (themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600]),
                fontSize: 12,
              ),
            ),
            if (isOverdue)
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(task.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(task.status),
            style: TextStyle(
              color: _getStatusColor(task.status),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChart(List<TaskModel> tasks, ThemeProvider themeProvider) {
    final priorityCounts = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      priorityCounts[priority] = tasks.where((t) => t.priority == priority).length;
    }

    return Card(
      color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribusi Prioritas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : null,
              ),
            ),
            const SizedBox(height: 16),
            ...TaskPriority.values.map((priority) {
              final count = priorityCounts[priority] ?? 0;
              final percentage = tasks.isEmpty ? 0.0 : (count / tasks.length);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPriorityText(priority),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? AppTheme.textPrimary : null,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: themeProvider.isDarkMode 
                            ? AppTheme.borderDark 
                            : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(_getPriorityColor(priority)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : Colors.grey[50],
          appBar: AppBar(
            title: Text(widget.isManager ? 'Dashboard Tugas Tim' : 'Dashboard Tugas'),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.primaryGreen : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                FutureBuilder<Map<String, int>>(
                  future: _repository.getTaskStats(widget.employeeId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: themeProvider.isDarkMode ? AppTheme.primaryGreen : Theme.of(context).primaryColor,
                        ),
                      );
                    }
                    
                    final stats = snapshot.data ?? {};
                    
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Total Tugas',
                          value: '${stats['total'] ?? 0}',
                          icon: Icons.assignment,
                          color: Colors.blue,
                          themeProvider: themeProvider,
                        ),
                        _buildStatCard(
                          title: 'Menunggu',
                          value: '${stats['pending'] ?? 0}',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          themeProvider: themeProvider,
                        ),
                        _buildStatCard(
                          title: 'Dikerjakan',
                          value: '${stats['inProgress'] ?? 0}',
                          icon: Icons.work,
                          color: Colors.blue,
                          themeProvider: themeProvider,
                        ),
                        _buildStatCard(
                          title: 'Selesai',
                          value: '${stats['completed'] ?? 0}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          themeProvider: themeProvider,
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Overdue Tasks Alert
                StreamBuilder<List<TaskModel>>(
                  stream: _repository.watchOverdueTasks(),
                  builder: (context, snapshot) {
                    final overdueTasks = snapshot.data ?? [];
                    final myOverdueTasks = widget.isManager 
                        ? overdueTasks 
                        : overdueTasks.where((t) => t.assigneeId == widget.employeeId).toList();
                    
                    if (myOverdueTasks.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Card(
                      color: themeProvider.isDarkMode 
                          ? AppTheme.errorColor.withOpacity(0.2) 
                          : Colors.red.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: AppTheme.errorColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Tugas Terlambat (${myOverdueTasks.length})',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Anda memiliki ${myOverdueTasks.length} tugas yang sudah melewati tenggat waktu.',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Priority Distribution Chart
                StreamBuilder<List<TaskModel>>(
                  stream: widget.isManager 
                      ? _bloc.watchAll() 
                      : _bloc.watchMyTasks(widget.employeeId),
                  builder: (context, snapshot) {
                    final tasks = snapshot.data ?? [];
                    final activeTasks = tasks.where((t) => 
                        t.status != TaskStatus.completed && 
                        t.status != TaskStatus.cancelled
                    ).toList();
                    
                    return _buildPriorityChart(activeTasks, themeProvider);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Recent Tasks
                Text(
                  'Tugas Terbaru',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                StreamBuilder<List<TaskModel>>(
                  stream: widget.isManager 
                      ? _bloc.watchAll() 
                      : _bloc.watchMyTasks(widget.employeeId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final tasks = snapshot.data ?? [];
                    final recentTasks = tasks.take(5).toList();
                    
                    if (recentTasks.isEmpty) {
                      return Card(
                        color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 48,
                                  color: themeProvider.isDarkMode 
                                      ? AppTheme.textTertiary 
                                      : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada tugas',
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode 
                                        ? AppTheme.textSecondary 
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: recentTasks.map((task) => _buildTaskCard(task, themeProvider)).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // View All Tasks Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, 
                        '/hrm/my-tasks',
                        arguments: widget.employeeId,
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Lihat Semua Tugas'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
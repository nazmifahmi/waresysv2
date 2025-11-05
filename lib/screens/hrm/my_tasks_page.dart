import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/task_model.dart';
import '../../models/hrm/employee_model.dart';
import '../../providers/hrm/task_bloc.dart';
import '../../providers/auth_provider.dart';
import '../../services/hrm/task_repository.dart';
import '../../services/auth_service.dart';
import 'task_detail_page.dart';

class MyTasksPage extends StatefulWidget {
  final String? employeeId;
  
  const MyTasksPage({super.key, this.employeeId});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late TaskBloc _bloc;
  
  // Filter variables
  TaskPriority? _filterPriority;
  String? _filterAssigneeId;
  String? _filterReporterId;
  bool _showOverdueOnly = false;
  bool _showAllTasks = true;
  String _orderBy = 'dueDate';
  bool _descending = false;
  
  // Employee lists for filters
  List<EmployeeModel> _assignees = [];
  List<EmployeeModel> _reporters = [];
  bool _loadingFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bloc = TaskBloc(repository: TaskRepository());
    _loadFilterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterData() async {
    setState(() => _loadingFilters = true);
    try {
      final assignees = await _bloc.getAllTaskAssignees();
      final reporters = await _bloc.getAllTaskReporters();
      setState(() {
        _assignees = assignees;
        _reporters = reporters;
        _loadingFilters = false;
      });
    } catch (e) {
      setState(() => _loadingFilters = false);
    }
  }

  // Method untuk mendapatkan stream yang konsisten berdasarkan tab dan filter
  Stream<List<TaskModel>> _getTaskStream(String currentEmployeeId, {TaskStatus? statusFilter}) {
    if (_showAllTasks) {
      return _bloc.watchAllWithFilters(
        assigneeId: _filterAssigneeId,
        reporterId: _filterReporterId,
        status: statusFilter,
        priority: _filterPriority,
        isOverdue: _showOverdueOnly ? true : null,
        orderBy: _orderBy,
        descending: _descending,
      ).handleError((error) {
        print('Error in watchAllWithFilters: $error');
        return <TaskModel>[];
      });
    } else {
      // Untuk "My Tasks", kita tetap gunakan watchMyTasks tapi filter di UI
      return _bloc.watchMyTasks(currentEmployeeId).map((tasks) {
        try {
          var filteredTasks = List<TaskModel>.from(tasks);
          
          // Apply status filter
          if (statusFilter != null) {
            filteredTasks = filteredTasks.where((task) => task.status == statusFilter).toList();
          }
          
          // Apply priority filter
          if (_filterPriority != null) {
            filteredTasks = filteredTasks.where((task) => task.priority == _filterPriority).toList();
          }
          
          // Apply overdue filter
          if (_showOverdueOnly) {
            filteredTasks = filteredTasks.where((task) => _isOverdue(task)).toList();
          }
          
          // Apply sorting
          filteredTasks.sort((a, b) {
            int comparison = 0;
            switch (_orderBy) {
              case 'dueDate':
                comparison = a.dueDate.compareTo(b.dueDate);
                break;
              case 'priority':
                comparison = a.priority.index.compareTo(b.priority.index);
                break;
              case 'createdAt':
                comparison = a.createdAt.compareTo(b.createdAt);
                break;
              case 'title':
                comparison = a.title.compareTo(b.title);
                break;
            }
            return _descending ? -comparison : comparison;
          });
          
          return filteredTasks;
        } catch (e) {
          print('Error in task filtering: $e');
          return tasks; // Return original tasks if filtering fails
        }
      }).handleError((error) {
        print('Error in watchMyTasks: $error');
        return <TaskModel>[];
      });
    }
  }

  void _refreshData() {
    setState(() {
      // Trigger rebuild untuk semua StreamBuilder
    });
  }

  bool _hasActiveFilters() {
    return _filterPriority != null ||
           _filterAssigneeId != null ||
           _filterReporterId != null ||
           _showOverdueOnly ||
           !_showAllTasks ||
           _orderBy != 'dueDate' ||
           _descending;
  }

  void _resetFilters() {
    setState(() {
      _filterPriority = null;
      _filterAssigneeId = null;
      _filterReporterId = null;
      _showOverdueOnly = false;
      _orderBy = 'dueDate';
      _descending = false;
    });
    _refreshData();
  }

  String _getStatusText(TaskModel task) {
    switch (task.status) {
      case TaskStatus.pending:
        return 'Menunggu';
      case TaskStatus.in_progress:
        return 'Sedang Dikerjakan';
      case TaskStatus.completed:
        return 'Selesai';
      case TaskStatus.cancelled:
        return 'Dibatalkan';
      default:
        return 'Tidak Diketahui';
    }
  }

  String _getPriorityText(TaskModel task) {
    switch (task.priority) {
      case TaskPriority.low:
        return 'Rendah';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.high:
        return 'Tinggi';
      case TaskPriority.urgent:
        return 'Mendesak';
      default:
        return 'Tidak Diketahui';
    }
  }

  bool _isOverdue(TaskModel task) {
    return task.dueDate.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;
  }

  void _showTaskDetails(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final isOverdue = _isOverdue(task);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPriorityText(task),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(task.dueDate),
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TERLAMBAT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(task),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.in_progress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada tugas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Tugas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Show only my tasks toggle
            SwitchListTile(
              title: const Text('Hanya Tugas Saya'),
              subtitle: const Text('Tampilkan hanya tugas yang ditugaskan kepada saya'),
              value: !_showAllTasks,
              onChanged: (value) {
                setState(() {
                  _showAllTasks = !value;
                  // Reset assignee and reporter filters when switching to "My Tasks Only"
                  if (!_showAllTasks) {
                    _filterAssigneeId = null;
                    _filterReporterId = null;
                  }
                });
                _refreshData();
                Navigator.pop(context);
              },
            ),
            
            const Divider(),
            
            // Priority filter
            ListTile(
              title: const Text('Filter Prioritas'),
              subtitle: Text(_filterPriority?.name ?? 'Semua'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showPriorityFilter(),
            ),
            
            // Assignee filter (only when showing all tasks)
            if (_showAllTasks) ...[
              ListTile(
                title: const Text('Filter Assignee'),
                subtitle: Text(_getAssigneeName(_filterAssigneeId) ?? 'Semua'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showAssigneeFilter(),
              ),
              
              ListTile(
                title: const Text('Filter Reporter'),
                subtitle: Text(_getReporterName(_filterReporterId) ?? 'Semua'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showReporterFilter(),
              ),
            ],
            
            // Overdue filter
            SwitchListTile(
              title: const Text('Hanya Tugas Terlambat'),
              value: _showOverdueOnly,
              onChanged: (value) {
                setState(() => _showOverdueOnly = value);
                _refreshData();
              },
            ),
            
            const Divider(),
            
            // Sort options
            ListTile(
              title: const Text('Urutkan'),
              subtitle: Text('${_getSortText(_orderBy)} (${_descending ? 'Menurun' : 'Menaik'})'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showSortOptions(),
            ),
            
            const SizedBox(height: 16),
            
            // Clear filters button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _resetFilters();
                  Navigator.pop(context);
                },
                child: const Text('Hapus Semua Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getAssigneeName(String? assigneeId) {
    if (assigneeId == null) return null;
    final idx = _assignees.indexWhere((e) => e.employeeId == assigneeId);
    if (idx == -1) return 'Unknown';
    return _assignees[idx].fullName;
  }

  String? _getReporterName(String? reporterId) {
    if (reporterId == null) return null;
    final idx = _reporters.indexWhere((e) => e.employeeId == reporterId);
    if (idx == -1) return 'Unknown';
    return _reporters[idx].fullName;
  }

  String _getSortText(String orderBy) {
    switch (orderBy) {
      case 'dueDate':
        return 'Tanggal Jatuh Tempo';
      case 'priority':
        return 'Prioritas';
      case 'createdAt':
        return 'Tanggal Dibuat';
      case 'title':
        return 'Judul';
      default:
        return orderBy;
    }
  }

  void _showPriorityFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Prioritas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<TaskPriority?>(
              title: const Text('Semua'),
              value: null,
              groupValue: _filterPriority,
              onChanged: (value) {
                setState(() => _filterPriority = value);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<TaskPriority?>(
              title: const Text('Mendesak'),
              value: TaskPriority.urgent,
              groupValue: _filterPriority,
              onChanged: (value) {
                setState(() => _filterPriority = value);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<TaskPriority?>(
              title: const Text('Tinggi'),
              value: TaskPriority.high,
              groupValue: _filterPriority,
              onChanged: (value) {
                setState(() => _filterPriority = value);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<TaskPriority?>(
              title: const Text('Sedang'),
              value: TaskPriority.medium,
              groupValue: _filterPriority,
              onChanged: (value) {
                setState(() => _filterPriority = value);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<TaskPriority?>(
              title: const Text('Rendah'),
              value: TaskPriority.low,
              groupValue: _filterPriority,
              onChanged: (value) {
                setState(() => _filterPriority = value);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssigneeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Assignee'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: const Text('Semua'),
                value: null,
                groupValue: _filterAssigneeId,
                onChanged: (value) {
                  setState(() => _filterAssigneeId = value);
                  _refreshData();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
              ..._assignees.map((assignee) => RadioListTile<String?>(
                title: Text(assignee.fullName),
                value: assignee.employeeId,
                groupValue: _filterAssigneeId,
                onChanged: (value) {
                  setState(() => _filterAssigneeId = value);
                  _refreshData();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showReporterFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reporter'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: const Text('Semua'),
                value: null,
                groupValue: _filterReporterId,
                onChanged: (value) {
                  setState(() => _filterReporterId = value);
                  _refreshData();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
              ..._reporters.map((reporter) => RadioListTile<String?>(
                title: Text(reporter.fullName),
                value: reporter.employeeId,
                groupValue: _filterReporterId,
                onChanged: (value) {
                  setState(() => _filterReporterId = value);
                  _refreshData();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urutkan Berdasarkan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tanggal Jatuh Tempo'),
              value: 'dueDate',
              groupValue: _orderBy,
              onChanged: (value) {
                setState(() => _orderBy = value!);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Prioritas'),
              value: 'priority',
              groupValue: _orderBy,
              onChanged: (value) {
                setState(() => _orderBy = value!);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Tanggal Dibuat'),
              value: 'createdAt',
              groupValue: _orderBy,
              onChanged: (value) {
                setState(() => _orderBy = value!);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Judul'),
              value: 'title',
              groupValue: _orderBy,
              onChanged: (value) {
                setState(() => _orderBy = value!);
                _refreshData();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Urutan Menurun'),
              value: _descending,
              onChanged: (value) {
                setState(() => _descending = value);
                _refreshData();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        final currentEmployeeId = widget.employeeId ?? user?.uid;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tugas'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Menunggu'),
                Tab(text: 'Dikerjakan'),
                Tab(text: 'Selesai'),
              ],
            ),
            actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All tasks tab
          StreamBuilder<List<TaskModel>>(
            stream: _getTaskStream(currentEmployeeId ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return _buildTaskList(snapshot.data ?? []);
            },
          ),
          // Pending tasks tab
          StreamBuilder<List<TaskModel>>(
            stream: _getTaskStream(currentEmployeeId ?? '', statusFilter: TaskStatus.pending),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return _buildTaskList(snapshot.data ?? []);
            },
          ),
          // In progress tasks tab
          StreamBuilder<List<TaskModel>>(
            stream: _getTaskStream(currentEmployeeId ?? '', statusFilter: TaskStatus.in_progress),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return _buildTaskList(snapshot.data ?? []);
            },
          ),
          // Completed tasks tab
          StreamBuilder<List<TaskModel>>(
            stream: _getTaskStream(currentEmployeeId ?? '', statusFilter: TaskStatus.completed),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return _buildTaskList(snapshot.data ?? []);
            },
          ),
        ],
      ),
    );
      },
    );
  }
}
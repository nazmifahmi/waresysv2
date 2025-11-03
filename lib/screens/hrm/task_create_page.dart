import 'package:flutter/material.dart';
import '../../models/hrm/task_model.dart';
import '../../providers/hrm/task_bloc.dart';
import '../../services/hrm/task_repository.dart';
import '../../services/hrm/employee_repository.dart';
import '../../models/hrm/employee_model.dart';

class TaskCreatePage extends StatefulWidget {
  final String reporterId;
  const TaskCreatePage({super.key, required this.reporterId});

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  String? _assigneeId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _saving = false;

  final TaskBloc _bloc = TaskBloc(repository: TaskRepository());
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  List<EmployeeModel> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await _employeeRepo.getAll();
      setState(() => _employees = list.where((e) => e.status == EmployeeStatus.active).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data karyawan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Rendah';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.high:
        return 'Tinggi';
      case TaskPriority.urgent:
        return 'Mendesak';
    }
  }

  Future<void> _create() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check due date
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tenggat waktu tugas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    
    try {
      final task = TaskModel(
        taskId: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        assigneeId: _assigneeId!,
        reporterId: widget.reporterId,
        dueDate: _dueDate!,
        priority: _selectedPriority,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );
      
      await _bloc.create(task);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat tugas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tugas')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Title Field
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                border: OutlineInputBorder(),
                hintText: 'Masukkan judul tugas...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tugas harus diisi';
                }
                if (value.trim().length < 3) {
                  return 'Judul tugas minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description Field
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Tugas',
                border: OutlineInputBorder(),
                hintText: 'Jelaskan detail tugas...',
              ),
              minLines: 3,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi tugas harus diisi';
                }
                if (value.trim().length < 10) {
                  return 'Deskripsi tugas minimal 10 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Priority Selection
            DropdownButtonFormField<TaskPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Prioritas',
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values.map((priority) => 
                DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityText(priority)),
                )
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Assignee Selection
            DropdownButtonFormField<String>(
              value: _assigneeId,
              decoration: const InputDecoration(
                labelText: 'Ditugaskan Kepada',
                border: OutlineInputBorder(),
              ),
              items: _employees.map((e) => 
                DropdownMenuItem(
                  value: e.employeeId, 
                  child: Text('${e.fullName} - ${e.position}'),
                )
              ).toList(),
              onChanged: (v) => setState(() => _assigneeId = v),
              validator: (value) => value == null ? 'Pilih karyawan yang ditugaskan' : null,
            ),
            const SizedBox(height: 16),
            
            // Due Date Selection
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tenggat Waktu',
                      border: const OutlineInputBorder(),
                      errorText: _dueDate == null ? 'Pilih tenggat waktu' : null,
                    ),
                    child: Text(_dueDate != null 
                      ? _dueDate!.toLocal().toString().split(' ').first 
                      : 'Belum dipilih'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? now.add(const Duration(days: 1)),
                      firstDate: now,
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _create,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Membuat Tugas...'),
                      ],
                    )
                  : const Text('Buat Tugas'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
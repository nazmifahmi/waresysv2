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
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  String? _assigneeId;
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
    final list = await _employeeRepo.getAll();
    setState(() => _employees = list.where((e) => e.status == EmployeeStatus.active).toList());
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty || _assigneeId == null || _dueDate == null) return;
    setState(() => _saving = true);
    final model = TaskModel(
      taskId: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      assigneeId: _assigneeId!,
      reporterId: widget.reporterId,
      dueDate: _dueDate!,
    );
    await _bloc.create(model);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Judul')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi'), minLines: 2, maxLines: 4),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _assigneeId,
            decoration: const InputDecoration(labelText: 'Karyawan'),
            items: _employees.map((e) => DropdownMenuItem(value: e.employeeId, child: Text(e.fullName))).toList(),
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tenggat'),
                  child: Text(_dueDate != null ? _dueDate!.toLocal().toString().split(' ').first : 'Belum dipilih'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 2),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: const Text('Pilih'),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _saving ? null : _create, child: Text(_saving ? 'Menyimpan...' : 'Buat Tugas')),
          ),
        ]),
      ),
    );
  }
}
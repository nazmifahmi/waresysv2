import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/hrm/employee_model.dart';
import '../../providers/hrm/employee_bloc.dart';
import '../../services/hrm/employee_repository.dart';
import '../../services/hrm/storage_upload_service.dart';

class EmployeeFormPage extends StatefulWidget {
  final EmployeeModel? existing;
  const EmployeeFormPage({super.key, this.existing});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  DateTime? _joinDate;
  String _status = EmployeeStatus.active.name;
  String? _contractUrl;
  bool _saving = false;

  late final EmployeeBloc _bloc;
  final StorageUploadService _uploader = StorageUploadService();

  @override
  void initState() {
    super.initState();
    _bloc = EmployeeBloc(repository: EmployeeRepository());
    final e = widget.existing;
    if (e != null) {
      _fullNameCtrl.text = e.fullName;
      _positionCtrl.text = e.position;
      _salaryCtrl.text = e.salary.toStringAsFixed(2);
      _joinDate = e.joinDate;
      _status = e.status.name;
      _contractUrl = e.contractUrl;
    }
  }

  Future<void> _pickContract() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res != null && res.files.single.path != null) {
      final file = File(res.files.single.path!);
      final id = widget.existing?.employeeId ?? 'temp';
      final url = await _uploader.uploadEmployeeContract(employeeId: id, file: file);
      setState(() => _contractUrl = url);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _joinDate == null) return;
    setState(() => _saving = true);
    final model = EmployeeModel(
      employeeId: widget.existing?.employeeId ?? '',
      userId: widget.existing?.userId ?? '',
      fullName: _fullNameCtrl.text.trim(),
      position: _positionCtrl.text.trim(),
      joinDate: _joinDate!,
      salary: double.tryParse(_salaryCtrl.text.trim()) ?? 0,
      contractUrl: _contractUrl,
      status: EmployeeStatus.values.firstWhere((e) => e.name == _status),
    );
    if (widget.existing == null) {
      final id = await _bloc.create(model);
      if (_contractUrl != null && !_contractUrl!.contains(id)) {
        // no-op; in real app you might re-upload with final employeeId
      }
    } else {
      await _bloc.update(model);
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Karyawan' : 'Tambah Karyawan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _positionCtrl,
              decoration: const InputDecoration(labelText: 'Jabatan'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salaryCtrl,
              decoration: const InputDecoration(labelText: 'Gaji Pokok'),
              keyboardType: TextInputType.number,
              validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Tidak valid' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal Masuk'),
                    child: Text(_joinDate != null ? _joinDate!.toLocal().toString().split(' ').first : 'Belum dipilih'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _joinDate ?? now,
                      firstDate: DateTime(now.year - 20),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) setState(() => _joinDate = picked);
                  },
                  child: const Text('Pilih'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: EmployeeStatus.values
                  .map((e) => DropdownMenuItem(value: e.name, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? EmployeeStatus.active.name),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(_contractUrl ?? 'Belum ada kontrak terunggah')),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickContract,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Kontrak'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : (isEdit ? 'Simpan Perubahan' : 'Tambah')),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
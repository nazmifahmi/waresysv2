import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/employee_model.dart';
import '../../providers/hrm/employee_bloc.dart';
import '../../providers/theme_provider.dart';
import '../../services/hrm/employee_repository.dart';
import '../../services/hrm/storage_upload_service.dart';
import '../../constants/theme.dart';
import '../../constants/company_standards.dart';

class EmployeeFormPage extends StatefulWidget {
  final EmployeeModel? existing;
  const EmployeeFormPage({super.key, this.existing});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  DateTime? _joinDate;
  String _status = EmployeeStatus.active.name;
  String? _position;
  String? _department;
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
      _position = e.position;
      _department = e.department;
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
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _joinDate == null) return;
    setState(() => _saving = true);
    
    try {
      final model = EmployeeModel(
        employeeId: widget.existing?.employeeId ?? '',
        userId: widget.existing?.userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: _fullNameCtrl.text.trim(),
        position: _position ?? '',
        department: _department ?? '',
        joinDate: _joinDate!,
        salary: double.tryParse(_salaryCtrl.text.trim()) ?? 0,
        contractUrl: _contractUrl,
        status: EmployeeStatus.values.firstWhere((e) => e.name == _status),
      );
      
      if (widget.existing == null) {
        final id = await _bloc.create(model);
        if (_contractUrl != null && !_contractUrl!.contains(id)) {
          // Re-upload contract with correct employee ID if needed
          final file = File(_contractUrl!);
          if (await file.exists()) {
            final newUrl = await _uploader.uploadEmployeeContract(employeeId: id, file: file);
            final updatedModel = EmployeeModel(
              employeeId: id,
              userId: model.userId,
              fullName: model.fullName,
              position: model.position,
              department: model.department,
              joinDate: model.joinDate,
              salary: model.salary,
              contractUrl: newUrl,
              status: model.status,
            );
            await _bloc.update(updatedModel);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Karyawan berhasil ditambahkan')),
          );
        }
      } else {
        await _bloc.update(model);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data karyawan berhasil diperbarui')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
            title: Text(
              isEdit ? 'Edit Karyawan' : 'Tambah Karyawan',
              style: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _fullNameCtrl,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _position,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  dropdownColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Jabatan',
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  items: CompanyStandards.positions
                      .map((position) => DropdownMenuItem(
                            value: position,
                            child: Text(
                              position,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _position = value),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _department,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  dropdownColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Departemen',
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  items: CompanyStandards.departments
                      .map((department) => DropdownMenuItem(
                            value: department,
                            child: Text(
                              department,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _department = value),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salaryCtrl,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Gaji Pokok',
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Tidak valid' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Masuk',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _joinDate != null ? _joinDate!.toLocal().toString().split(' ').first : 'Belum dipilih',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: themeProvider.isDarkMode
                                    ? ColorScheme.dark(
                                        primary: AppTheme.primaryGreen,
                                        surface: AppTheme.cardDark,
                                        onSurface: AppTheme.textPrimary,
                                      )
                                    : ColorScheme.light(
                                        primary: AppTheme.accentBlue,
                                        surface: Colors.white,
                                        onSurface: AppTheme.textPrimaryLight,
                                      ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setState(() => _joinDate = picked);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Pilih'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  dropdownColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                    filled: true,
                    fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  items: EmployeeStatus.values
                      .map((e) => DropdownMenuItem(
                            value: e.name,
                            child: Text(
                              e.name,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? EmployeeStatus.active.name),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _contractUrl ?? 'Belum ada kontrak terunggah',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickContract,
                        icon: Icon(
                          Icons.upload_file,
                          color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                        ),
                        label: Text(
                          'Upload Kontrak',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Menyimpan...'),
                            ],
                          )
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambah'),
                  ),
                )
              ]),
            ),
          ),
        );
      },
    );
  }
}
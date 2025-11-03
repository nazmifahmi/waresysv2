import 'package:flutter/material.dart';
import '../../models/hrm/leave_request_model.dart';
import '../../providers/hrm/leave_bloc.dart';
import '../../services/hrm/leave_repository.dart';

class LeaveRequestPage extends StatefulWidget {
  final String employeeId;
  const LeaveRequestPage({super.key, required this.employeeId});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTimeRange? _range;
  LeaveType _selectedLeaveType = LeaveType.annual;
  late final LeaveBloc _bloc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bloc = LeaveBloc(repository: LeaveRepository());
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _getLeaveTypeText(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return 'Cuti Tahunan';
      case LeaveType.sick:
        return 'Cuti Sakit';
      case LeaveType.emergency:
        return 'Cuti Darurat';
      case LeaveType.maternity:
        return 'Cuti Melahirkan';
      case LeaveType.paternity:
        return 'Cuti Ayah';
      case LeaveType.lainnya:
        return 'Lainnya';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _range == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field yang diperlukan')),
      );
      return;
    }
    
    setState(() => _saving = true);
    
    try {
      final model = LeaveRequestModel(
        requestId: '',
        employeeId: widget.employeeId,
        startDate: _range!.start,
        endDate: _range!.end,
        reason: _reasonCtrl.text.trim(),
        leaveType: _selectedLeaveType,
        submissionDate: DateTime.now(),
      );
      
      await _bloc.submit(model);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan cuti berhasil dikirim')),
        );
        Navigator.pop(context);
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Cuti')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Leave Type Selection
            DropdownButtonFormField<LeaveType>(
              value: _selectedLeaveType,
              decoration: const InputDecoration(
                labelText: 'Jenis Cuti',
                border: OutlineInputBorder(),
              ),
              items: LeaveType.values.map((type) => 
                DropdownMenuItem(
                  value: type,
                  child: Text(_getLeaveTypeText(type)),
                )
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLeaveType = value);
                }
              },
              validator: (value) => value == null ? 'Pilih jenis cuti' : null,
            ),
            const SizedBox(height: 16),
            
            // Date Range Selection
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Rentang Tanggal',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_range == null 
                      ? 'Pilih rentang tanggal' 
                      : '${_range!.start.toLocal().toString().split(' ').first} - ${_range!.end.toLocal().toString().split(' ').first}'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: now,
                      lastDate: DateTime(now.year + 1),
                      initialDateRange: _range ?? DateTimeRange(start: now, end: now.add(const Duration(days: 1))),
                    );
                    if (picked != null) setState(() => _range = picked);
                  },
                  child: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reason Field
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan Cuti',
                border: OutlineInputBorder(),
                hintText: 'Jelaskan alasan pengajuan cuti...',
              ),
              minLines: 3,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alasan cuti harus diisi';
                }
                if (value.trim().length < 10) {
                  return 'Alasan cuti minimal 10 karakter';
                }
                return null;
              },
            ),
            
            const Spacer(),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
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
                        Text('Mengirim...'),
                      ],
                    )
                  : const Text('Kirim Pengajuan'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
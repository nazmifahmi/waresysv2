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
  DateTimeRange? _range;
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

  Future<void> _submit() async {
    if (_range == null || _reasonCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final model = LeaveRequestModel(
      requestId: '',
      employeeId: widget.employeeId,
      startDate: _range!.start,
      endDate: _range!.end,
      reason: _reasonCtrl.text.trim(),
    );
    await _bloc.submit(model);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Cuti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            children: [
              Expanded(child: Text(_range == null ? 'Pilih rentang tanggal' : '${_range!.start.toLocal().toString().split(' ').first} - ${_range!.end.toLocal().toString().split(' ').first}')),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: _range ?? DateTimeRange(start: now, end: now.add(const Duration(days: 1))),
                  );
                  if (picked != null) setState(() => _range = picked);
                },
                child: const Text('Pilih Tanggal'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'Alasan'),
            minLines: 2,
            maxLines: 4,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Mengirim...' : 'Kirim Pengajuan'),
            ),
          ),
        ]),
      ),
    );
  }
}
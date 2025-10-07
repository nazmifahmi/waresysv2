import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/hrm/employee_model.dart';
import '../../models/hrm/payroll_model.dart';
import '../../services/hrm/employee_repository.dart';
import '../../services/hrm/payroll_service.dart';
import '../../services/hrm/storage_upload_service.dart';

class PayrollProcessPage extends StatefulWidget {
  final DateTime month;
  final String periodLabel;
  const PayrollProcessPage({super.key, required this.month, required this.periodLabel});

  @override
  State<PayrollProcessPage> createState() => _PayrollProcessPageState();
}

class _PayrollProcessPageState extends State<PayrollProcessPage> {
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  final PayrollService _payrollService = PayrollService();
  final StorageUploadService _uploader = StorageUploadService();

  List<EmployeeModel> _employees = [];
  bool _loading = true;
  final Map<String, PayrollModel> _preview = {};
  final Map<String, bool> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final all = await _employeeRepo.getAll();
    setState(() {
      _employees = all.where((e) => e.status == EmployeeStatus.active).toList();
      _selected.addEntries(_employees.map((e) => MapEntry(e.employeeId, true)));
      _loading = false;
    });
  }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    _preview.clear();
    for (final e in _employees) {
      if (_selected[e.employeeId] != true) continue;
      final p = await _payrollService.calculateSalary(
        employeeId: e.employeeId,
        periodLabel: widget.periodLabel,
        baseSalary: e.salary,
        month: widget.month,
      );
      _preview[e.employeeId] = p;
    }
    setState(() => _loading = false);
  }

  Future<void> _commit() async {
    setState(() => _loading = true);
    for (final entry in _preview.entries) {
      final p = entry.value;
      final id = await _payrollService.savePayroll(p);
      // If you generate payslip PDF file externally, upload here and update URL.
      // Example placeholder: no file generated in this snippet.
      // await _payrollService.updatePayslipUrl(id, url);
    }
    if (mounted) setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proses Gaji')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text('Periode: ${widget.periodLabel}')),
                      ElevatedButton(onPressed: _calculate, child: const Text('Hitung')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _preview.isEmpty ? null : _commit, child: const Text('Proses')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, i) {
                      final e = _employees[i];
                      final preview = _preview[e.employeeId];
                      return CheckboxListTile(
                        value: _selected[e.employeeId] ?? false,
                        onChanged: (v) => setState(() => _selected[e.employeeId] = v ?? false),
                        title: Text(e.fullName),
                        subtitle: Text(preview == null
                            ? 'Gaji pokok: ${e.salary.toStringAsFixed(2)}'
                            : 'Net: ${preview.netSalary.toStringAsFixed(2)} (Potongan: ${preview.totalDeductions.toStringAsFixed(2)}, Tunjangan: ${preview.totalAllowances.toStringAsFixed(2)})'),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}
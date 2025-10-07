import 'package:flutter/material.dart';
import '../../models/hrm/payroll_model.dart';
import '../../services/hrm/payroll_service.dart';

class PayrollHistoryPage extends StatelessWidget {
  final String employeeId;
  const PayrollHistoryPage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final service = PayrollService();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Gaji')),
      body: StreamBuilder<List<PayrollModel>>(
        stream: service.watchByEmployee(employeeId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Belum ada riwayat gaji.'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final p = data[i];
              return ListTile(
                title: Text(p.period),
                subtitle: Text('Net: ${p.netSalary.toStringAsFixed(2)}'),
                trailing: p.payslipUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // Use url_launcher or open_filex to download/open
                        },
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
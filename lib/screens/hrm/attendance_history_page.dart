import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/attendance_model.dart';
import '../../services/hrm/attendance_repository.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final String employeeId;
  final DateTime month;
  const AttendanceHistoryPage({super.key, required this.employeeId, required this.month});

  @override
  Widget build(BuildContext context) {
    final repo = AttendanceRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: repo.watchMonthly(employeeId, month),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Belum ada data absensi.'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final a = data[i];
              final inStr = a.checkInTimestamp?.toLocal().toString().split('.').first ?? '-';
              final outStr = a.checkOutTimestamp?.toLocal().toString().split('.').first ?? '-';
              return ListTile(
                leading: Icon(a.status == AttendanceStatus.late ? Icons.warning_amber : Icons.check_circle, color: a.status == AttendanceStatus.late ? Colors.orange : Colors.green),
                title: Text('Check-In: $inStr'),
                subtitle: Text('Check-Out: $outStr'),
              );
            },
          );
        },
      ),
    );
  }
}
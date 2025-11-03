import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/attendance_model.dart';
import '../../services/hrm/attendance_repository.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final String employeeId;
  final DateTime month;
  const AttendanceHistoryPage({super.key, required this.employeeId, required this.month});

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
  }

  String _formatWorkingHours(int? minutes) {
    if (minutes == null) return '-';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final repo = AttendanceRepository();
    print('AttendanceHistory: Loading data for employeeId: $employeeId, month: ${DateFormat('yyyy-MM').format(month)}');
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : Colors.grey[50],
          appBar: AppBar(
            title: Text('Riwayat Absensi - ${DateFormat('MMMM yyyy').format(month)}'),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.primaryGreen : Colors.blue,
            foregroundColor: Colors.white,
          ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: repo.watchMonthly(employeeId, month),
        builder: (context, snapshot) {
          print('AttendanceHistory: Stream state: ${snapshot.connectionState}');
          print('AttendanceHistory: Has data: ${snapshot.hasData}');
          print('AttendanceHistory: Data length: ${snapshot.data?.length ?? 0}');
          print('AttendanceHistory: Error: ${snapshot.error}');
          
          if (snapshot.hasError) {
            print('AttendanceHistory: Error occurred: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data absensi...'),
                ],
              ),
            );
          }
          
          final data = snapshot.data ?? [];
          
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data absensi untuk ${DateFormat('MMMM yyyy').format(month)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data absensi akan muncul setelah Anda melakukan check-in',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = data[i];
              final dateStr = _formatDateTime(a.date);
              final inStr = _formatDateTime(a.checkInTimestamp);
              final outStr = _formatDateTime(a.checkOutTimestamp);
              final workingHoursStr = _formatWorkingHours(a.workingHours);
              
              Color statusColor = Colors.green;
              IconData statusIcon = Icons.check_circle;
              String statusText = 'Hadir';
              
              switch (a.status) {
                case AttendanceStatus.late:
                  statusColor = Colors.orange;
                  statusIcon = Icons.warning_amber;
                  statusText = 'Terlambat';
                  break;
                case AttendanceStatus.absent:
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  statusText = 'Tidak Hadir';
                  break;
                case AttendanceStatus.present:
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusText = 'Hadir';
                  break;
                case null:
                  statusColor = Colors.grey;
                  statusIcon = Icons.help_outline;
                  statusText = 'Tidak Diketahui';
                  break;
              }
              
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check-In',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inStr,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check-Out',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  outStr,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jam Kerja',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  workingHoursStr,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
      },
    );
  }
}
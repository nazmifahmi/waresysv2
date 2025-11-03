import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/hrm/attendance_bloc.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import '../../services/hrm/attendance_repository.dart';
import '../../models/hrm/attendance_model.dart';

class AttendancePage extends StatefulWidget {
  final String employeeId;
  const AttendancePage({super.key, required this.employeeId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late final AttendanceBloc _bloc;
  late final AttendanceRepository _repository;
  String? _error;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _repository = AttendanceRepository();
    _bloc = AttendanceBloc(repository: _repository, employeeId: widget.employeeId);
    _bloc.error.listen((e) => setState(() => _error = e));
    
    // Update time every minute instead of every second to reduce rebuilds
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Widget _buildCurrentTimeCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_currentTime),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('HH:mm:ss').format(_currentTime),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? AppTheme.primaryGreen : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAttendanceCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return StreamBuilder<AttendanceModel?>(
          stream: _repository.watchTodayAttendance(widget.employeeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: themeProvider.isDarkMode ? AppTheme.primaryGreen : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              );
            }

            final attendance = snapshot.data;
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Absensi Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (attendance == null) ...[
                      _buildStatusRow('Check-In', 'Belum Check-In', themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey, themeProvider),
                      _buildStatusRow('Check-Out', 'Belum Check-Out', themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey, themeProvider),
                    ] else ...[
                      _buildStatusRow(
                        'Check-In',
                        attendance.checkInTimestamp != null
                            ? DateFormat('HH:mm').format(attendance.checkInTimestamp!)
                            : 'Belum Check-In',
                        attendance.checkInTimestamp != null ? Colors.green : (themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey),
                        themeProvider,
                      ),
                      _buildStatusRow(
                        'Check-Out',
                        attendance.checkOutTimestamp != null
                            ? DateFormat('HH:mm').format(attendance.checkOutTimestamp!)
                            : 'Belum Check-Out',
                        attendance.checkOutTimestamp != null ? Colors.green : (themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey),
                        themeProvider,
                      ),
                      if (attendance.workingHours != null)
                        _buildStatusRow(
                          'Jam Kerja',
                          '${attendance.workingHours!.toStringAsFixed(1)} jam',
                          Colors.blue,
                          themeProvider,
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(AttendanceButtonState state) {
    switch (state) {
      case AttendanceButtonState.loading:
        return const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator()),
        );
      case AttendanceButtonState.canCheckIn:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _bloc.checkIn,
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text(
              'Check-In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      case AttendanceButtonState.canCheckOut:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _bloc.checkOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Check-Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      case AttendanceButtonState.idle:
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Absensi Hari Ini Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        );
      case AttendanceButtonState.error:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : Colors.grey[50],
          appBar: AppBar(
            title: const Text('Absensi Karyawan'),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.primaryGreen : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildCurrentTimeCard(),
                const SizedBox(height: 8),
                _buildTodayAttendanceCard(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<AttendanceButtonState>(
                    stream: _bloc.state,
                    initialData: AttendanceButtonState.loading,
                    builder: (context, snapshot) {
                      final state = snapshot.data ?? AttendanceButtonState.loading;
                      return Column(
                        children: [
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildActionButton(state),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/theme_provider.dart';
import '../../services/hrm/employee_repository.dart';
import '../../utils/employee_seeder.dart';
import '../../widgets/theme_selector.dart';
import 'employee_list_page.dart';
import 'attendance_page.dart';
import 'attendance_history_page.dart';
import 'leave_request_page.dart';
import 'leave_history_page.dart';
import 'payroll_dashboard_page.dart';
import 'claim_form_page.dart';
import 'claim_history_page.dart';
import 'claim_review_page.dart';
import 'my_tasks_page.dart';
import 'task_create_page.dart';

class HRMHomePage extends StatefulWidget {
  const HRMHomePage({super.key});

  @override
  State<HRMHomePage> createState() => _HRMHomePageState();
}

class _HRMHomePageState extends State<HRMHomePage> {
  final EmployeeRepository _employeeRepository = EmployeeRepository();
  String? _currentEmployeeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentEmployeeId();
  }

  Future<void> _getCurrentEmployeeId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First try to get existing employee
        final employee = await _employeeRepository.getByUserId(user.uid);
        if (employee != null) {
          setState(() {
            _currentEmployeeId = employee.employeeId;
            _isLoading = false;
          });
        } else {
          // If no employee data exists, create one
          print('🔄 No employee data found for user ${user.uid}, creating...');
          final employeeId = await EmployeeSeeder.createEmployeeForCurrentUser();
          if (employeeId != null) {
            setState(() {
              _currentEmployeeId = employeeId;
              _isLoading = false;
            });
          } else {
            // Failed to create employee
            setState(() {
              _currentEmployeeId = null;
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _currentEmployeeId = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting current employee ID: $e');
      setState(() {
        _currentEmployeeId = null;
        _isLoading = false;
      });
    }
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelector(),
    );
  }

  Widget _buildWelcomeHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentBlue.withOpacity(0.1),
            AppTheme.accentPurple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen SDM',
            style: AppTheme.heading2.copyWith(
              color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Kelola karyawan, absensi, cuti, payroll, dan tugas',
            style: AppTheme.bodyMedium.copyWith(
              color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
            appBar: AppBar(
              title: const Text('Human Resource Management'),
              backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  onPressed: () => _showThemeSelector(context),
                ),
              ],
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            ),
          );
        }

        if (_currentEmployeeId == null) {
          return Scaffold(
            backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
            appBar: AppBar(
              title: const Text('Human Resource Management'),
              backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                  onPressed: () => _showThemeSelector(context),
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat data karyawan',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan logout dan login kembali',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Text('Human Resource Management'),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
                onPressed: () => _showThemeSelector(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(themeProvider),
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Employee Management Section
                  _buildSection(
                    context,
                    title: 'Manajemen Karyawan',
                    themeProvider: themeProvider,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.people,
                              title: 'Daftar Karyawan',
                              subtitle: 'Kelola data karyawan',
                              color: AppTheme.accentBlue,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EmployeeListPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.access_time,
                              title: 'Absensi',
                              subtitle: 'Catat kehadiran',
                              color: AppTheme.accentGreen,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendancePage(employeeId: _currentEmployeeId!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.history,
                              title: 'Riwayat Absensi',
                              subtitle: 'Lihat riwayat kehadiran',
                              color: AppTheme.accentOrange,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceHistoryPage(employeeId: _currentEmployeeId!, month: DateTime.now()),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.beach_access,
                              title: 'Pengajuan Cuti',
                              subtitle: 'Ajukan dan kelola cuti',
                              color: AppTheme.accentPurple,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LeaveRequestPage(employeeId: _currentEmployeeId!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.history,
                              title: 'Riwayat Cuti',
                              subtitle: 'Lihat riwayat permohonan cuti',
                              color: AppTheme.accentBlue,
                              themeProvider: themeProvider,
                              onTap: () async {
                                final employee = await _employeeRepository.getByUserId(FirebaseAuth.instance.currentUser!.uid);
                                if (employee != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LeaveHistoryPage(
                                        employeeId: _currentEmployeeId!,
                                        userRole: employee.role,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          const Expanded(child: SizedBox()), // Empty space for symmetry
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Payroll & Claims Section
                  _buildSection(
                    context,
                    title: 'Payroll & Klaim',
                    themeProvider: themeProvider,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.payment,
                              title: 'Payroll',
                              subtitle: 'Kelola gaji karyawan',
                              color: AppTheme.accentGreen,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PayrollDashboardPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.request_quote,
                              title: 'Pengajuan Klaim',
                              subtitle: 'Ajukan klaim biaya',
                              color: AppTheme.accentOrange,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClaimFormPage(employeeId: _currentEmployeeId!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.history_edu,
                              title: 'Riwayat Klaim',
                              subtitle: 'Lihat riwayat klaim',
                              color: AppTheme.accentPurple,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClaimHistoryPage(employeeId: _currentEmployeeId!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.approval,
                              title: 'Review Klaim',
                              subtitle: 'Setujui/tolak klaim',
                              color: AppTheme.accentGreen,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClaimReviewPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          const Expanded(child: SizedBox()), // Empty space
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Task Management Section
                  _buildSection(
                    context,
                    title: 'Manajemen Tugas',
                    themeProvider: themeProvider,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.task_alt,
                              title: 'Tugas Saya',
                              subtitle: 'Lihat tugas yang diberikan',
                              color: AppTheme.accentBlue,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MyTasksPage(employeeId: _currentEmployeeId!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildHRMCard(
                              context,
                              icon: Icons.add_task,
                              title: 'Buat Tugas',
                              subtitle: 'Buat tugas baru',
                              color: AppTheme.accentGreen,
                              themeProvider: themeProvider,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskCreatePage(reporterId: _currentEmployeeId!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.heading3.copyWith(
              color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHRMCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: AppTheme.heading4.copyWith(
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: AppTheme.labelSmall.copyWith(
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import 'employee_list_page.dart';
import 'attendance_page.dart';
import 'attendance_history_page.dart';
import 'leave_request_page.dart';
import 'payroll_process_page.dart';
import 'payroll_history_page.dart';
import 'claim_form_page.dart';
import 'claim_history_page.dart';
import 'claim_review_page.dart';
import 'my_tasks_page.dart';
import 'task_create_page.dart';

class HRMHomePage extends StatelessWidget {
  const HRMHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Human Resource Management'),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen SDM',
                style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Kelola karyawan, absensi, cuti, payroll, dan tugas',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Employee Management Section
              _buildSection(
                context,
                title: 'Manajemen Karyawan',
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendancePage(employeeId: 'current_user'),
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceHistoryPage(employeeId: 'current_user', month: DateTime.now()),
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaveRequestPage(employeeId: 'current_user'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Payroll & Claims Section
              _buildSection(
                context,
                title: 'Payroll & Klaim',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildHRMCard(
                          context,
                          icon: Icons.payment,
                          title: 'Proses Payroll',
                          subtitle: 'Kelola gaji karyawan',
                          color: AppTheme.accentGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayrollProcessPage(month: DateTime.now(), periodLabel: 'Current Month'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildHRMCard(
                          context,
                          icon: Icons.receipt_long,
                          title: 'Riwayat Payroll',
                          subtitle: 'Lihat riwayat gaji',
                          color: AppTheme.accentBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PayrollHistoryPage(employeeId: 'current_user'),
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
                          icon: Icons.request_quote,
                          title: 'Pengajuan Klaim',
                          subtitle: 'Ajukan klaim biaya',
                          color: AppTheme.accentOrange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClaimFormPage(employeeId: 'current_user'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildHRMCard(
                          context,
                          icon: Icons.history_edu,
                          title: 'Riwayat Klaim',
                          subtitle: 'Lihat riwayat klaim',
                          color: AppTheme.accentPurple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClaimHistoryPage(employeeId: 'current_user'),
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
                          icon: Icons.approval,
                          title: 'Review Klaim',
                          subtitle: 'Setujui/tolak klaim',
                          color: AppTheme.accentGreen,
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyTasksPage(employeeId: 'current_user'),
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TaskCreatePage(reporterId: 'current_user'),
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
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.surfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
              style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
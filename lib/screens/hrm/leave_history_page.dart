import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/leave_request_model.dart';
import '../../models/hrm/employee_model.dart';
import '../../providers/hrm/leave_bloc.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import '../../services/hrm/leave_repository.dart';
import '../../services/hrm/employee_repository.dart';

class LeaveHistoryPage extends StatefulWidget {
  final String employeeId;
  final EmployeeRole userRole;

  const LeaveHistoryPage({
    super.key,
    required this.employeeId,
    required this.userRole,
  });

  @override
  State<LeaveHistoryPage> createState() => _LeaveHistoryPageState();
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage> with SingleTickerProviderStateMixin {
  late final LeaveBloc _bloc;
  late final TabController _tabController;
  final EmployeeRepository _employeeRepository = EmployeeRepository();

  @override
  void initState() {
    super.initState();
    _bloc = LeaveBloc(repository: LeaveRepository());
    
    // Show different tabs based on user role
    final tabCount = widget.userRole == EmployeeRole.manager || widget.userRole == EmployeeRole.admin ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  String _getStatusText(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Menunggu';
      case LeaveStatus.approved:
        return 'Disetujui';
      case LeaveStatus.rejected:
        return 'Ditolak';
    }
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Icons.schedule;
      case LeaveStatus.approved:
        return Icons.check_circle;
      case LeaveStatus.rejected:
        return Icons.cancel;
    }
  }

  Future<void> _updateLeaveStatus(String requestId, LeaveStatus status) async {
    try {
      await _bloc.setStatus(requestId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == LeaveStatus.approved 
                ? 'Cuti berhasil disetujui' 
                : 'Cuti berhasil ditolak'
            ),
            backgroundColor: status == LeaveStatus.approved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLeaveCard(LeaveRequestModel leave, {bool showActions = false, ThemeProvider? themeProvider}) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final duration = leave.endDate.difference(leave.startDate).inDays + 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: themeProvider?.isDarkMode == true ? AppTheme.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getLeaveTypeText(leave.leaveType),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(leave.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(leave.status)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(leave.status),
                        size: 16,
                        color: _getStatusColor(leave.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(leave.status),
                        style: TextStyle(
                          color: _getStatusColor(leave.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Date range and duration
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: themeProvider?.isDarkMode == true ? AppTheme.textSecondary : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(leave.startDate)} - ${dateFormat.format(leave.endDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider?.isDarkMode == true ? AppTheme.textPrimary : Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$duration hari',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Reason
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 16, color: themeProvider?.isDarkMode == true ? AppTheme.textSecondary : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    leave.reason,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider?.isDarkMode == true ? AppTheme.textPrimary : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Submission date
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: themeProvider?.isDarkMode == true ? AppTheme.textSecondary : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Diajukan: ${DateFormat('dd MMM yyyy HH:mm').format(leave.submissionDate)}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: themeProvider?.isDarkMode == true ? AppTheme.textSecondary : Colors.grey,
                  ),
                ),
              ],
            ),
            
            // Approval info
            if (leave.status != LeaveStatus.pending && leave.approvedBy != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    leave.status == LeaveStatus.approved ? Icons.check : Icons.close,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${leave.status == LeaveStatus.approved ? 'Disetujui' : 'Ditolak'} oleh: ${leave.approvedBy}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (leave.approvalDate != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 24),
                    Text(
                      'Pada: ${DateFormat('dd MMM yyyy HH:mm').format(leave.approvalDate!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
            
            // Action buttons for managers/admins
            if (showActions && leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateLeaveStatus(leave.requestId, LeaveStatus.rejected),
                      icon: const Icon(Icons.close),
                      label: const Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateLeaveStatus(leave.requestId, LeaveStatus.approved),
                      icon: const Icon(Icons.check),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyLeaveHistory(ThemeProvider themeProvider) {
    return StreamBuilder<List<LeaveRequestModel>>(
      stream: _bloc.watchEmployeeLeaves(widget.employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final leaves = snapshot.data ?? [];
        
        if (leaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat cuti',
                  style: TextStyle(fontSize: 16, color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: leaves.length,
          itemBuilder: (context, index) {
            return _buildLeaveCard(leaves[index], themeProvider: themeProvider);
          },
        );
      },
    );
  }

  Widget _buildPendingApprovals(ThemeProvider themeProvider) {
    return StreamBuilder<List<LeaveRequestModel>>(
      stream: _bloc.watchPending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final pendingLeaves = snapshot.data ?? [];
        
        if (pendingLeaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada cuti yang menunggu persetujuan',
                  style: TextStyle(fontSize: 16, color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pendingLeaves.length,
          itemBuilder: (context, index) {
            return FutureBuilder<EmployeeModel?>(
              future: _employeeRepository.getById(pendingLeaves[index].employeeId),
              builder: (context, employeeSnapshot) {
                final employee = employeeSnapshot.data;
                return Column(
                  children: [
                    if (employee != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.grey.withOpacity(0.1),
                        child: Text(
                          'Pengajuan dari: ${employee.fullName} (${employee.position})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    _buildLeaveCard(pendingLeaves[index], showActions: true, themeProvider: themeProvider),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isManagerOrAdmin = widget.userRole == EmployeeRole.manager || widget.userRole == EmployeeRole.admin;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Text('Riwayat Cuti'),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
            bottom: isManagerOrAdmin ? TabBar(
              controller: _tabController,
              labelColor: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
              unselectedLabelColor: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600],
              tabs: const [
                Tab(text: 'Riwayat Saya'),
                Tab(text: 'Persetujuan'),
              ],
            ) : null,
          ),
          body: isManagerOrAdmin 
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildMyLeaveHistory(themeProvider),
                  _buildPendingApprovals(themeProvider),
                ],
              )
            : _buildMyLeaveHistory(themeProvider),
        );
      },
    );
  }
}
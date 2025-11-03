import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/hrm/employee_model.dart';
import '../../services/hrm/employee_repository.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class EmployeeProfilePage extends StatefulWidget {
  final String employeeId;

  const EmployeeProfilePage({
    super.key,
    required this.employeeId,
  });

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final EmployeeRepository _employeeRepository = EmployeeRepository();
  final TextEditingController _passwordController = TextEditingController();
  
  EmployeeModel? _employee;
  bool _isLoading = true;
  bool _showSalary = false;
  bool _isVerifyingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    setState(() => _isLoading = true);
    try {
      final employee = await _employeeRepository.getById(widget.employeeId);
      setState(() {
        _employee = employee;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Error loading employee data: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _verifyPasswordAndShowSalary() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Verifikasi Password',
          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan password login Anda untuk melihat informasi gaji',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _passwordController.text),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );

    if (password != null && password.isNotEmpty) {
      setState(() => _isVerifyingPassword = true);
      
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Re-authenticate user with their password
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          
          await user.reauthenticateWithCredential(credential);
          
          // If successful, show salary
          setState(() {
            _showSalary = true;
            _isVerifyingPassword = false;
          });
          
          if (mounted) {
            CommonWidgets.showSnackBar(
              context: context,
              message: 'Password berhasil diverifikasi',
              type: SnackBarType.success,
            );
          }
        }
      } catch (e) {
        setState(() => _isVerifyingPassword = false);
        if (mounted) {
          CommonWidgets.showSnackBar(
            context: context,
            message: 'Password salah. Silakan coba lagi.',
            type: SnackBarType.error,
          );
        }
      }
      
      _passwordController.clear();
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getStatusText(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Aktif';
      case EmployeeStatus.inactive:
        return 'Tidak Aktif';
    }
  }

  String _getRoleText(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.employee:
        return 'Karyawan';
      case EmployeeRole.manager:
        return 'Manager';
      case EmployeeRole.admin:
        return 'Admin';
    }
  }

  Color _getStatusColor(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return Colors.green;
      case EmployeeStatus.inactive:
        return Colors.red;
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {Color? valueColor, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSalaryCard() {
    if (_employee == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attach_money,
              color: AppTheme.accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gaji Bulanan',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showSalary 
                    ? _formatCurrency(_employee!.salary)
                    : '••••••••••',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (!_showSalary) ...[
            _isVerifyingPassword
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _verifyPasswordAndShowSalary,
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Tampilkan gaji',
                ),
          ] else ...[
            IconButton(
              onPressed: () => setState(() => _showSalary = false),
              icon: const Icon(Icons.visibility_off),
              tooltip: 'Sembunyikan gaji',
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Profil Karyawan',
          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark,
            ],
          ),
        ),
        child: _isLoading
          ? Center(child: CommonWidgets.buildLoadingIndicator())
          : _employee == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data karyawan tidak ditemukan',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadEmployeeData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _employee!.fullName,
                            style: AppTheme.heading2.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_employee!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(_employee!.status)),
                            ),
                            child: Text(
                              _getStatusText(_employee!.status),
                              style: TextStyle(
                                color: _getStatusColor(_employee!.status),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Employee Information
                    Text(
                      'Informasi Karyawan',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      'ID Karyawan',
                      _employee!.employeeId,
                      Icons.badge_outlined,
                    ),
                    
                    _buildInfoCard(
                      'Jabatan/Posisi',
                      _employee!.position,
                      Icons.work_outline,
                    ),
                    
                    _buildInfoCard(
                      'Departemen',
                      _employee!.department,
                      Icons.business_outlined,
                    ),
                    
                    _buildInfoCard(
                      'Role',
                      _getRoleText(_employee!.role),
                      Icons.admin_panel_settings_outlined,
                    ),
                    
                    _buildInfoCard(
                      'Tanggal Bergabung',
                      DateFormat('dd MMMM yyyy', 'id_ID').format(_employee!.joinDate),
                      Icons.calendar_today_outlined,
                    ),
                    
                    _buildInfoCard(
                      'Sisa Cuti',
                      '${_employee!.leaveBalance} hari',
                      Icons.beach_access_outlined,
                      valueColor: _employee!.leaveBalance > 5 
                        ? Colors.green 
                        : _employee!.leaveBalance > 2 
                          ? Colors.orange 
                          : Colors.red,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Salary Information
                    Text(
                      'Informasi Gaji',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSalaryCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Additional Information
                    if (_employee!.contractUrl != null) ...[
                      Text(
                        'Dokumen',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoCard(
                        'Kontrak Kerja',
                        'Tersedia',
                        Icons.description_outlined,
                        trailing: IconButton(
                          onPressed: () {
                            // TODO: Implement contract viewing
                            CommonWidgets.showSnackBar(
                              context: context,
                              message: 'Fitur melihat kontrak akan segera tersedia',
                              type: SnackBarType.info,
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                          tooltip: 'Lihat kontrak',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
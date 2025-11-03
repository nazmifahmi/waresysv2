import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/payroll_model.dart';
import '../../services/hrm/payroll_service.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';

class PayrollDetailPage extends StatefulWidget {
  final PayrollModel payroll;

  const PayrollDetailPage({Key? key, required this.payroll}) : super(key: key);

  @override
  State<PayrollDetailPage> createState() => _PayrollDetailPageState();
}

class _PayrollDetailPageState extends State<PayrollDetailPage> {
  final PayrollService _payrollService = PayrollService();
  late PayrollModel _payroll;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _payroll = widget.payroll;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      final success = await _payrollService.updatePayrollStatus(_payroll.id, newStatus);
      
      if (success) {
        setState(() {
          _payroll = _payroll.copyWith(status: newStatus);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payroll status updated to ${newStatus.toUpperCase()}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to dashboard to refresh the list
          Navigator.of(context).pop(true); // Return true to indicate update
        }
      } else {
        throw Exception('Failed to update payroll status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePayroll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payroll'),
        content: const Text('Are you sure you want to delete this payroll? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final success = await _payrollService.deletePayroll(_payroll.id);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payroll deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Failed to delete payroll');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting payroll: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Text(
              'Payroll Details',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
            elevation: 0,
            shadowColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: themeProvider.isDarkMode ? AppTheme.borderDark : Colors.grey[200],
              ),
            ),
            actions: [
              if (_payroll.status == 'pending')
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePayroll();
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Delete Payroll',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmployeeInfo(themeProvider),
                const SizedBox(height: 20),
                _buildPayrollInfo(themeProvider),
                const SizedBox(height: 20),
                _buildSalaryBreakdown(themeProvider),
                const SizedBox(height: 20),
                _buildStatusSection(themeProvider),
                const SizedBox(height: 32),
                _buildActionButtons(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeInfo(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode 
                          ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                          : [Colors.blue[500]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Employee Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Full Name', _payroll.employeeName, Icons.badge_outlined, themeProvider),
            const SizedBox(height: 16),
            _buildInfoRow('Position', _payroll.position, Icons.work_outline, themeProvider),
            const SizedBox(height: 16),
            _buildInfoRow('Employee ID', _payroll.employeeId, Icons.numbers_outlined, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollInfo(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode 
                          ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.8)]
                          : [Colors.green[500]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Payroll Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Payroll Date', DateFormat('dd MMMM yyyy').format(_payroll.payrollDate), Icons.calendar_today_outlined, themeProvider),
            const SizedBox(height: 16),
            _buildInfoRow('Created At', DateFormat('dd MMM yyyy, HH:mm').format(_payroll.createdAt), Icons.access_time_outlined, themeProvider),
            if (_payroll.updatedAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow('Last Updated', DateFormat('dd MMM yyyy, HH:mm').format(_payroll.updatedAt!), Icons.update_outlined, themeProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryBreakdown(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode 
                          ? [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.8)]
                          : [Colors.purple[500]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Salary Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSalaryRow('Base Salary', _payroll.baseSalary, themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue[600]!, themeProvider),
            if (_payroll.allowances > 0) ...[
              const SizedBox(height: 12),
              _buildSalaryRow('Allowances', _payroll.allowances, themeProvider.isDarkMode ? AppTheme.accentGreen : Colors.green[600]!, themeProvider),
            ],
            if (_payroll.deductions > 0) ...[
              const SizedBox(height: 12),
              _buildSalaryRow('Deductions', -_payroll.deductions, Colors.red[600]!, themeProvider),
            ],
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.isDarkMode 
                      ? [AppTheme.borderDark, AppTheme.borderDark.withOpacity(0.5)]
                      : [Colors.grey[300]!, Colors.grey[200]!],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSalaryRow('Net Salary', _payroll.netSalary, themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87, themeProvider, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(ThemeProvider themeProvider) {
    Color statusColor;
    IconData statusIcon;
    
    switch (_payroll.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.payment;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      color: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _payroll.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      _getStatusDescription(_payroll.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeProvider themeProvider) {
    if (_payroll.status == 'pending') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _updateStatus('approved'),
              icon: const Icon(Icons.check_circle),
              label: const Text('Approve Payroll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _updateStatus('paid'),
              icon: const Icon(Icons.payment),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.isDarkMode ? AppTheme.accentGreen : Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_payroll.status == 'approved') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _updateStatus('paid'),
          icon: const Icon(Icons.payment),
          label: const Text('Mark as Paid'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.isDarkMode ? AppTheme.accentGreen : Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // No buttons for 'paid' status
    }
  }

  Widget _buildInfoRow(String label, String value, [IconData? icon, ThemeProvider? themeProvider]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider?.isDarkMode == true ? AppTheme.backgroundDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider?.isDarkMode == true ? AppTheme.borderDark : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider?.isDarkMode == true ? AppTheme.accentBlue.withOpacity(0.2) : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: themeProvider?.isDarkMode == true ? AppTheme.accentBlue : Colors.blue[600],
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider?.isDarkMode == true ? AppTheme.textSecondary : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: themeProvider?.isDarkMode == true ? AppTheme.textPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryRow(String label, double amount, Color color, ThemeProvider themeProvider, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isTotal 
            ? (themeProvider.isDarkMode ? AppTheme.accentBlue.withOpacity(0.1) : Colors.blue[50])
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
            ),
          ),
          Text(
            'Rp ${NumberFormat('#,###').format(amount.abs())}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for approval';
      case 'approved':
        return 'Approved and ready for payment';
      case 'paid':
        return 'Payment completed';
      default:
        return 'Unknown status';
    }
  }
}
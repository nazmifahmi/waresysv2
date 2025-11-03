import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/payroll_model.dart';
import '../../services/hrm/payroll_service.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import 'payroll_create_page.dart';
import 'payroll_detail_page.dart';

class PayrollDashboardPage extends StatefulWidget {
  const PayrollDashboardPage({Key? key}) : super(key: key);

  @override
  State<PayrollDashboardPage> createState() => _PayrollDashboardPageState();
}

class _PayrollDashboardPageState extends State<PayrollDashboardPage> {
  final PayrollService _payrollService = PayrollService();
  List<PayrollModel> _payrolls = [];
  Map<String, dynamic> _monthlySummary = {};
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final payrolls = await _payrollService.getAllPayrolls();
      final summary = await _payrollService.getMonthlyPayrollSummary(DateTime.now());
      
      setState(() {
        _payrolls = payrolls;
        _monthlySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payroll data: $e')),
        );
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
            title: Text(
              'Payroll Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.grey[800],
              ),
            ),
            elevation: 0,
            backgroundColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : Colors.white,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.grey[800],
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? AppTheme.accentBlue.withOpacity(0.2) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh, 
                    color: themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue[700],
                  ),
                  onPressed: _isLoading ? null : _loadData,
                ),
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue[700],
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(themeProvider),
                        const SizedBox(height: 24),
                        _buildSummaryCards(themeProvider),
                        const SizedBox(height: 32),
                        _buildFilterSection(themeProvider),
                        const SizedBox(height: 20),
                        _buildPayrollList(themeProvider),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode 
                    ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                    : [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PayrollCreatePage()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode 
              ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
              : [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payroll Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Payrolls',
                '${_monthlySummary['totalPayrolls'] ?? 0}',
                Icons.people_outline,
                themeProvider.isDarkMode 
                    ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                    : [Colors.blue[400]!, Colors.blue[600]!],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Total Amount',
                'Rp ${NumberFormat('#,###').format(_monthlySummary['totalAmount'] ?? 0)}',
                Icons.account_balance_wallet_outlined,
                themeProvider.isDarkMode 
                    ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.8)]
                    : [Colors.green[400]!, Colors.green[600]!],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Pending',
                '${_monthlySummary['pendingCount'] ?? 0}',
                Icons.pending_outlined,
                themeProvider.isDarkMode 
                    ? [AppTheme.accentOrange, AppTheme.accentOrange.withOpacity(0.8)]
                    : [Colors.orange[400]!, Colors.orange[600]!],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Approved',
                '${_monthlySummary['approvedCount'] ?? 0}',
                Icons.check_circle_outline,
                themeProvider.isDarkMode 
                    ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                    : [Colors.blue[400]!, Colors.blue[600]!],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Paid',
                '${_monthlySummary['paidCount'] ?? 0}',
                Icons.payment_outlined,
                themeProvider.isDarkMode 
                    ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.8)]
                    : [Colors.green[400]!, Colors.green[600]!],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list, 
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600], 
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Payrolls',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', Icons.list, themeProvider),
                _buildFilterChip('pending', 'Pending', Icons.pending_outlined, themeProvider),
                _buildFilterChip('approved', 'Approved', Icons.check_circle_outline, themeProvider),
                _buildFilterChip('paid', 'Paid', Icons.payment_outlined, themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, ThemeProvider themeProvider) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                        : [Colors.blue[500]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected 
                ? null 
                : themeProvider.isDarkMode 
                    ? AppTheme.surfaceDark.withOpacity(0.5)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected 
                  ? (themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue[600]!)
                  : (themeProvider.isDarkMode ? AppTheme.borderDark : Colors.grey[300]!),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? Colors.white 
                    : (themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[600]),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.grey[700]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayrollList(ThemeProvider themeProvider) {
    final filteredPayrolls = _payrolls.where((payroll) {
      if (_selectedStatus == 'all') return true;
      return payroll.status == _selectedStatus;
    }).toList();
    
    if (filteredPayrolls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode 
                    ? AppTheme.surfaceDark.withOpacity(0.5)
                    : Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No payrolls found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first payroll by tapping the + button',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payroll List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    '${filteredPayrolls.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPayrolls.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final payroll = filteredPayrolls[index];
              return _buildPayrollCard(payroll, themeProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(PayrollModel payroll, ThemeProvider themeProvider) {
    Color statusColor;
    IconData statusIcon;
    Color statusBgColor;
    
    switch (payroll.status) {
      case 'pending':
        statusColor = Colors.orange[600]!;
        statusIcon = Icons.pending_outlined;
        statusBgColor = Colors.orange[50]!;
        break;
      case 'approved':
        statusColor = Colors.blue[600]!;
        statusIcon = Icons.check_circle_outline;
        statusBgColor = Colors.blue[50]!;
        break;
      case 'paid':
        statusColor = Colors.green[600]!;
        statusIcon = Icons.payment_outlined;
        statusBgColor = Colors.green[50]!;
        break;
      default:
        statusColor = Colors.grey[600]!;
        statusIcon = Icons.help_outline;
        statusBgColor = Colors.grey[50]!;
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayrollDetailPage(payroll: payroll),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.1), statusBgColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payroll.employeeName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payroll.position,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(payroll.payrollDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${NumberFormat('#,###').format(payroll.netSalary)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withOpacity(0.1), statusBgColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    payroll.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
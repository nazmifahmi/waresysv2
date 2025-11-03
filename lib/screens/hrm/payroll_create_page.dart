import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hrm/employee_model.dart';
import '../../models/hrm/payroll_model.dart';
import '../../services/hrm/payroll_service.dart';
import '../../services/hrm/employee_repository.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';

class PayrollCreatePage extends StatefulWidget {
  const PayrollCreatePage({Key? key}) : super(key: key);

  @override
  State<PayrollCreatePage> createState() => _PayrollCreatePageState();
}

class _PayrollCreatePageState extends State<PayrollCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final PayrollService _payrollService = PayrollService();
  final EmployeeRepository _employeeRepository = EmployeeRepository();
  
  List<EmployeeModel> _employees = [];
  EmployeeModel? _selectedEmployee;
  DateTime _payrollDate = DateTime.now();
  double _allowances = 0.0;
  double _deductions = 0.0;
  bool _isLoading = false;
  bool _isLoadingEmployees = true;

  final TextEditingController _allowancesController = TextEditingController();
  final TextEditingController _deductionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _allowancesController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeRepository.getAll();
      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading employees: $e')),
        );
      }
    }
  }

  Future<void> _createPayroll() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payrollId = await _payrollService.createPayroll(
        employeeId: _selectedEmployee!.employeeId,
        employeeName: _selectedEmployee!.fullName,
        position: _selectedEmployee!.position,
        baseSalary: _selectedEmployee!.salary,
        allowances: _allowances,
        deductions: _deductions,
        payrollDate: _payrollDate,
      );

      if (payrollId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payroll created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to create payroll');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating payroll: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _netSalary {
    if (_selectedEmployee == null) return 0.0;
    return _selectedEmployee!.salary + _allowances - _deductions;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Text(
              'Create Payroll',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            backgroundColor: themeProvider.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
            foregroundColor: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
            elevation: 0,
            shadowColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
          ),
          body: _isLoadingEmployees
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.isDarkMode 
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading employees...',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(themeProvider),
                        const SizedBox(height: 32),
                        _buildEmployeeSelection(themeProvider),
                        const SizedBox(height: 24),
                        _buildPayrollDateSelection(themeProvider),
                        const SizedBox(height: 24),
                        if (_selectedEmployee != null) ...[
                          _buildSalaryInfo(themeProvider),
                          const SizedBox(height: 24),
                          _buildAllowancesField(themeProvider),
                          const SizedBox(height: 16),
                          _buildDeductionsField(themeProvider),
                          const SizedBox(height: 24),
                          _buildNetSalarySummary(themeProvider),
                          const SizedBox(height: 32),
                        ],
                        _buildCreateButton(themeProvider),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode 
              ? [AppTheme.primaryGreen, AppTheme.secondaryGreen]
              : [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? AppTheme.primaryGreen.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              Icons.receipt_long_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Payroll',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate payroll for your employees',
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

  Widget _buildEmployeeSelection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.8)]
                        : [Colors.purple[500]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Employee',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<EmployeeModel>(
            value: _selectedEmployee,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeProvider.isDarkMode ? AppTheme.primaryGreen : AppTheme.accentBlue, 
                  width: 2
                ),
              ),
              filled: true,
              fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
              hintText: 'Choose an employee',
              hintStyle: TextStyle(color: themeProvider.isDarkMode ? AppTheme.textTertiary : AppTheme.textTertiaryLight),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode 
                      ? AppTheme.primaryGreen.withOpacity(0.2)
                      : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: themeProvider.isDarkMode ? AppTheme.primaryGreen : Colors.blue[600],
                  size: 20,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            style: TextStyle(
              color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
            ),
            items: _employees.map((employee) {
              return DropdownMenuItem<EmployeeModel>(
                value: employee,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        employee.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${employee.position} • Rp ${NumberFormat('#,###').format(employee.salary)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (employee) {
              setState(() => _selectedEmployee = employee);
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an employee';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollDateSelection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentOrange, AppTheme.accentOrange.withOpacity(0.8)]
                        : [Colors.orange[500]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Payroll Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _payrollDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: themeProvider.isDarkMode 
                          ? ColorScheme.dark(
                              primary: AppTheme.primaryGreen,
                              onPrimary: Colors.white,
                              surface: AppTheme.surfaceDark,
                              onSurface: AppTheme.textPrimary,
                            )
                          : ColorScheme.light(
                              primary: Colors.blue[600]!,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black87,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _payrollDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
                border: Border.all(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? AppTheme.accentOrange.withOpacity(0.2)
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: themeProvider.isDarkMode ? AppTheme.accentOrange : Colors.orange[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(_payrollDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfo(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                        : [Colors.blue[500]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Employee Salary Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode 
                  ? AppTheme.accentBlue.withOpacity(0.1)
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.isDarkMode 
                    ? AppTheme.accentBlue.withOpacity(0.3)
                    : Colors.blue[200]!
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base Salary:',
                      style: TextStyle(
                        fontSize: 15,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format(_selectedEmployee!.salary)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: themeProvider.isDarkMode ? AppTheme.accentBlue : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Position:',
                      style: TextStyle(
                        fontSize: 15,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _selectedEmployee!.position,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowancesField(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.8)]
                        : [Colors.green[500]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Allowances',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _allowancesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeProvider.isDarkMode ? AppTheme.accentGreen : Colors.green[600]!, 
                  width: 2
                ),
              ),
              filled: true,
              fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
              hintText: '0',
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textTertiary : AppTheme.textTertiaryLight,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode 
                      ? AppTheme.accentGreen.withOpacity(0.2)
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: themeProvider.isDarkMode ? AppTheme.accentGreen : Colors.green[600],
                  size: 20,
                ),
              ),
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
            ),
            onChanged: (value) {
              setState(() {
                _allowances = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsField(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentRed, AppTheme.accentRed.withOpacity(0.8)]
                        : [Colors.red[500]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Deductions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _deductionsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeProvider.isDarkMode ? AppTheme.accentRed : Colors.red[600]!, 
                  width: 2
                ),
              ),
              filled: true,
              fillColor: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.grey[50],
              hintText: '0',
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textTertiary : AppTheme.textTertiaryLight,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode 
                      ? AppTheme.accentRed.withOpacity(0.2)
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove_circle_outline,
                  color: themeProvider.isDarkMode ? AppTheme.accentRed : Colors.red[600],
                  size: 20,
                ),
              ),
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (value) {
              setState(() {
                _deductions = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalarySummary(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode 
              ? [AppTheme.accentGreen.withOpacity(0.1), AppTheme.accentGreen.withOpacity(0.2)]
              : [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode ? AppTheme.accentGreen.withOpacity(0.3) : Colors.green[200]!
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? AppTheme.accentGreen.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode 
                        ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.8)]
                        : [Colors.green[600]!, Colors.green[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Payroll Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.isDarkMode ? AppTheme.accentGreen.withOpacity(0.3) : Colors.green[200]!
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base Salary:',
                      style: TextStyle(
                        fontSize: 15,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format(_selectedEmployee!.salary)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Allowances:',
                      style: TextStyle(
                        fontSize: 15,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format(_allowances)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode ? AppTheme.accentGreen : Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deductions:',
                      style: TextStyle(
                        fontSize: 15,
                        color: themeProvider.isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format(_deductions)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode ? AppTheme.accentRed : Colors.red[600],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: themeProvider.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Salary:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: themeProvider.isDarkMode 
                              ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.8)]
                              : [Colors.green[600]!, Colors.green[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rp ${NumberFormat('#,###').format(_netSalary)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading || _selectedEmployee == null
              ? themeProvider.isDarkMode 
                  ? [AppTheme.textTertiary, AppTheme.textTertiary.withOpacity(0.8)]
                  : [Colors.grey[400]!, Colors.grey[500]!]
              : themeProvider.isDarkMode 
                  ? [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.8)]
                  : [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading || _selectedEmployee == null
            ? []
            : [
                BoxShadow(
                  color: themeProvider.isDarkMode 
                      ? AppTheme.accentBlue.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading || _selectedEmployee == null ? null : _createPayroll,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Creating Payroll...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Create Payroll',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
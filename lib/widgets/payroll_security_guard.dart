import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/role_utils.dart';
import '../services/firestore_service.dart';

/// Security guard widget specifically for payroll features
class PayrollSecurityGuard extends StatelessWidget {
  final PayrollPermission requiredPermission;
  final Widget child;
  final Widget? fallback;
  final String? targetEmployeeId;
  final String? targetEmployeeDepartment;
  final String? auditAction;
  final String? payrollId;
  final bool showUnauthorizedMessage;

  const PayrollSecurityGuard({
    Key? key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
    this.targetEmployeeId,
    this.targetEmployeeDepartment,
    this.auditAction,
    this.payrollId,
    this.showUnauthorizedMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        debugPrint('PayrollSecurityGuard: Checking access for permission: ${requiredPermission.name}');
        
        if (authProvider.currentUser == null) {
          debugPrint('PayrollSecurityGuard: User not authenticated');
          return _buildUnauthorizedWidget(context, 'User not authenticated');
        }

        final userData = authProvider.userData;
        final userRoleString = userData?['role'] as String?;
        final userRole = RoleUtils.parseRole(userRoleString);
        final currentUserId = authProvider.currentUser!.uid;
        final currentUserDepartment = userData?['department'] as String?;

        debugPrint('PayrollSecurityGuard: User ID: $currentUserId');
        debugPrint('PayrollSecurityGuard: User Role: ${userRole.name}');
        debugPrint('PayrollSecurityGuard: Target Employee ID: ${targetEmployeeId ?? currentUserId}');
        debugPrint('PayrollSecurityGuard: Current User Department: $currentUserDepartment');
        debugPrint('PayrollSecurityGuard: Target Employee Department: $targetEmployeeDepartment');

        // Validate access
        final hasAccess = PayrollSecurityUtils.validatePayrollAccess(
          userRole: userRole,
          currentUserId: currentUserId,
          targetEmployeeId: targetEmployeeId ?? currentUserId,
          requiredPermission: requiredPermission,
          targetEmployeeDepartment: targetEmployeeDepartment,
          currentUserDepartment: currentUserDepartment,
        );

        if (hasAccess) {
          // Log access if audit action is specified
          if (auditAction != null) {
            _logPayrollAccess(
              userId: currentUserId,
              userName: userData?['name'] ?? 'Unknown',
              action: auditAction!,
              payrollId: payrollId,
              employeeId: targetEmployeeId ?? currentUserId,
            );
          }
          return child;
        }
        return _buildUnauthorizedWidget(context, 'Insufficient permissions');
      },
    );
  }

  Widget _buildUnauthorizedWidget(BuildContext context, String reason) {
    if (fallback != null) {
      return fallback!;
    }

    if (showUnauthorizedMessage) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Akses Ditolak',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda tidak memiliki izin untuk mengakses data gaji ini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Izin yang diperlukan: ${RoleUtils.getPayrollPermissionDisplayName(requiredPermission)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _logPayrollAccess({
    required String userId,
    required String userName,
    required String action,
    String? payrollId,
    required String employeeId,
  }) {
    // Log asynchronously to avoid blocking UI
    Future.microtask(() async {
      try {
        final auditLog = PayrollSecurityUtils.createPayrollAuditLog(
          userId: userId,
          userName: userName,
          action: action,
          payrollId: payrollId ?? 'unknown',
          employeeId: employeeId,
          details: 'Permission: ${requiredPermission.name}',
        );

        await FirestoreService().logActivity(
          userId: userId,
          userName: userName,
          type: 'payroll_security',
          action: action,
          description: 'Payroll access: $action',
          details: auditLog,
        );
      } catch (e) {
        debugPrint('Failed to log payroll access: $e');
      }
    });
  }
}

/// Password protection dialog for sensitive payroll operations
class PayrollPasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PayrollPasswordDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  State<PayrollPasswordDialog> createState() => _PayrollPasswordDialogState();
}

class _PayrollPasswordDialogState extends State<PayrollPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _isObscured = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _isObscured,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
              errorText: _errorMessage,
            ),
            onSubmitted: (_) => _verifyPassword(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyPassword,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verifikasi'),
        ),
      ],
    );
  }

  void _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Password tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser?.email != null) {
        // Verify password by attempting to reauthenticate
        final isValid = await authProvider.verifyPassword(_passwordController.text);
        
        if (isValid) {
          // Password is correct
          Navigator.of(context).pop();
          widget.onSuccess();
        } else {
          throw Exception('Invalid password');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Password salah';
        _isLoading = false;
      });
    }
  }
}

/// Utility function to show payroll password dialog
Future<void> showPayrollPasswordDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onSuccess,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PayrollPasswordDialog(
      title: title,
      message: message,
      onSuccess: onSuccess,
      onCancel: onCancel,
    ),
  );
}

/// Widget that shows user's payroll permissions
class PayrollPermissionsDisplay extends StatelessWidget {
  const PayrollPermissionsDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userData = authProvider.userData;
        final userRoleString = userData?['role'] as String?;
        final userRole = RoleUtils.parseRole(userRoleString);
        final permissions = RoleUtils.getPayrollPermissionsForRole(userRole);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: RoleUtils.getRoleColor(userRole)),
                    const SizedBox(width: 8),
                    Text(
                      'Izin Akses Gaji',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Role: ${RoleUtils.getRoleDisplayName(userRole)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RoleUtils.getRoleColor(userRole),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...permissions.map((permission) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        RoleUtils.getPayrollPermissionDisplayName(permission),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}
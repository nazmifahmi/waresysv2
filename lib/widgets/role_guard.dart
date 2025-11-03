import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/role_utils.dart';

class RoleGuard extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const RoleGuard({
    Key? key,
    required this.requiredRole,
    required this.child,
    this.fallback,
    this.showFallback = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.currentUser == null) {
          return showFallback ? (fallback ?? const SizedBox.shrink()) : const SizedBox.shrink();
        }

        final userData = authProvider.userData;
        final userRoleString = userData?['role'] as String?;
        final userRole = RoleUtils.parseRole(userRoleString);

        if (RoleUtils.hasPermission(userRole, requiredRole)) {
          return child;
        }

        return showFallback ? (fallback ?? const SizedBox.shrink()) : const SizedBox.shrink();
      },
    );
  }
}

class RoleBasedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final UserRole? requiredRole;

  const RoleBasedAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.requiredRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userData = authProvider.userData;
        final userRoleString = userData?['role'] as String?;
        final userRole = RoleUtils.parseRole(userRoleString);

        List<Widget> filteredActions = [];
        if (actions != null) {
          for (var action in actions!) {
            if (requiredRole == null || RoleUtils.hasPermission(userRole, requiredRole!)) {
              filteredActions.add(action);
            }
          }
        }

        return AppBar(
          title: Row(
            children: [
              Text(title),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RoleUtils.getRoleColor(userRole).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: RoleUtils.getRoleColor(userRole),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      RoleUtils.getRoleIcon(userRole),
                      size: 14,
                      color: RoleUtils.getRoleColor(userRole),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      RoleUtils.getRoleDisplayName(userRole),
                      style: TextStyle(
                        fontSize: 12,
                        color: RoleUtils.getRoleColor(userRole),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: filteredActions.isNotEmpty ? filteredActions : null,
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class RoleBasedDrawer extends StatelessWidget {
  const RoleBasedDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userData = authProvider.userData;
        final userRoleString = userData?['role'] as String?;
        final userRole = RoleUtils.parseRole(userRoleString);

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userData?['name'] ?? 'User'),
                accountEmail: Text(authProvider.currentUser?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: RoleUtils.getRoleColor(userRole),
                  child: Icon(
                    RoleUtils.getRoleIcon(userRole),
                    color: Colors.white,
                  ),
                ),
                decoration: BoxDecoration(
                  color: RoleUtils.getRoleColor(userRole),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
              ),
              RoleGuard(
                requiredRole: UserRole.employee,
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('HRM'),
                  onTap: () => Navigator.pushNamed(context, '/hrm'),
                ),
              ),
              RoleGuard(
                requiredRole: UserRole.employee,
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Finance'),
                  onTap: () => Navigator.pushNamed(context, '/finance'),
                ),
              ),
              RoleGuard(
                requiredRole: UserRole.employee,
                child: ListTile(
                  leading: const Icon(Icons.contacts),
                  title: const Text('CRM'),
                  onTap: () => Navigator.pushNamed(context, '/crm'),
                ),
              ),
              RoleGuard(
                requiredRole: UserRole.employee,
                child: ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: const Text('Logistics'),
                  onTap: () => Navigator.pushNamed(context, '/logistics'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  // Handle logout
                  Navigator.of(context).pop();
                  // Add logout logic here
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
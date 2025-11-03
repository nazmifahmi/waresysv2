import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/hrm/employee_repository.dart';
import '../hrm/employee_profile_page.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final String moduleName;
  final Color moduleColor;
  final VoidCallback onBack;

  const ProfileScreen({
    super.key,
    required this.moduleName,
    required this.moduleColor,
    required this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _employeeRepository = EmployeeRepository();
  bool _isLoading = false;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        if (userData != null) {
          _nameController.text = userData['name'] ?? '';
          _companyController.text = userData['company'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Error loading user data: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        await _firestoreService.updateUser(user.uid, {
          'name': _nameController.text,
          'company': _companyController.text,
          'updatedAt': DateTime.now(),
        });
        setState(() => _isEditing = false);
        if (mounted) {
          CommonWidgets.showSnackBar(
            context: context,
            message: 'Profile updated successfully',
            type: SnackBarType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Error updating profile: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${widget.moduleName} Profile',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: widget.moduleColor,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: AppTheme.textPrimary,
              ),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        decoration: BoxDecoration(
                          color: widget.moduleColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.moduleColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 64,
                          color: widget.moduleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),
                    if (_isEditing) ...[
                      _buildEditForm(),
                    ] else ...[
                      _buildInfoRow('Name', _nameController.text),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildInfoRow('Company', _companyController.text),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildEmployeeProfileButton(),
                      const SizedBox(height: AppTheme.spacingXXL),
                      _buildSignOutButton(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXXL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Profile',
            style: AppTheme.heading3.copyWith(
              color: widget.moduleColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXXL),
          CommonWidgets.buildTextField(
            label: 'Name',
            hint: 'Enter your full name',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Company',
            hint: 'Enter your company name',
            controller: _companyController,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: AppTheme.spacingXXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CommonWidgets.buildSecondaryButton(
                text: 'Cancel',
                onPressed: () => setState(() => _isEditing = false),
              ),
              const SizedBox(width: AppTheme.spacingM),
              CommonWidgets.buildPrimaryButton(
                text: 'Save',
                onPressed: _saveUserData,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: widget.moduleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              label == 'Name' ? Icons.person_outline : Icons.business_outlined,
              color: widget.moduleColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: AppTheme.bodyLarge.copyWith(
                    color: value.isEmpty ? AppTheme.textTertiary : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeProfileButton() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            Icons.badge_outlined,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          'Employee Profile',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'View detailed employee information',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textTertiary,
        ),
        onTap: () async {
          try {
            final user = await _authService.getCurrentUser();
            if (user != null) {
              // Get employee by user ID
              final employees = await _employeeRepository.getAll();
              final employee = employees.firstWhere(
                (emp) => emp.userId == user.uid,
                orElse: () => throw Exception('Employee profile not found'),
              );
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeProfilePage(
                      employeeId: employee.employeeId,
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              CommonWidgets.showSnackBar(
                context: context,
                message: 'Employee profile not found. Please contact HR.',
                type: SnackBarType.error,
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            Icons.logout_outlined,
            color: AppTheme.errorColor,
            size: 20,
          ),
        ),
        title: Text(
          'Sign Out',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textTertiary,
        ),
        onTap: () async {
           final shouldSignOut = await showDialog<bool>(
             context: context,
             builder: (context) => AlertDialog(
               backgroundColor: AppTheme.surfaceDark,
               title: Text(
                 'Sign Out',
                 style: AppTheme.heading3.copyWith(
                   color: AppTheme.errorColor,
                 ),
               ),
               content: Text(
                 'Are you sure you want to sign out?',
                 style: AppTheme.bodyMedium.copyWith(
                   color: AppTheme.textSecondary,
                 ),
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context, false),
                   child: Text(
                     'Cancel',
                     style: AppTheme.bodyMedium.copyWith(
                       color: AppTheme.textSecondary,
                     ),
                   ),
                 ),
                 ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.errorColor,
                     foregroundColor: AppTheme.textPrimary,
                   ),
                   onPressed: () => Navigator.pop(context, true),
                   child: Text(
                     'Sign Out',
                     style: AppTheme.bodyMedium.copyWith(
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
               ],
             ),
           );
           
           if (shouldSignOut == true) {
             await _authService.signOut();
             if (mounted) {
               Navigator.pushReplacementNamed(context, '/login');
             }
           }
         },
      ),
    );
  }
}
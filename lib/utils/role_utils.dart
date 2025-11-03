import 'package:flutter/material.dart';

enum UserRole {
  employee,
  manager,
  admin,
}

enum PayrollPermission {
  viewOwnPayroll,
  viewTeamPayroll,
  viewAllPayroll,
  processPayroll,
  approvePayroll,
  generateReports,
  managePayrollSettings,
}

class RoleUtils {
  static UserRole parseRole(String? roleString) {
    if (roleString == null) return UserRole.employee;
    
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.employee:
        return 'employee';
    }
  }

  static bool hasPermission(UserRole userRole, UserRole requiredRole) {
    // Admin has access to everything
    if (userRole == UserRole.admin) return true;
    
    // Manager has access to manager and employee level features
    if (userRole == UserRole.manager && requiredRole != UserRole.admin) return true;
    
    // Employee only has access to employee level features
    if (userRole == UserRole.employee && requiredRole == UserRole.employee) return true;
    
    return false;
  }

  /// Check if user has specific payroll permission
  static bool hasPayrollPermission(UserRole userRole, PayrollPermission permission) {
    switch (permission) {
      case PayrollPermission.viewOwnPayroll:
        return true; // All users can view their own payroll
        
      case PayrollPermission.viewTeamPayroll:
        return userRole == UserRole.manager || userRole == UserRole.admin;
        
      case PayrollPermission.viewAllPayroll:
        return userRole == UserRole.admin;
        
      case PayrollPermission.processPayroll:
        return userRole == UserRole.admin;
        
      case PayrollPermission.approvePayroll:
        return userRole == UserRole.manager || userRole == UserRole.admin;
        
      case PayrollPermission.generateReports:
        return userRole == UserRole.manager || userRole == UserRole.admin;
        
      case PayrollPermission.managePayrollSettings:
        return userRole == UserRole.admin;
    }
  }

  /// Check if user can access payroll data for specific employee
  static bool canAccessEmployeePayroll(UserRole userRole, String currentUserId, String targetEmployeeId, {String? targetEmployeeDepartment, String? currentUserDepartment}) {
    // Admin can access all payroll data
    if (userRole == UserRole.admin) return true;
    
    // Users can always access their own payroll
    if (currentUserId == targetEmployeeId) return true;
    
    // Managers can access payroll data of employees in their department
    if (userRole == UserRole.manager && 
        targetEmployeeDepartment != null && 
        currentUserDepartment != null &&
        targetEmployeeDepartment == currentUserDepartment) {
      return true;
    }
    
    return false;
  }

  /// Get sensitive data access level
  static PayrollDataAccessLevel getPayrollDataAccessLevel(UserRole userRole) {
    switch (userRole) {
      case UserRole.admin:
        return PayrollDataAccessLevel.full;
      case UserRole.manager:
        return PayrollDataAccessLevel.departmental;
      case UserRole.employee:
        return PayrollDataAccessLevel.personal;
    }
  }

  static bool canAccessHRM(UserRole role) {
    return true; // All roles can access HRM
  }

  static bool canAccessFinance(UserRole role) {
    return role == UserRole.manager || role == UserRole.admin; // Restricted access
  }

  static bool canAccessCRM(UserRole role) {
    return true; // All roles can access CRM
  }

  static bool canAccessLogistics(UserRole role) {
    return true; // All roles can access Logistics
  }

  static bool canManageUsers(UserRole role) {
    return role == UserRole.admin; // Only admin can manage users
  }

  static bool canApproveLeaves(UserRole role) {
    return role == UserRole.manager || role == UserRole.admin; // Manager and admin can approve
  }

  static bool canApproveClaims(UserRole role) {
    return role == UserRole.manager || role == UserRole.admin; // Manager and admin can approve
  }

  static bool canAssignTasks(UserRole role) {
    return role == UserRole.manager || role == UserRole.admin; // Manager and admin can assign
  }

  static bool canViewAllTasks(UserRole role) {
    return role == UserRole.manager || role == UserRole.admin; // Manager and admin can view all
  }

  static bool canViewReports(UserRole role) {
    return role == UserRole.manager || role == UserRole.admin; // Manager and admin can view reports
  }

  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }

  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.orange;
      case UserRole.employee:
        return Colors.blue;
    }
  }

  static IconData getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.supervisor_account;
      case UserRole.employee:
        return Icons.person;
    }
  }

  /// Get payroll permission display name
  static String getPayrollPermissionDisplayName(PayrollPermission permission) {
    switch (permission) {
      case PayrollPermission.viewOwnPayroll:
        return 'Lihat Gaji Sendiri';
      case PayrollPermission.viewTeamPayroll:
        return 'Lihat Gaji Tim';
      case PayrollPermission.viewAllPayroll:
        return 'Lihat Semua Gaji';
      case PayrollPermission.processPayroll:
        return 'Proses Gaji';
      case PayrollPermission.approvePayroll:
        return 'Setujui Gaji';
      case PayrollPermission.generateReports:
        return 'Buat Laporan';
      case PayrollPermission.managePayrollSettings:
        return 'Kelola Pengaturan Gaji';
    }
  }

  /// Get list of permissions for a role
  static List<PayrollPermission> getPayrollPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return PayrollPermission.values; // All permissions
      case UserRole.manager:
        return [
          PayrollPermission.viewOwnPayroll,
          PayrollPermission.viewTeamPayroll,
          PayrollPermission.approvePayroll,
          PayrollPermission.generateReports,
        ];
      case UserRole.employee:
        return [
          PayrollPermission.viewOwnPayroll,
        ];
    }
  }
}

enum PayrollDataAccessLevel {
  personal,    // Can only access own payroll data
  departmental, // Can access payroll data for their department
  full,        // Can access all payroll data
}

/// Security utility class for payroll data protection
class PayrollSecurityUtils {
  /// Mask sensitive payroll data based on user role
  static Map<String, dynamic> maskPayrollData(Map<String, dynamic> payrollData, UserRole userRole, String currentUserId, String payrollEmployeeId) {
    final maskedData = Map<String, dynamic>.from(payrollData);
    
    // If user is viewing their own data or is admin, show full data
    if (currentUserId == payrollEmployeeId || userRole == UserRole.admin) {
      return maskedData;
    }
    
    // For managers viewing team data, mask some sensitive fields
    if (userRole == UserRole.manager) {
      // Keep basic info but mask detailed breakdowns
      maskedData['deductionBreakdown'] = _maskBreakdown(maskedData['deductionBreakdown']);
      maskedData['allowanceBreakdown'] = _maskBreakdown(maskedData['allowanceBreakdown']);
      return maskedData;
    }
    
    // For other cases, return empty data (should not happen with proper access control)
    return {};
  }
  
  static Map<String, dynamic>? _maskBreakdown(dynamic breakdown) {
    if (breakdown is Map<String, dynamic>) {
      return breakdown.map((key, value) => MapEntry(key, '***'));
    }
    return null;
  }
  
  /// Generate audit log entry for payroll access
  static Map<String, dynamic> createPayrollAuditLog({
    required String userId,
    required String userName,
    required String action,
    required String payrollId,
    required String employeeId,
    String? details,
  }) {
    return {
      'userId': userId,
      'userName': userName,
      'action': action,
      'payrollId': payrollId,
      'employeeId': employeeId,
      'timestamp': DateTime.now().toIso8601String(),
      'details': details,
      'type': 'payroll_access',
    };
  }
  
  /// Validate payroll access attempt
  static bool validatePayrollAccess({
    required UserRole userRole,
    required String currentUserId,
    required String targetEmployeeId,
    required PayrollPermission requiredPermission,
    String? targetEmployeeDepartment,
    String? currentUserDepartment,
  }) {
    // Check if user has the required permission
    if (!RoleUtils.hasPayrollPermission(userRole, requiredPermission)) {
      return false;
    }
    
    // Check if user can access the specific employee's payroll
    return RoleUtils.canAccessEmployeePayroll(
      userRole, 
      currentUserId, 
      targetEmployeeId,
      targetEmployeeDepartment: targetEmployeeDepartment,
      currentUserDepartment: currentUserDepartment,
    );
  }
}
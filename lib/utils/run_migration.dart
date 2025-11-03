import 'package:flutter/material.dart';
import 'user_role_migration.dart';

/// Simple utility to run user role migration
/// This can be called from the main app or from a debug screen
class MigrationRunner {
  
  /// Run the user role migration with UI feedback
  static Future<void> runMigrationWithFeedback(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Migrating user roles...'),
          ],
        ),
      ),
    );

    try {
      // Print status before migration
      await UserRoleMigration.printMigrationStatus();
      
      // Run migration
      await UserRoleMigration.migrateUserRoles();
      
      // Print status after migration
      await UserRoleMigration.printMigrationStatus();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Migration Complete'),
          content: const Text('User roles have been successfully migrated from "user" to "employee".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Migration Failed'),
          content: Text('Error during migration: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Run migration silently (for console/debug use)
  static Future<void> runMigrationSilently() async {
    try {
      print('=== Starting User Role Migration ===');
      
      // Print status before migration
      await UserRoleMigration.printMigrationStatus();
      
      // Run migration
      await UserRoleMigration.migrateUserRoles();
      
      // Print status after migration
      await UserRoleMigration.printMigrationStatus();
      
      print('=== Migration Completed Successfully ===');
      
    } catch (e) {
      print('=== Migration Failed ===');
      print('Error: $e');
      rethrow;
    }
  }
}
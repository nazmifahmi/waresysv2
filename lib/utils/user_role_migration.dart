import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Utility class to migrate existing users from 'user' role to 'employee' role
class UserRoleMigration {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Migrate all users with 'user' role to 'employee' role
  static Future<void> migrateUserRoles() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('⚠️ Firebase not initialized, skipping user role migration');
        return;
      }
      
      print('Starting user role migration...');
      
      // Query all users with 'user' role
      final QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('No users found with "user" role. Migration not needed.');
        return;
      }

      print('Found ${usersSnapshot.docs.length} users to migrate.');

      // Batch update for better performance
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const int batchLimit = 500; // Firestore batch limit

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        batch.update(doc.reference, {
          'role': 'employee',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        // Commit batch if we reach the limit
        if (batchCount >= batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          print('Migrated batch of $batchLimit users...');
        }
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        print('Migrated final batch of $batchCount users.');
      }

      print('User role migration completed successfully!');
      print('Total users migrated: ${usersSnapshot.docs.length}');
      
    } catch (e) {
      print('Error during user role migration: $e');
      rethrow;
    }
  }

  /// Check how many users have 'user' role (for verification)
  static Future<int> countUsersWithUserRole() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('⚠️ Firebase not initialized, cannot count users with user role');
        return 0;
      }
      
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error counting users with "user" role: $e');
      return 0;
    }
  }

  /// Check how many users have 'employee' role (for verification)
  static Future<int> countUsersWithEmployeeRole() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('⚠️ Firebase not initialized, cannot count users with employee role');
        return 0;
      }
      
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error counting users with "employee" role: $e');
      return 0;
    }
  }

  /// Print migration status
  static Future<void> printMigrationStatus() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('⚠️ Firebase not initialized, skipping migration status check');
        return;
      }
      
      final userRoleCount = await countUsersWithUserRole();
      final employeeRoleCount = await countUsersWithEmployeeRole();
      
      print('=== User Role Migration Status ===');
      print('Users with "user" role: $userRoleCount');
      print('Users with "employee" role: $employeeRoleCount');
      print('==================================');
    } catch (e) {
      print('Error printing migration status: $e');
    }
  }
}
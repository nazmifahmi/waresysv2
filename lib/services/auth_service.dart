import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'firestore_service.dart';
import 'firebase_messaging_handler.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestore = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login timestamp and get user data
      if (userCredential.user != null) {
        final userData = await _firestore.getUser(userCredential.user!.uid);
        final userName = userData?['name'] ?? userCredential.user!.displayName ?? email.split('@')[0];
        
        await _firestore.updateUser(userCredential.user!.uid, {
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Store FCM token for push notifications
        try {
          await FirebaseMessagingHandler.storeFCMToken(userCredential.user!.uid);
        } catch (e) {
          debugPrint('Failed to store FCM token: $e');
        }

        // Log activity with proper username
        await _firestore.logActivity(
          userId: userCredential.user!.uid,
          userName: userName,
          type: 'auth',
          action: 'login',
          description: 'User Logged In',
          details: {
            'email': email,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String company,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document
        await _firestore.updateUser(userCredential.user!.uid, {
          'name': name,
          'company': company,
          'email': email,
          'role': 'employee', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Store FCM token for push notifications
        try {
          await FirebaseMessagingHandler.storeFCMToken(userCredential.user!.uid);
        } catch (e) {
          debugPrint('Failed to store FCM token during registration: $e');
        }

        // Update user profile
        await userCredential.user!.updateDisplayName(name);

        // Log activity
        await _firestore.logActivity(
          userId: userCredential.user!.uid,
          userName: name,
          type: 'auth',
          action: 'create',
          description: 'New user registered',
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data for proper username
        final userData = await _firestore.getUser(user.uid);
        final userName = userData?['name'] ?? user.displayName ?? user.email?.split('@')[0] ?? 'Unknown';
        
        // Log activity before signing out
        await _firestore.logActivity(
          userId: user.uid,
          userName: userName,
          type: 'auth',
          action: 'logout',
          description: 'User Logged Out',
          details: {
            'email': user.email,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user role
  Future<String> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore.getUser(user.uid);
        return userData?['role'] ?? 'employee';
      }
      return 'employee';
    } catch (e) {
      return 'employee';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final role = await getUserRole();
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String name,
    required String company,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update Firestore user document
        await _firestore.updateUser(user.uid, {
          'name': name,
          'company': company,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update auth profile
        await user.updateDisplayName(name);

        // Log activity
        await _firestore.logActivity(
          userId: user.uid,
          userName: name,
          type: 'auth',
          action: 'update',
          description: 'User profile updated',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Reauthenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Change password
        await user.updatePassword(newPassword);

        // Log activity
        await _firestore.logActivity(
          userId: user.uid,
          userName: user.displayName ?? 'Unknown',
          type: 'auth',
          action: 'update',
          description: 'Password changed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) throw 'Google Sign In was cancelled';

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Update or create user document
      if (userCredential.user != null) {
        await _firestore.updateUser(userCredential.user!.uid, {
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });

        // Store FCM token for push notifications
        try {
          await FirebaseMessagingHandler.storeFCMToken(userCredential.user!.uid);
        } catch (e) {
          debugPrint('Failed to store FCM token during Google sign-in: $e');
        }

        // Log activity
        await _firestore.logActivity(
          userId: userCredential.user!.uid,
          userName: userCredential.user!.displayName ?? 'Unknown',
          type: 'auth',
          action: 'login',
          description: 'User Logged In with Google',
        );
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      // Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential for Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuthCredential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Update or create user document
      if (userCredential.user != null) {
        final String displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        
        await _firestore.updateUser(userCredential.user!.uid, {
          'name': displayName.isNotEmpty ? displayName : null,
          'email': userCredential.user!.email,
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'provider': 'apple',
        });

        // Store FCM token for push notifications
        try {
          await FirebaseMessagingHandler.storeFCMToken(userCredential.user!.uid);
        } catch (e) {
          debugPrint('Failed to store FCM token during Apple sign-in: $e');
        }

        // Log activity
        await _firestore.logActivity(
          userId: userCredential.user!.uid,
          userName: displayName.isNotEmpty ? displayName : 'Apple User',
          type: 'auth',
          action: 'login',
          description: 'User Logged In with Apple',
        );
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Apple: $e');
      rethrow;
    }
  }

  // Generate nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // SHA256 hash
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
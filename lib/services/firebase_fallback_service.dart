import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service untuk menangani fallback ketika Firebase tidak tersedia
class FirebaseFallbackService {
  static final FirebaseFallbackService _instance = FirebaseFallbackService._internal();
  factory FirebaseFallbackService() => _instance;
  
  bool _isFirebaseAvailable = true;
  bool _isAuthAvailable = true;
  bool _isFirestoreAvailable = true;
  
  FirebaseFallbackService._internal();
  
  // Getters untuk status availability
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  bool get isAuthAvailable => _isAuthAvailable;
  bool get isFirestoreAvailable => _isFirestoreAvailable;
  
  /// Check Firebase availability
  Future<void> checkFirebaseAvailability() async {
    try {
      // Test Firebase Auth
      try {
        FirebaseAuth.instance.currentUser;
        _isAuthAvailable = true;
      } catch (e) {
        _isAuthAvailable = false;
        debugPrint('⚠️ Firebase Auth not available: $e');
      }
      
      // Test Firestore
      try {
        await FirebaseFirestore.instance
            .collection('test')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));
        _isFirestoreAvailable = true;
      } catch (e) {
        _isFirestoreAvailable = false;
        debugPrint('⚠️ Firestore not available: $e');
      }
      
      _isFirebaseAvailable = _isAuthAvailable && _isFirestoreAvailable;
      
    } catch (e) {
      _isFirebaseAvailable = false;
      _isAuthAvailable = false;
      _isFirestoreAvailable = false;
      debugPrint('⚠️ Firebase completely unavailable: $e');
    }
  }
  
  /// Fallback authentication using SharedPreferences
  Future<Map<String, dynamic>?> getFallbackUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('fallback_user');
      if (userJson != null) {
        return jsonDecode(userJson);
      }
    } catch (e) {
      debugPrint('Error getting fallback user: $e');
    }
    return null;
  }
  
  /// Save user data as fallback
  Future<void> saveFallbackUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fallback_user', jsonEncode(userData));
    } catch (e) {
      debugPrint('Error saving fallback user: $e');
    }
  }
  
  /// Fallback data storage using SharedPreferences
  Future<void> saveFallbackData(String collection, String docId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'fallback_${collection}_$docId';
      await prefs.setString(key, jsonEncode({
        ...data,
        'timestamp': DateTime.now().toIso8601String(),
        'is_fallback': true,
      }));
    } catch (e) {
      debugPrint('Error saving fallback data: $e');
    }
  }
  
  /// Get fallback data from SharedPreferences
  Future<Map<String, dynamic>?> getFallbackData(String collection, String docId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'fallback_${collection}_$docId';
      final dataJson = prefs.getString(key);
      if (dataJson != null) {
        return jsonDecode(dataJson);
      }
    } catch (e) {
      debugPrint('Error getting fallback data: $e');
    }
    return null;
  }
  
  /// Get all fallback data for a collection
  Future<List<Map<String, dynamic>>> getFallbackCollection(String collection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('fallback_$collection'));
      final List<Map<String, dynamic>> results = [];
      
      for (final key in keys) {
        final dataJson = prefs.getString(key);
        if (dataJson != null) {
          final data = jsonDecode(dataJson);
          results.add(data);
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting fallback collection: $e');
      return [];
    }
  }
  
  /// Sync fallback data to Firebase when available
  Future<void> syncFallbackData() async {
    if (!_isFirestoreAvailable) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final fallbackKeys = prefs.getKeys().where((key) => key.startsWith('fallback_'));
      
      for (final key in fallbackKeys) {
        try {
          final dataJson = prefs.getString(key);
          if (dataJson != null) {
            final data = jsonDecode(dataJson);
            
            // Parse collection and doc ID from key
            final parts = key.split('_');
            if (parts.length >= 3) {
              final collection = parts[1];
              final docId = parts.sublist(2).join('_');
              
              // Remove fallback metadata
              data.remove('is_fallback');
              data.remove('timestamp');
              
              // Sync to Firestore
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .set(data, SetOptions(merge: true));
              
              // Remove from local storage after successful sync
              await prefs.remove(key);
              debugPrint('✅ Synced fallback data: $collection/$docId');
            }
          }
        } catch (e) {
          debugPrint('Error syncing fallback data for $key: $e');
        }
      }
    } catch (e) {
      debugPrint('Error during fallback data sync: $e');
    }
  }
  
  /// Create mock user for offline mode
  Map<String, dynamic> createMockUser() {
    return {
      'uid': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      'email': 'offline@waresys.local',
      'name': 'Offline User',
      'isOffline': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// Show connection status to user
  String getConnectionStatus() {
    if (_isFirebaseAvailable) {
      return '🟢 Online - Firebase Connected';
    } else if (_isAuthAvailable || _isFirestoreAvailable) {
      return '🟡 Partial Connection - Limited Features';
    } else {
      return '🔴 Offline Mode - Local Data Only';
    }
  }
}
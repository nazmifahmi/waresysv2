import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk menangani koneksi Firestore dengan retry mechanism
class FirestoreConnectionService {
  static final FirestoreConnectionService _instance = FirestoreConnectionService._internal();
  factory FirestoreConnectionService() => _instance;
  FirestoreConnectionService._internal();

  FirebaseFirestore? _firestore;
  bool _isConnected = false;
  bool _isInitialized = false;
  Timer? _retryTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Connection status stream
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  FirebaseFirestore? get firestore => _firestore;

  /// Initialize Firestore connection dengan retry mechanism
  Future<bool> initialize() async {
    if (_isInitialized) return _isConnected;
    
    debugPrint('🔄 Initializing Firestore connection...');
    
    // Setup connectivity monitoring
    _setupConnectivityMonitoring();
    
    // Try to connect
    await _attemptConnection();
    
    _isInitialized = true;
    return _isConnected;
  }

  /// Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none && !_isConnected) {
        debugPrint('📶 Network connectivity restored, attempting Firestore reconnection...');
        _attemptConnection();
      }
    });
  }

  /// Attempt to connect to Firestore
  Future<void> _attemptConnection() async {
    try {
      // Cancel any existing retry timer
      _retryTimer?.cancel();
      
      // Initialize Firestore instance
      _firestore = FirebaseFirestore.instance;
      
      // Configure Firestore settings for better offline support
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Test connection dengan timeout
      await _testConnection();
      
      _isConnected = true;
      _connectionStatusController.add(true);
      debugPrint('✅ Firestore connected successfully');
      
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      debugPrint('❌ Firestore connection failed: $e');
      
      // Schedule retry
      _scheduleRetry();
    }
  }

  /// Test Firestore connection
  Future<void> _testConnection() async {
    // Try to read from a test collection with timeout
    await _firestore!
        .collection('_connection_test')
        .limit(1)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 5));
  }

  /// Schedule connection retry
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (!_isConnected) {
        debugPrint('🔄 Retrying Firestore connection...');
        _attemptConnection();
      }
    });
  }

  /// Execute Firestore operation dengan fallback
  Future<T?> executeOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool useCache = true,
  }) async {
    if (!_isConnected) {
      debugPrint('⚠️ Firestore not connected, returning fallback value');
      return fallbackValue;
    }

    try {
      return await operation().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('❌ Firestore operation failed: $e');
      
      // Mark as disconnected and attempt reconnection
      _isConnected = false;
      _connectionStatusController.add(false);
      _attemptConnection();
      
      return fallbackValue;
    }
  }

  /// Get collection reference dengan safety check
  CollectionReference? getCollection(String path) {
    if (!_isConnected || _firestore == null) {
      debugPrint('⚠️ Firestore not available for collection: $path');
      return null;
    }
    return _firestore!.collection(path);
  }

  /// Get document reference dengan safety check
  DocumentReference? getDocument(String path) {
    if (!_isConnected || _firestore == null) {
      debugPrint('⚠️ Firestore not available for document: $path');
      return null;
    }
    return _firestore!.doc(path);
  }

  /// Check if user is authenticated
  bool get isUserAuthenticated {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      debugPrint('❌ Firebase Auth check failed: $e');
      return false;
    }
  }

  /// Get connection status string
  String getConnectionStatusString() {
    if (_isConnected) {
      return '🟢 Firestore Connected';
    } else if (_isInitialized) {
      return '🟡 Firestore Connecting...';
    } else {
      return '🔴 Firestore Offline';
    }
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }

  /// Force reconnection
  Future<void> forceReconnect() async {
    debugPrint('🔄 Forcing Firestore reconnection...');
    _isConnected = false;
    await _attemptConnection();
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      if (_firestore != null) {
        await _firestore!.enablePersistence();
        debugPrint('✅ Firestore offline persistence enabled');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to enable offline persistence: $e');
    }
  }

  /// Clear offline cache
  Future<void> clearOfflineCache() async {
    try {
      if (_firestore != null) {
        await _firestore!.clearPersistence();
        debugPrint('✅ Firestore offline cache cleared');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to clear offline cache: $e');
    }
  }
}
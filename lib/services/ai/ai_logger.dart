import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../firestore_service.dart';

enum AILogLevel {
  debug,
  info,
  warning,
  error,
  critical
}

class AILogger {
  static final AILogger _instance = AILogger._internal();
  factory AILogger() => _instance;
  
  final FirestoreService _firestoreService = FirestoreService();
  final CollectionReference _logsCollection = FirebaseFirestore.instance.collection('ai_logs');
  bool _firestoreAvailable = true;
  
  AILogger._internal();

  Future<void> log({
    required String component,
    required String message,
    required AILogLevel level,
    Map<String, dynamic>? data,
    String? modelName,
    double? confidence,
    String? error,
    StackTrace? stackTrace,
  }) async {
    final logEntry = {
      'component': component,
      'message': message,
      'level': level.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
      'modelName': modelName,
      'confidence': confidence,
      'error': error,
      'stackTrace': stackTrace?.toString(),
      'environment': kDebugMode ? 'development' : 'production',
    };

    // Always print to console in debug mode
    if (kDebugMode) {
      print('AI Log [$level] $component: $message');
      if (error != null) {
        print('Error: $error');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
      }
    }

    // Try to store in Firestore if available
    if (_firestoreAvailable) {
      try {
        final firestoreEntry = Map<String, dynamic>.from(logEntry);
        firestoreEntry['timestamp'] = FieldValue.serverTimestamp();
        await _logsCollection.add(firestoreEntry);
      } catch (e) {
        // Check if it's a permission error
        if (e.toString().contains('permission-denied')) {
          _firestoreAvailable = false;
          debugPrint('⚠️ Firestore logging disabled due to permission denied. Falling back to local logging.');
        } else {
          debugPrint('Failed to log to Firestore: $e');
        }
        
        // Fallback to local storage
        await _logToLocal(logEntry);
      }
    } else {
      // Use local storage as fallback
      await _logToLocal(logEntry);
    }
  }

  Future<void> _logToLocal(Map<String, dynamic> logEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLogs = prefs.getStringList('ai_logs') ?? [];
      
      // Keep only last 100 logs to prevent storage bloat
      if (existingLogs.length >= 100) {
        existingLogs.removeRange(0, existingLogs.length - 99);
      }
      
      existingLogs.add(jsonEncode(logEntry));
      await prefs.setStringList('ai_logs', existingLogs);
    } catch (e) {
      debugPrint('Failed to log locally: $e');
    }
  }

  Future<void> logPrediction({
    required String modelName,
    required Map<String, dynamic> input,
    required Map<String, dynamic> output,
    required double confidence,
    Duration? executionTime,
  }) async {
    await log(
      component: 'prediction',
      message: 'Model prediction completed',
      level: AILogLevel.info,
      data: {
        'input': input,
        'output': output,
        'executionTime': executionTime?.inMilliseconds,
      },
      modelName: modelName,
      confidence: confidence,
    );
  }

  Future<void> logModelUpdate({
    required String modelName,
    required String version,
    required bool success,
    String? error,
  }) async {
    await log(
      component: 'model_update',
      message: success ? 'Model updated successfully' : 'Model update failed',
      level: success ? AILogLevel.info : AILogLevel.error,
      data: {'version': version},
      modelName: modelName,
      error: error,
    );
  }

  Future<void> logError({
    required String component,
    required String message,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await log(
      component: component,
      message: message,
      level: AILogLevel.error,
      data: context,
      error: error.toString(),
      stackTrace: stackTrace,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentLogs({
    int limit = 100,
    AILogLevel? minLevel,
    String? component,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _logsCollection.orderBy('timestamp', descending: true);

    if (minLevel != null) {
      query = query.where('level', whereIn: AILogLevel.values
          .sublist(AILogLevel.values.indexOf(minLevel))
          .map((e) => e.toString())
          .toList());
    }

    if (component != null) {
      query = query.where('component', isEqualTo: component);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getErrorStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _logsCollection.where('level', isEqualTo: AILogLevel.error.toString());

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.get();
    final errors = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Group errors by component
    final componentErrors = <String, int>{};
    for (var error in errors) {
      final component = error['component'] as String;
      componentErrors[component] = (componentErrors[component] ?? 0) + 1;
    }

    return {
      'total_errors': errors.length,
      'errors_by_component': componentErrors,
      'time_range': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
    };
  }
}
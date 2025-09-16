import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility untuk optimasi performance dan mengurangi work di main thread
class PerformanceOptimizer {
  static final Map<String, Isolate> _isolates = {};
  static final Map<String, ReceivePort> _receivePorts = {};
  
  /// Jalankan heavy computation di background isolate
  static Future<T> runInBackground<T>({
    required String taskName,
    required Future<T> Function() computation,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (kIsWeb) {
      // Web tidak support isolates, jalankan di main thread
      return await computation();
    }
    
    try {
      final completer = Completer<T>();
      final receivePort = ReceivePort();
      
      // Spawn isolate untuk computation
      final isolate = await Isolate.spawn(
        _isolateEntryPoint<T>,
        _IsolateMessage(
          sendPort: receivePort.sendPort,
          computation: computation,
        ),
      );
      
      // Listen untuk hasil
      late StreamSubscription subscription;
      subscription = receivePort.listen((message) {
        if (message is _IsolateResult<T>) {
          if (message.isError) {
            completer.completeError(message.error!, message.stackTrace);
          } else {
            completer.complete(message.result);
          }
          subscription.cancel();
          receivePort.close();
          isolate.kill();
        }
      });
      
      // Set timeout
      Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Background task timeout', timeout));
          subscription.cancel();
          receivePort.close();
          isolate.kill();
        }
      });
      
      return await completer.future;
    } catch (e) {
      debugPrint('Background computation failed, running on main thread: $e');
      return await computation();
    }
  }
  
  /// Entry point untuk isolate
  static void _isolateEntryPoint<T>(_IsolateMessage<T> message) async {
    try {
      final result = await message.computation();
      message.sendPort.send(_IsolateResult<T>(result: result));
    } catch (e, stackTrace) {
      message.sendPort.send(_IsolateResult<T>(error: e, stackTrace: stackTrace));
    }
  }
  
  /// Debounce function calls untuk mengurangi excessive calls
  static Timer? _debounceTimer;
  static void debounce({
    required Duration duration,
    required VoidCallback callback,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }
  
  /// Throttle function calls
  static DateTime? _lastThrottleTime;
  static void throttle({
    required Duration duration,
    required VoidCallback callback,
  }) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      callback();
    }
  }
  
  /// Batch operations untuk mengurangi frequent updates
  static final Map<String, List<VoidCallback>> _batchedOperations = {};
  static final Map<String, Timer> _batchTimers = {};
  
  static void batchOperation({
    required String batchKey,
    required VoidCallback operation,
    Duration batchDuration = const Duration(milliseconds: 100),
  }) {
    _batchedOperations[batchKey] ??= [];
    _batchedOperations[batchKey]!.add(operation);
    
    _batchTimers[batchKey]?.cancel();
    _batchTimers[batchKey] = Timer(batchDuration, () {
      final operations = _batchedOperations[batchKey] ?? [];
      _batchedOperations[batchKey]?.clear();
      
      for (final operation in operations) {
        operation();
      }
    });
  }
  
  /// Memory optimization - clear caches
  static void clearCaches() {
    _batchedOperations.clear();
    _batchTimers.forEach((key, timer) => timer.cancel());
    _batchTimers.clear();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastThrottleTime = null;
  }
  
  /// Monitor frame rate
  static void monitorFrameRate() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          final frameTime = timing.totalSpan.inMilliseconds;
          if (frameTime > 16) { // 60 FPS = 16.67ms per frame
            debugPrint('⚠️ Slow frame detected: ${frameTime}ms');
          }
        }
      });
    }
  }
  
  /// Optimize widget rebuilds
  static Widget optimizedBuilder({
    required Widget Function() builder,
    List<Object?>? dependencies,
  }) {
    return _OptimizedWidget(
      builder: builder,
      dependencies: dependencies,
    );
  }
}

/// Message untuk isolate communication
class _IsolateMessage<T> {
  final SendPort sendPort;
  final Future<T> Function() computation;
  
  _IsolateMessage({
    required this.sendPort,
    required this.computation,
  });
}

/// Result dari isolate computation
class _IsolateResult<T> {
  final T? result;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isError;
  
  _IsolateResult({
    this.result,
    this.error,
    this.stackTrace,
  }) : isError = error != null;
}

/// Widget yang dioptimasi untuk mengurangi rebuilds
class _OptimizedWidget extends StatefulWidget {
  final Widget Function() builder;
  final List<Object?>? dependencies;
  
  const _OptimizedWidget({
    required this.builder,
    this.dependencies,
  });
  
  @override
  State<_OptimizedWidget> createState() => _OptimizedWidgetState();
}

class _OptimizedWidgetState extends State<_OptimizedWidget> {
  Widget? _cachedWidget;
  List<Object?>? _lastDependencies;
  
  @override
  Widget build(BuildContext context) {
    final currentDependencies = widget.dependencies;
    
    // Check if dependencies changed
    if (_cachedWidget == null || 
        !listEquals(_lastDependencies, currentDependencies)) {
      _cachedWidget = widget.builder();
      _lastDependencies = currentDependencies?.toList();
    }
    
    return _cachedWidget!;
  }
}

/// Extension untuk Future dengan timeout
extension FutureTimeout<T> on Future<T> {
  Future<T> withTimeout(Duration timeout) {
    return Future.any([
      this,
      Future.delayed(timeout).then((_) => 
        throw TimeoutException('Operation timeout', timeout)
      ),
    ]);
  }
}

/// Performance metrics
class PerformanceMetrics {
  static final Stopwatch _appStartTime = Stopwatch()..start();
  static final Map<String, Stopwatch> _operationTimers = {};
  
  static void startTimer(String operation) {
    _operationTimers[operation] = Stopwatch()..start();
  }
  
  static void stopTimer(String operation) {
    final timer = _operationTimers[operation];
    if (timer != null) {
      timer.stop();
      if (kDebugMode) {
        debugPrint('⏱️ $operation took ${timer.elapsedMilliseconds}ms');
      }
      _operationTimers.remove(operation);
    }
  }
  
  static int get appUptimeMs => _appStartTime.elapsedMilliseconds;
}
import 'package:flutter/foundation.dart';
// import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart'; // <-- DIHAPUS
// import 'package:tflite_flutter/tflite_flutter.dart'; // <-- DIHAPUS karena menyebabkan error
import '../firestore_service.dart';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import 'predictors/stock_predictor.dart';
import 'predictors/sales_predictor.dart';
import 'predictors/financial_predictor.dart';
import 'ai_logger.dart';
import 'model_validator.dart';
import 'mock_ai_service.dart';

// FUNGSI YANG HILANG DITAMBAHKAN DI SINI
// Harus berada di luar class agar bisa dijalankan oleh Isolate
void _processInBackground(SendPort sendPort) {
  // Implementasi pemrosesan latar belakang bisa ditambahkan di sini nanti.
  // Untuk sekarang, biarkan kosong agar tidak error.
  debugPrint("Isolate for background processing started.");
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  late final SharedPreferences _prefs;
  final FirestoreService _firestoreService = FirestoreService();
  final AILogger _logger = AILogger();
  final ModelValidator _validator = ModelValidator();

  final StockPredictor _stockPredictor = StockPredictor();
  final SalesPredictor _salesPredictor = SalesPredictor();
  final FinancialPredictor _financialPredictor = FinancialPredictor();
  final MockAIService _mockService = MockAIService();

  bool _isInitialized = false;
  bool _useMockService = false;
  Isolate? _isolate;
  ReceivePort? _receivePort;

  static const String _cachePrefix = 'ai_prediction_';
  static const Duration _cacheDuration = Duration(hours: 1);

  AIService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Coba load model TensorFlow Lite terlebih dahulu
      try {
        await _loadModelsFromAssets();
        _useMockService = false;
        debugPrint('✅ TensorFlow Lite models loaded successfully');
      } catch (e) {
        debugPrint('⚠️ TensorFlow Lite models failed to load: $e');
        debugPrint('🔄 Falling back to Mock AI Service');
        
        // Fallback ke mock service
        await _mockService.initialize();
        _useMockService = true;
      }

      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _processInBackground,
        _receivePort!.sendPort,
      );

      _isInitialized = true;

      final serviceType = _useMockService ? 'Mock AI Service' : 'TensorFlow Lite';
      await _logger.log(
        component: 'ai_service',
        message: 'AI Service initialized successfully using $serviceType',
        level: AILogLevel.info,
      );
    } catch (e, stackTrace) {
      await _logger.logError(
        component: 'ai_service',
        message: 'AI Service initialization failed completely',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _loadModelsFromAssets() async {
    try {
      // Panggilan ini akan berhasil setelah kita memodifikasi Predictor di Langkah 2
      await _stockPredictor.initialize(modelPath: 'assets/ml/stock_prediction.tflite');
      await _salesPredictor.initialize(modelPath: 'assets/ml/sales_prediction.tflite');
      await _financialPredictor.initialize(modelPath: 'assets/ml/financial_prediction.tflite');

      await _logger.log(component: 'model_loader', message: 'All models loaded from assets.', level: AILogLevel.info);

    } catch (e, stackTrace) {
      await _logger.logError(
        component: 'model_loader',
        message: 'Failed to load models from assets',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Sisa kode di bawah ini bisa ditempel dari file asli kamu.
  // Untuk sementara, saya akan tambahkan placeholder agar lengkap.

  Future<void> _validateModels() async {
    // Implementasi validasi
  }

  Future<Map<String, dynamic>> predictStockLevels(String productId) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (_useMockService) {
        return await _mockService.predictStockLevels(productId);
      } else {
        return await _stockPredictor.predictStockLevels(productId);
      }
    } catch (e) {
      debugPrint('Error in predictStockLevels: $e');
      // Fallback ke mock service jika terjadi error
      if (!_useMockService) {
        try {
          await _mockService.initialize();
          return await _mockService.predictStockLevels(productId);
        } catch (mockError) {
          debugPrint('Mock service also failed: $mockError');
        }
      }
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> predictSales({String? productId}) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (_useMockService) {
        return await _mockService.predictSales(productId: productId);
      } else {
        return await _salesPredictor.predictSales(productId: productId);
      }
    } catch (e) {
      debugPrint('Error in predictSales: $e');
      // Fallback ke mock service jika terjadi error
      if (!_useMockService) {
        try {
          await _mockService.initialize();
          return await _mockService.predictSales(productId: productId);
        } catch (mockError) {
          debugPrint('Mock service also failed: $mockError');
        }
      }
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeFinancialHealth() async {
    if (!_isInitialized) await initialize();
    
    try {
      if (_useMockService) {
        return await _mockService.analyzeFinancialHealth();
      } else {
        return await _financialPredictor.analyzeFinancialHealth();
      }
    } catch (e) {
      debugPrint('Error in analyzeFinancialHealth: $e');
      // Fallback ke mock service jika terjadi error
      if (!_useMockService) {
        try {
          await _mockService.initialize();
          return await _mockService.analyzeFinancialHealth();
        } catch (mockError) {
          debugPrint('Mock service also failed: $mockError');
        }
      }
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> generateSmartAlerts() async {
    if (!_isInitialized) await initialize();
    
    try {
      if (_useMockService) {
        return await _mockService.generateSmartAlerts();
      } else {
        // Implementasi untuk generate alert dengan TensorFlow Lite
        // Untuk sementara return empty list
        return [];
      }
    } catch (e) {
      debugPrint('Error in generateSmartAlerts: $e');
      // Fallback ke mock service jika terjadi error
      if (!_useMockService) {
        try {
          await _mockService.initialize();
          return await _mockService.generateSmartAlerts();
        } catch (mockError) {
          debugPrint('Mock service also failed: $mockError');
        }
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getCachedPrediction(String key) async {
    // Implementasi cache
    return null;
  }

  Future<void> _cachePrediction(String key, Map<String, dynamic> data) async {
    // Implementasi cache
  }

  // Getter untuk mengetahui apakah menggunakan mock service
  bool get isUsingMockService => _useMockService;
  
  // Getter untuk status inisialisasi
  bool get isInitialized => _isInitialized;

  void dispose() {
    _isolate?.kill();
    _receivePort?.close();
    if (_useMockService) {
      _mockService.dispose();
    }
    _isInitialized = false;
  }
}


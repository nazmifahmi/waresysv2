import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  MobileScannerController? _controller;
  bool _isInitialized = false;

  /// Initialize the barcode scanner
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _isInitialized = true;
      debugPrint('✅ Barcode scanner initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize barcode scanner: $e');
      throw Exception('Failed to initialize barcode scanner: $e');
    }
  }

  /// Get the scanner controller
  MobileScannerController? get controller => _controller;

  /// Check if scanner is initialized
  bool get isInitialized => _isInitialized;

  /// Start scanning
  Future<void> startScanning() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Barcode scanner not initialized');
    }
    
    try {
      await _controller!.start();
      debugPrint('📱 Barcode scanning started');
    } catch (e) {
      debugPrint('❌ Failed to start scanning: $e');
      throw Exception('Failed to start scanning: $e');
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (_controller == null) return;
    
    try {
      await _controller!.stop();
      debugPrint('⏹️ Barcode scanning stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop scanning: $e');
    }
  }

  /// Toggle torch/flashlight
  Future<void> toggleTorch() async {
    if (_controller == null) return;
    
    try {
      await _controller!.toggleTorch();
      debugPrint('🔦 Torch toggled');
    } catch (e) {
      debugPrint('❌ Failed to toggle torch: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_controller == null) return;
    
    try {
      await _controller!.switchCamera();
      debugPrint('📷 Camera switched');
    } catch (e) {
      debugPrint('❌ Failed to switch camera: $e');
    }
  }

  /// Process barcode detection result
  String? processBarcodeResult(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isEmpty) {
      debugPrint('⚠️ No barcodes detected');
      return null;
    }

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;
    
    if (code == null || code.isEmpty) {
      debugPrint('⚠️ Empty barcode detected');
      return null;
    }

    debugPrint('✅ Barcode detected: $code (Type: ${barcode.type})');
    return code;
  }

  /// Validate barcode format (basic validation)
  bool isValidBarcode(String code) {
    if (code.isEmpty) return false;
    
    // Basic validation - can be extended based on requirements
    // Check for common barcode formats
    final RegExp barcodePattern = RegExp(r'^[0-9A-Za-z\-_]+$');
    return barcodePattern.hasMatch(code) && code.length >= 4;
  }

  /// Generate barcode for product (simple implementation)
  String generateProductBarcode(String productId) {
    // Simple barcode generation - in production, use proper barcode generation
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'PRD${productId.substring(0, 4).toUpperCase()}$timestamp';
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    _isInitialized = false;
    debugPrint('🗑️ Barcode service disposed');
  }

  /// Check camera permissions
  Future<bool> checkPermissions() async {
    try {
      // Mobile scanner handles permissions internally
      // This is a placeholder for additional permission checks if needed
      return true;
    } catch (e) {
      debugPrint('❌ Permission check failed: $e');
      return false;
    }
  }

  /// Get supported barcode formats
  List<BarcodeFormat> getSupportedFormats() {
    return [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
    ];
  }
}
import 'package:flutter/foundation.dart';
import '../services/ai/ai_service.dart'; // Sesuaikan path jika perlu

// Provider ini akan mengelola status inisialisasi AIService
class AIProvider with ChangeNotifier {
  final AIService _aiService = AIService();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  AIService get service => _aiService;

  // Fungsi inilah yang akan kita panggil dari layar loading
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _aiService.initialize();
      _isInitialized = true;
      print("✅ AI Service Initialized Successfully!");
      notifyListeners();
    } catch (e) {
      print("❌ AI Service Initialization Failed: $e");
      // Kamu bisa menambahkan penanganan error di sini
      rethrow;
    }
  }
}

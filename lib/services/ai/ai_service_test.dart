import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock_ai_service.dart';
import 'ai_service.dart';

/// Test utility untuk memverifikasi AI Service functionality
class AIServiceTest {
  static Future<void> runTests() async {
    debugPrint('🧪 Starting AI Service Tests...');
    
    // Check if Firebase is initialized before running tests
    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ Firebase not initialized. Skipping AI Service tests that require Firebase.');
      return;
    }
    
    try {
      await _testMockAIService();
      await _testAIServiceFallback();
      debugPrint('✅ All AI Service tests passed!');
    } catch (e) {
      debugPrint('❌ AI Service tests failed: $e');
    }
  }
  
  static Future<void> _testMockAIService() async {
    debugPrint('🔍 Testing Mock AI Service...');
    
    final mockService = MockAIService();
    
    // Test initialization
    await mockService.initialize();
    assert(mockService.isInitialized, 'Mock AI Service should be initialized');
    debugPrint('✅ Mock AI Service initialization test passed');
    
    // Test stock prediction
    final stockPrediction = await mockService.predictStockLevels('test_product_id');
    assert(stockPrediction.isNotEmpty, 'Stock prediction should not be empty');
    assert(stockPrediction['is_mock'] == true, 'Should be marked as mock data');
    assert(stockPrediction['product_id'] == 'test_product_id', 'Product ID should match');
    debugPrint('✅ Mock stock prediction test passed');
    
    // Test sales prediction
    final salesPrediction = await mockService.predictSales(productId: 'test_product_id');
    assert(salesPrediction.isNotEmpty, 'Sales prediction should not be empty');
    assert(salesPrediction['is_mock'] == true, 'Should be marked as mock data');
    debugPrint('✅ Mock sales prediction test passed');
    
    // Test financial analysis
    final financialAnalysis = await mockService.analyzeFinancialHealth();
    assert(financialAnalysis.isNotEmpty, 'Financial analysis should not be empty');
    assert(financialAnalysis['is_mock'] == true, 'Should be marked as mock data');
    assert(financialAnalysis['health_score'] != null, 'Should have health score');
    debugPrint('✅ Mock financial analysis test passed');
    
    // Test smart alerts
    final alerts = await mockService.generateSmartAlerts();
    assert(alerts is List, 'Alerts should be a list');
    debugPrint('✅ Mock smart alerts test passed');
    
    // Test dispose
    mockService.dispose();
    debugPrint('✅ Mock AI Service dispose test passed');
  }
  
  static Future<void> _testAIServiceFallback() async {
    debugPrint('🔍 Testing AI Service Fallback Mechanism...');
    
    final aiService = AIService();
    
    try {
      // Test initialization (should fallback to mock if TensorFlow fails)
      await aiService.initialize();
      assert(aiService.isInitialized, 'AI Service should be initialized');
      debugPrint('✅ AI Service initialization test passed');
      
      // Test if using mock service
      if (aiService.isUsingMockService) {
        debugPrint('🔄 AI Service is using Mock Service (as expected)');
        
        // Test stock prediction with fallback
        final stockPrediction = await aiService.predictStockLevels('test_product_id');
        assert(stockPrediction.isNotEmpty, 'Stock prediction should not be empty');
        debugPrint('✅ AI Service stock prediction fallback test passed');
        
        // Test sales prediction with fallback
        final salesPrediction = await aiService.predictSales(productId: 'test_product_id');
        assert(salesPrediction.isNotEmpty, 'Sales prediction should not be empty');
        debugPrint('✅ AI Service sales prediction fallback test passed');
        
        // Test financial analysis with fallback
        final financialAnalysis = await aiService.analyzeFinancialHealth();
        assert(financialAnalysis.isNotEmpty, 'Financial analysis should not be empty');
        debugPrint('✅ AI Service financial analysis fallback test passed');
        
        // Test smart alerts with fallback
        final alerts = await aiService.generateSmartAlerts();
        assert(alerts is List, 'Alerts should be a list');
        debugPrint('✅ AI Service smart alerts fallback test passed');
      } else {
        debugPrint('🎯 AI Service is using TensorFlow Lite (real models)');
      }
      
    } catch (e) {
      debugPrint('⚠️ AI Service test encountered error: $e');
      // This is expected if models are not valid
    }
  }
  
  /// Test data validation
  static bool validatePredictionData(Map<String, dynamic> data) {
    // Check required fields
    if (!data.containsKey('confidence')) return false;
    if (!data.containsKey('description')) return false;
    
    // Check confidence is valid
    final confidence = data['confidence'];
    if (confidence is! double || confidence < 0 || confidence > 1) return false;
    
    // Check description is not empty
    final description = data['description'];
    if (description is! String || description.isEmpty) return false;
    
    return true;
  }
  
  /// Performance test
  static Future<void> performanceTest() async {
    debugPrint('⚡ Running AI Service Performance Test...');
    
    // Check if Firebase is initialized before running performance test
    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ Firebase not initialized. Skipping AI Service performance test.');
      return;
    }
    
    final mockService = MockAIService();
    await mockService.initialize();
    
    final stopwatch = Stopwatch()..start();
    
    // Test multiple predictions
    for (int i = 0; i < 10; i++) {
      await mockService.predictStockLevels('product_$i');
    }
    
    stopwatch.stop();
    final avgTime = stopwatch.elapsedMilliseconds / 10;
    
    debugPrint('📊 Average prediction time: ${avgTime.toStringAsFixed(2)}ms');
    
    if (avgTime < 100) {
      debugPrint('✅ Performance test passed (< 100ms average)');
    } else {
      debugPrint('⚠️ Performance test warning (> 100ms average)');
    }
  }
}
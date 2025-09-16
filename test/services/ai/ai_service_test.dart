import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waresys_fix1/services/ai/ai_service.dart';
import 'package:waresys_fix1/services/firestore_service.dart';
import 'package:waresys_fix1/models/product_model.dart';
import 'package:waresys_fix1/models/transaction_model.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late AIService aiService;
  late MockFirestoreService mockFirestore;

  setUp(() {
    mockFirestore = MockFirestoreService();
    aiService = AIService();
  });

  group('AIService - Stock Prediction', () {
    final testProduct = ProductModel(
      id: 'test_product',
      name: 'Test Product',
      stock: 100,
      price: 5000,
      reorderPoint: 20,
    );

    final testTransactions = [
      TransactionModel(
        id: 'trans1',
        productId: 'test_product',
        quantity: 5,
        date: DateTime.now().subtract(Duration(days: 1)),
      ),
      TransactionModel(
        id: 'trans2',
        productId: 'test_product',
        quantity: 3,
        date: DateTime.now().subtract(Duration(days: 2)),
      ),
    ];

    test('predictStockLevels returns valid prediction for product with history', () async {
      // Arrange
      when(mockFirestore.getProduct('test_product'))
          .thenAnswer((_) async => testProduct);
      when(mockFirestore.getProductTransactions('test_product'))
          .thenAnswer((_) async => testTransactions);

      // Act
      final result = await aiService.predictStockLevels('test_product');

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['productId'], equals('test_product'));
      expect(result['currentStock'], equals(100));
      expect(result['predictedDemand'], isA<double>());
      expect(result['recommendedRestock'], isA<double>());
      expect(result['confidenceScore'], isA<double>());
      expect(result['timestamp'], isNotNull);
    });

    test('predictStockLevels handles missing product gracefully', () async {
      // Arrange
      when(mockFirestore.getProduct('nonexistent_product'))
          .thenAnswer((_) async => null);

      // Act
      final result = await aiService.predictStockLevels('nonexistent_product');

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['error'], contains('Product not found'));
      expect(result['productId'], equals('nonexistent_product'));
      expect(result['timestamp'], isNotNull);
    });

    test('predictStockLevels handles empty transaction history gracefully', () async {
      // Arrange
      when(mockFirestore.getProduct('test_product'))
          .thenAnswer((_) async => testProduct);
      when(mockFirestore.getProductTransactions('test_product'))
          .thenAnswer((_) async => []);

      // Act
      final result = await aiService.predictStockLevels('test_product');

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['error'], contains('No transaction history'));
      expect(result['productId'], equals('test_product'));
      expect(result['timestamp'], isNotNull);
    });

    test('predictStockLevels uses cached results when available', () async {
      // First call to populate cache
      when(mockFirestore.getProduct('test_product'))
          .thenAnswer((_) async => testProduct);
      when(mockFirestore.getProductTransactions('test_product'))
          .thenAnswer((_) async => testTransactions);

      final firstResult = await aiService.predictStockLevels('test_product');
      
      // Second call should use cache
      final secondResult = await aiService.predictStockLevels('test_product');

      expect(secondResult, equals(firstResult));
      verify(mockFirestore.getProduct('test_product')).called(1); // Should be called only once
    });
  });
} 
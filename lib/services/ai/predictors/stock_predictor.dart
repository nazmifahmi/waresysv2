import 'dart:math' as math;
import '../../../models/product_model.dart';
import '../../../models/transaction_model.dart';
import '../../firestore_service.dart';
import '../tflite/custom_interpreter.dart';

class StockPredictor {
  final FirestoreService _firestoreService = FirestoreService();
  final CustomInterpreter _interpreter = CustomInterpreter();
  bool _isInitialized = false;

  Future<void> initialize({required String modelPath}) async {
    if (_isInitialized) return;
    try {
      await _interpreter.loadModel(modelPath);
      _isInitialized = true;
      print('StockPredictor berhasil diinisialisasi dengan model: $modelPath');
    } catch (e) {
      print('Gagal menginisialisasi StockPredictor: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predictStockLevels(String productId) async {
    if (!_isInitialized) {
      throw Exception("StockPredictor belum diinisialisasi. Panggil AIService.initialize() terlebih dahulu.");
    }

    try {
      final product = await _firestoreService.getProduct(productId);
      if (product == null) {
        throw Exception('Produk tidak ditemukan');
      }

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final historicalData = await _processHistoricalData(productId, startDate, endDate);
      final historicalSales = List<double>.from(historicalData['daily_sales']);

      final inputData = _prepareInputData(historicalData, product);

      // --- PERBAIKAN: Menggunakan logika parsing yang kuat ---
      final predictionResult = await _interpreter.predict(inputData, outputLength: 30);
      final List<double> predictions = _parsePredictionResult(predictionResult);
      // --- AKHIR PERBAIKAN ---

      if (predictions.isEmpty) {
        return {
          'description': 'Prediksi tidak dapat dihasilkan karena data tidak cukup.',
          'actions': [],
          'confidence': 0.0,
        };
      }

      final averageDaily = predictions.reduce((a, b) => a + b) / predictions.length;

      final leadTime = 2.0;
      final serviceLevel = 0.95;
      final standardDeviation = _calculateStandardDeviation(historicalSales);

      final reorderPoint = (averageDaily * leadTime) +
          (serviceLevel * standardDeviation * sqrt(leadTime));

      final safetyStock = serviceLevel * standardDeviation * sqrt(leadTime);

      final currentStock = product.stock.toDouble();
      final daysUntilStockout = averageDaily > 0 ? currentStock / averageDaily : double.infinity;

      List<String> actions = [];
      String description = '';

      if (currentStock <= reorderPoint) {
        final orderQuantity = (averageDaily * leadTime * 2) + safetyStock - currentStock;
        actions.add('Lakukan pemesanan untuk ${orderQuantity.ceil()} unit');
        description = 'Tingkat stok di bawah titik pemesanan ulang. Diperlukan tindakan segera.';
      } else if (daysUntilStockout < 14) {
        description = 'Stok akan bertahan selama ${daysUntilStockout.ceil()} hari dengan tingkat saat ini.';
        if (daysUntilStockout < 7) {
          actions.add('Rencanakan pemesanan ulang dalam ${(daysUntilStockout - leadTime).ceil()} hari');
        }
      } else {
        description = 'Tingkat stok dalam kondisi aman.';
      }

      return {
        'product_id': productId,
        'current_stock': currentStock,
        'daily_average': averageDaily,
        'days_until_stockout': daysUntilStockout,
        'reorder_point': reorderPoint,
        'safety_stock': safetyStock,
        'predictions': predictions,
        'description': description,
        'actions': actions,
        'confidence': 0.85,
      };
    } catch (e) {
      print('Error dalam prediksi stok: $e');
      return {};
    }
  }

  // --- FUNGSI HELPER BARU UNTUK PARSING YANG KONSISTEN ---
  List<double> _parsePredictionResult(dynamic result) {
    if (result is! List || result.isEmpty) {
      return [];
    }
    if (result[0] is List) {
      final nestedList = result[0] as List;
      return nestedList.map((e) => (e as num).toDouble()).toList();
    } else {
      return result.map((e) => (e as num).toDouble()).toList();
    }
  }

  Future<Map<String, dynamic>> _processHistoricalData(
      String productId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    final transactions = await _firestoreService.getTransactions(
      startDate: startDate,
      endDate: endDate,
      productId: productId,
      type: TransactionType.sales,
    );

    final Map<DateTime, double> dailySales = {};
    for (var trx in transactions) {
      final date = DateTime(trx.date.year, trx.date.month, trx.date.day);
      for (final item in trx.items) {
        if (item.productId == productId) {
          final quantity = item.quantity.toDouble();
          // --- PERBAIKAN: Menggunakan 0.0 untuk konsistensi tipe data ---
          dailySales[date] = (dailySales[date] ?? 0.0) + quantity;
          break;
        }
      }
    }

    return {
      'daily_sales': dailySales.values.toList(),
      'trends': {},
    };
  }

  List<double> _prepareInputData(Map<String, dynamic> historicalData, Product product) {
    final sales = List<double>.from(historicalData['daily_sales']);
    return sales;
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((value) => pow(value - mean, 2));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
  }

  double sqrt(double value) => value <= 0 ? 0 : math.sqrt(value);

  double pow(double base, double exponent) => math.pow(base, exponent).toDouble();
}


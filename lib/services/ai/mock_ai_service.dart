import 'dart:math' as math;
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../models/finance_model.dart';
import '../firestore_service.dart';

/// Mock AI Service yang menyediakan data prediksi palsu
/// Digunakan sebagai fallback ketika model TensorFlow Lite gagal dimuat
class MockAIService {
  final FirestoreService _firestoreService = FirestoreService();
  final math.Random _random = math.Random();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Simulasi delay inisialisasi
    await Future.delayed(const Duration(milliseconds: 500));
    _isInitialized = true;
    print('✅ Mock AI Service initialized successfully!');
  }

  bool get isInitialized => _isInitialized;

  /// Prediksi stok dengan data mock
  Future<Map<String, dynamic>> predictStockLevels(String productId) async {
    if (!_isInitialized) {
      throw Exception('Mock AI Service belum diinisialisasi');
    }

    try {
      final product = await _firestoreService.getProduct(productId);
      if (product == null) {
        throw Exception('Produk tidak ditemukan');
      }

      final currentStock = product.stock.toDouble();
      final minStock = product.minStock.toDouble();
      
      // Generate mock predictions (30 hari ke depan)
      final predictions = List.generate(30, (index) {
        // Simulasi penjualan harian dengan variasi
        final baseDaily = math.max(1, currentStock / 30);
        final variation = _random.nextDouble() * 0.4 - 0.2; // ±20% variasi
        return baseDaily * (1 + variation);
      });

      final averageDaily = predictions.reduce((a, b) => a + b) / predictions.length;
      final daysUntilStockout = averageDaily > 0 ? currentStock / averageDaily : double.infinity;
      final reorderPoint = averageDaily * 7; // 7 hari lead time
      final safetyStock = minStock.toDouble();

      List<String> actions = [];
      String description = '';

      if (currentStock <= reorderPoint) {
        final orderQuantity = (averageDaily * 14) + safetyStock - currentStock;
        actions.add('Lakukan pemesanan untuk ${orderQuantity.ceil()} unit');
        description = 'Tingkat stok di bawah titik pemesanan ulang. Diperlukan tindakan segera.';
      } else if (daysUntilStockout < 14) {
        description = 'Stok akan bertahan selama ${daysUntilStockout.ceil()} hari dengan tingkat saat ini.';
        if (daysUntilStockout < 7) {
          actions.add('Rencanakan pemesanan ulang dalam ${(daysUntilStockout - 2).ceil()} hari');
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
        'confidence': 0.75, // Mock confidence
        'is_mock': true, // Flag untuk menandai data mock
      };
    } catch (e) {
      print('Error dalam mock prediksi stok: $e');
      return {
        'product_id': productId,
        'error': e.toString(),
        'is_mock': true,
      };
    }
  }

  /// Prediksi penjualan dengan data mock
  Future<Map<String, dynamic>> predictSales({String? productId}) async {
    if (!_isInitialized) {
      throw Exception('Mock AI Service belum diinisialisasi');
    }

    try {
      // Generate mock sales predictions
      final predictions = List.generate(30, (index) {
        final baseSales = 1000000 + _random.nextDouble() * 500000; // 1-1.5 juta
        final weeklyPattern = math.sin((index % 7) * math.pi / 3.5) * 0.2; // Pola mingguan
        return baseSales * (1 + weeklyPattern);
      });

      final totalPredicted = predictions.reduce((a, b) => a + b);
      final averageDaily = totalPredicted / predictions.length;
      final growth = _random.nextDouble() * 0.2 - 0.1; // ±10% growth

      return {
        'product_id': productId,
        'total_predicted': totalPredicted,
        'daily_average': averageDaily,
        'growth_rate': growth,
        'predictions': predictions,
        'description': growth > 0 
            ? 'Prediksi penjualan menunjukkan tren positif ${(growth * 100).toStringAsFixed(1)}%'
            : 'Prediksi penjualan menunjukkan penurunan ${(growth.abs() * 100).toStringAsFixed(1)}%',
        'confidence': 0.70,
        'is_mock': true,
      };
    } catch (e) {
      print('Error dalam mock prediksi penjualan: $e');
      return {
        'error': e.toString(),
        'is_mock': true,
      };
    }
  }

  /// Analisis kesehatan finansial dengan data mock
  Future<Map<String, dynamic>> analyzeFinancialHealth() async {
    if (!_isInitialized) {
      throw Exception('Mock AI Service belum diinisialisasi');
    }

    try {
      final healthScore = 60 + _random.nextDouble() * 30; // 60-90 score
      final cashFlowTrend = _random.nextDouble() * 0.3 - 0.15; // ±15%
      final profitMargin = 0.1 + _random.nextDouble() * 0.2; // 10-30%
      
      String healthStatus;
      List<String> recommendations = [];
      
      if (healthScore >= 80) {
        healthStatus = 'Sangat Baik';
        recommendations.add('Pertahankan kinerja yang baik');
        recommendations.add('Pertimbangkan ekspansi bisnis');
      } else if (healthScore >= 60) {
        healthStatus = 'Baik';
        recommendations.add('Tingkatkan efisiensi operasional');
        recommendations.add('Monitor cash flow secara berkala');
      } else {
        healthStatus = 'Perlu Perhatian';
        recommendations.add('Evaluasi struktur biaya');
        recommendations.add('Tingkatkan strategi penjualan');
      }

      return {
        'health_score': healthScore,
        'health_status': healthStatus,
        'cash_flow_trend': cashFlowTrend,
        'profit_margin': profitMargin,
        'recommendations': recommendations,
        'description': 'Analisis kesehatan finansial berdasarkan data historis dan tren saat ini',
        'confidence': 0.65,
        'is_mock': true,
      };
    } catch (e) {
      print('Error dalam mock analisis finansial: $e');
      return {
        'error': e.toString(),
        'is_mock': true,
      };
    }
  }

  /// Generate smart alerts dengan data mock
  Future<List<Map<String, dynamic>>> generateSmartAlerts() async {
    if (!_isInitialized) {
      throw Exception('Mock AI Service belum diinisialisasi');
    }

    try {
      final alerts = <Map<String, dynamic>>[];
      
      // Mock alert untuk stok rendah
      if (_random.nextBool()) {
        alerts.add({
          'type': 'stock_low',
          'title': 'Stok Produk Menipis',
          'message': 'Beberapa produk memiliki stok di bawah batas minimum',
          'priority': 'high',
          'timestamp': DateTime.now().toIso8601String(),
          'is_mock': true,
        });
      }
      
      // Mock alert untuk penjualan
      if (_random.nextBool()) {
        alerts.add({
          'type': 'sales_trend',
          'title': 'Tren Penjualan Positif',
          'message': 'Penjualan minggu ini meningkat 15% dari minggu sebelumnya',
          'priority': 'medium',
          'timestamp': DateTime.now().toIso8601String(),
          'is_mock': true,
        });
      }
      
      // Mock alert untuk keuangan
      if (_random.nextBool()) {
        alerts.add({
          'type': 'financial',
          'title': 'Cash Flow Stabil',
          'message': 'Arus kas menunjukkan stabilitas dalam 30 hari terakhir',
          'priority': 'low',
          'timestamp': DateTime.now().toIso8601String(),
          'is_mock': true,
        });
      }
      
      return alerts;
    } catch (e) {
      print('Error dalam generate mock alerts: $e');
      return [];
    }
  }

  void dispose() {
    _isInitialized = false;
    print('Mock AI Service disposed');
  }
}
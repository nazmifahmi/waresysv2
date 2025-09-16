import 'dart:math' as math;
import '../../../models/transaction_model.dart';
import '../../firestore_service.dart';
import '../tflite/custom_interpreter.dart';

class SalesPredictor {
  final FirestoreService _firestoreService = FirestoreService();
  final CustomInterpreter _interpreter = CustomInterpreter();
  bool _isInitialized = false;

  Future<void> initialize({required String modelPath}) async {
    if (_isInitialized) return;
    try {
      await _interpreter.loadModel(modelPath);
      _isInitialized = true;
      print('SalesPredictor berhasil diinisialisasi dengan model: $modelPath');
    } catch (e) {
      print('Gagal menginisialisasi SalesPredictor: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predictSales({String? productId}) async {
    if (!_isInitialized) {
      throw Exception("SalesPredictor belum diinisialisasi. Panggil AIService.initialize() terlebih dahulu.");
    }

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 180));
      final transactions = await _firestoreService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.sales,
        productId: productId,
      );

      final historicalData = await _processHistoricalSales(transactions);
      final historicalSales = List<double>.from(historicalData['daily_sales']);

      if (historicalSales.isEmpty) {
        return {
          'description': 'Tidak ada data penjualan historis yang cukup untuk membuat prediksi.',
          'actions': ['Pastikan ada transaksi penjualan yang tercatat untuk produk ini.'],
          'confidence': 0.0,
        };
      }

      final inputData = _prepareInputData(historicalData);

      // Panggil interpreter dan langsung parsing hasilnya dengan fungsi helper yang lebih kuat
      final predictionResult = await _interpreter.predict(inputData, outputLength: 30);
      final List<double> predictions = _parsePredictionResult(predictionResult);

      final confidence = _calculateConfidence(historicalSales, predictions);
      final insights = _generateInsights(predictions, historicalData);

      return {
        'daily_predictions': predictions,
        'total_predicted_revenue': predictions.reduce((a, b) => a + b),
        'average_daily_sales': predictions.reduce((a, b) => a + b) / predictions.length,
        'growth_rate': _calculateGrowthRate(historicalSales, predictions),
        'seasonal_factors': historicalData['seasonal_factors'],
        'description': insights['description'],
        'actions': insights['actions'],
        'confidence': confidence,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error dalam prediksi penjualan: $e');
      return {};
    }
  }

  // --- FUNGSI HELPER BARU YANG LEBIH DEFensif ---
  List<double> _parsePredictionResult(dynamic result) {
    if (result is! List || result.isEmpty) {
      return [];
    }

    // Cek jika hasilnya adalah list bersarang (nested list), misal: [[1.0, 2.0]]
    if (result[0] is List) {
      final nestedList = result[0] as List;
      return nestedList.map((e) => (e as num).toDouble()).toList();
    }
    // Jika tidak, asumsikan hasilnya adalah list biasa, misal: [1.0, 2.0]
    else {
      return result.map((e) => (e as num).toDouble()).toList();
    }
  }
  // --- AKHIR FUNGSI HELPER BARU ---

  Future<Map<String, dynamic>> _processHistoricalSales(List<TransactionModel> transactions) async {
    final Map<DateTime, double> dailySales = {};
    for (var trx in transactions) {
      final date = DateTime(trx.date.year, trx.date.month, trx.date.day);
      // --- PENCEGAHAN: Gunakan 0.0 (double) bukan 0 (int) ---
      dailySales[date] = (dailySales[date] ?? 0.0) + trx.total;
    }

    if (dailySales.isEmpty) {
      return {
        'daily_sales': <double>[],
        'seasonal_factors': <int, double>{},
      };
    }

    final Map<int, List<double>> weekdaySales = {};
    for (var entry in dailySales.entries) {
      final weekday = entry.key.weekday;
      weekdaySales[weekday] ??= [];
      weekdaySales[weekday]!.add(entry.value);
    }

    final Map<int, double> seasonalFactors = {};
    final overallAverage = dailySales.values.reduce((a, b) => a + b) / dailySales.length;

    for (var entry in weekdaySales.entries) {
      final weekdayAverage = entry.value.reduce((a, b) => a + b) / entry.value.length;
      seasonalFactors[entry.key] = weekdayAverage / overallAverage;
    }

    return {
      'daily_sales': dailySales.values.toList(),
      'seasonal_factors': seasonalFactors,
    };
  }

  List<double> _prepareInputData(Map<String, dynamic> historicalData) {
    final List<double> dailySales = List<double>.from(historicalData['daily_sales']);
    final Map<int, double> seasonalFactors = Map<int, double>.from(historicalData['seasonal_factors']);

    if (dailySales.isEmpty) return [];
    final maxSale = dailySales.reduce(math.max);
    // --- PENCEGAHAN: Gunakan 0.0 (double) bukan 0 (int) ---
    final normalizedSales = dailySales.map((sale) => maxSale > 0 ? sale / maxSale : 0.0).toList();

    final List<double> inputData = [...normalizedSales];
    seasonalFactors.forEach((weekday, factor) {
      inputData.add(factor);
    });

    return inputData;
  }

  double _calculateConfidence(List<double> historical, List<double> predictions) {
    if (historical.isEmpty) return 0.0;
    final historicalMean = historical.reduce((a, b) => a + b) / historical.length;
    if (historicalMean == 0) return 0.5;

    final variance = historical.map((x) => math.pow(x - historicalMean, 2)).reduce((a, b) => a + b) / historical.length;
    final volatility = math.sqrt(variance) / historicalMean;

    return math.max(0.5, 1 - volatility);
  }

  double _calculateGrowthRate(List<double> historical, List<double> predictions) {
    if (historical.isEmpty || predictions.isEmpty) return 0.0;

    final historicalAvg = historical.reduce((a, b) => a + b) / historical.length;
    if (historicalAvg == 0) return predictions.isNotEmpty ? 1.0 : 0.0;

    final predictedAvg = predictions.reduce((a, b) => a + b) / predictions.length;
    return (predictedAvg - historicalAvg) / historicalAvg;
  }

  Map<String, dynamic> _generateInsights(List<double> predictions, Map<String, dynamic> historicalData) {
    final List<String> actions = [];
    String description = '';
    final historicalSales = List<double>.from(historicalData['daily_sales']);

    if (historicalSales.isEmpty || predictions.isEmpty) {
      return {'description': 'Data tidak cukup untuk insight.', 'actions': []};
    }

    final growthRate = _calculateGrowthRate(historicalSales, predictions);
    final averagePredicted = predictions.reduce((a, b) => a + b) / predictions.length;
    final historicalAverage = historicalSales.reduce((a, b) => a + b) / historicalSales.length;

    if (growthRate > 0.1) {
      description = 'Penjualan diproyeksikan akan tumbuh secara signifikan. ';
      actions.add('Pastikan tingkat inventaris dapat mendukung pertumbuhan');
      actions.add('Pertimbangkan untuk meningkatkan skala operasi');
    } else if (growthRate > 0) {
      description = 'Penjualan menunjukkan potensi pertumbuhan yang moderat. ';
      actions.add('Pantau tingkat inventaris');
      actions.add('Cari peluang optimisasi');
    } else {
      description = 'Penjualan mungkin akan mengalami perlambatan. ';
      actions.add('Tinjau kembali strategi penetapan harga');
      actions.add('Analisis efektivitas pemasaran');
    }

    if (historicalAverage > 0 && averagePredicted > historicalAverage * 1.2) {
      description += 'Penjualan yang diharapkan berada di atas rata-rata historis secara signifikan. ';
      actions.add('Bersiap untuk peningkatan permintaan');
    } else if (historicalAverage > 0 && averagePredicted < historicalAverage * 0.8) {
      description += 'Penjualan yang diharapkan berada di bawah rata-rata historis. ';
      actions.add('Selidiki kemungkinan penyebabnya');
      actions.add('Kembangkan strategi peningkatan penjualan');
    }

    return {
      'description': description.trim(),
      'actions': actions,
    };
  }
}


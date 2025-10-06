import 'dart:math' as math;
import '../../../models/finance_model.dart';
import '../../../models/transaction_model.dart';
import '../../firestore_service.dart';
import '../tflite/custom_interpreter.dart';

class FinancialPredictor {
  final FirestoreService _firestoreService = FirestoreService();
  final CustomInterpreter _interpreter = CustomInterpreter();
  bool _isInitialized = false;

  Future<void> initialize({required String modelPath}) async {
    if (_isInitialized) return;
    try {
      await _interpreter.loadModel(modelPath);
      _isInitialized = true;
      print('FinancialPredictor berhasil diinisialisasi dengan model: $modelPath');
    } catch (e) {
      print('Gagal menginisialisasi FinancialPredictor: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analyzeFinancialHealth() async {
    if (!_isInitialized) {
      throw Exception("FinancialPredictor belum diinisialisasi. Panggil AIService.initialize() terlebih dahulu.");
    }

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 90));
      final transactions = await _firestoreService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      final metrics = await _calculateFinancialMetrics(transactions);
      final inputData = _prepareInputData(metrics);

      // --- PERBAIKAN: Menggunakan logika parsing yang kuat ---
      final predictionResult = await _interpreter.predict(inputData, outputLength: 4);
      final List<double> predictions = _parsePredictionResult(predictionResult);
      // --- AKHIR PERBAIKAN ---

      final healthScore = predictions.isNotEmpty ? predictions[0] : 0.0;
      final cashflowScore = predictions.length > 1 ? predictions[1] : 0.0;
      final profitabilityScore = predictions.length > 2 ? predictions[2] : 0.0;
      final efficiencyScore = predictions.length > 3 ? predictions[3] : 0.0;

      final insights = _generateInsights(
        healthScore,
        cashflowScore,
        profitabilityScore,
        efficiencyScore,
        metrics,
      );

      return {
        'health_score': healthScore,
        'cashflow_score': cashflowScore,
        'profitability_score': profitabilityScore,
        'efficiency_score': efficiencyScore,
        'description': insights['description'],
        'actions': insights['actions'],
        'metrics': metrics.map((key, value) => MapEntry(key, value.toDouble())),
        'confidence': 0.85,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error in financial health analysis: $e');
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

  Future<Map<String, double>> _calculateFinancialMetrics(List<TransactionModel> transactions) async {
    double totalRevenue = 0.0;
    double totalExpenses = 0.0;
    double accountsReceivable = 0.0;
    double accountsPayable = 0.0;

    for (var trx in transactions) {
      if (trx.type == TransactionType.sales) {
        totalRevenue += trx.total;
        if (trx.paymentStatus != PaymentStatus.paid) {
          accountsReceivable += trx.total;
        }
      } else if (trx.type == TransactionType.purchase) {
        totalExpenses += trx.total;
        if (trx.paymentStatus != PaymentStatus.paid) {
          accountsPayable += trx.total;
        }
      }
    }

    final grossProfit = totalRevenue - totalExpenses;
    final profitMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) : 0.0;
    final currentRatio = accountsPayable > 0 ? (accountsReceivable / accountsPayable) : 1.0;

    return {
      'revenue': totalRevenue,
      'expenses': totalExpenses,
      'gross_profit': grossProfit,
      'profit_margin': profitMargin,
      'accounts_receivable': accountsReceivable,
      'accounts_payable': accountsPayable,
      'current_ratio': currentRatio,
    };
  }

  List<double> _prepareInputData(Map<String, double> metrics) {
    return [
      metrics['revenue'] ?? 0.0,
      metrics['expenses'] ?? 0.0,
      metrics['gross_profit'] ?? 0.0,
      metrics['profit_margin'] ?? 0.0,
      metrics['accounts_receivable'] ?? 0.0,
      metrics['accounts_payable'] ?? 0.0,
      metrics['current_ratio'] ?? 0.0,
    ];
  }

  Map<String, dynamic> _generateInsights(
      double healthScore,
      double cashflowScore,
      double profitabilityScore,
      double efficiencyScore,
      Map<String, double> metrics,
      ) {
    final List<String> actions = [];
    String description = '';

    if (healthScore < 0.4) {
      description = 'Kesehatan finansial perlu perhatian segera. ';
      actions.add('Tinjau dan optimalkan biaya operasional');
      actions.add('Kembangkan rencana pemulihan keuangan');
    } else if (healthScore < 0.7) {
      description = 'Kesehatan finansial moderat tetapi perlu perbaikan. ';
      actions.add('Pantau arus kas dengan cermat');
      actions.add('Cari peluang optimisasi biaya');
    } else {
      description = 'Kesehatan finansial dalam kondisi baik. ';
      actions.add('Pertimbangkan peluang ekspansi');
      actions.add('Pertahankan praktik keuangan saat ini');
    }

    if (cashflowScore < 0.5) {
      description += 'Manajemen arus kas memerlukan perhatian. ';
      actions.add('Tinjau proses penagihan pembayaran');
      actions.add('Optimalkan tingkat inventaris');
    }

    if (profitabilityScore < 0.5) {
      description += 'Profitabilitas di bawah target. ';
      actions.add('Tinjau kembali strategi penetapan harga');
      actions.add('Analisis profitabilitas bauran produk');
    }

    if (efficiencyScore < 0.5) {
      description += 'Efisiensi operasional dapat ditingkatkan. ';
      actions.add('Rampingkan proses operasional');
      actions.add('Tinjau alokasi sumber daya');
    }

    return {
      'description': description.trim(),
      'actions': actions,
    };
  }
}


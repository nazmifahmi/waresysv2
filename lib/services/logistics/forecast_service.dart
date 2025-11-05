import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/forecast_result_model.dart';
import '../../models/logistics/forecast_model.dart';
import '../../models/transaction_model.dart';
import 'forecast_repository.dart';
import 'forecast_engine.dart';

class ForecastService {
  final FirebaseFirestore _firestore;
  final ForecastRepository _forecastRepository;
  ForecastService({FirebaseFirestore? firestore, ForecastRepository? forecastRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _forecastRepository = forecastRepository ?? ForecastRepository();

  Future<ForecastResultModel> generateDemandForecast(String productId) async {
    // Simple monthly demand forecasting using last 90 days sales moving average
    final since = DateTime.now().subtract(const Duration(days: 90));
    final snap = await _firestore
        .collection('transactions')
        .where('type', isEqualTo: TransactionType.sales.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    int totalSold = 0;
    for (final d in snap.docs) {
      final t = TransactionModel.fromFirestore(d);
      for (final item in t.items) {
        if (item.productId == productId) totalSold += item.quantity;
      }
    }

    final dailyAvg = totalSold / max(1, 90);
    final forecast30 = dailyAvg * 30;

    // current stock from products collection
    final productDoc = await _firestore.collection('products').doc(productId).get();
    final productData = productDoc.data() as Map<String, dynamic>?;
    final currentStock = (productData?['stock'] ?? 0) as int;

    // safety stock: 1.65 * sigma (approx). Here, use 20% of forecast as simple proxy.
    final safety = max(0, (forecast30 * 0.2).round());
    final recommendedPurchase = max(0, (forecast30 + safety - currentStock).round());

    return ForecastResultModel(
      productId: productId,
      forecastedDemand: forecast30,
      currentStock: currentStock,
      recommendedPurchaseQuantity: recommendedPurchase,
      safetyStockLevel: safety,
    );
  }

  Future<ForecastModel> upsertAggregateDemandForecast({
    double alpha = 0.3,
    double serviceLevelZ = 1.65,
    double leadTimeDays = 7,
  }) async {
    final since = DateTime.now().subtract(const Duration(days: 120));
    final snap = await _firestore
        .collection('transactions')
        .where('type', isEqualTo: TransactionType.sales.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    final Map<DateTime, int> daily = {};
    for (final d in snap.docs) {
      final t = TransactionModel.fromFirestore(d);
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      int qty = 0;
      for (final item in t.items) {
        qty += item.quantity;
      }
      daily[day] = (daily[day] ?? 0) + qty;
    }

    final days = daily.keys.toList()..sort();
    final series = days.map((e) => (daily[e] ?? 0).toDouble()).toList();
    final dailyAvg = series.isEmpty ? 0.0 : series.reduce((a, b) => a + b) / max(1, series.length);

    final nextDaily = ForecastEngine.exponentialSmoothingNext(series, alpha);
    final forecast30 = nextDaily * 30;

    final smoothed = ForecastEngine.exponentialSmoothingSeries(series, alpha);
    final int k = min(30, series.length);
    final actualTail = k == 0 ? <double>[] : series.sublist(series.length - k);
    final forecastTail = k == 0 ? <double>[] : smoothed.sublist(smoothed.length - k);
    final mape = ForecastEngine.mape(actualTail, forecastTail);
    final accuracyPercent = max(0.0, min(100.0, (1 - mape) * 100));

    double mean = dailyAvg;
    double variance = 0.0;
    for (final v in series) {
      variance += pow(v - mean, 2) as double;
    }
    variance = series.isEmpty ? 0.0 : variance / max(1, series.length);
    final stdDev = sqrt(variance);
    final safety = ForecastEngine.safetyStock(
      demandStdDevPerDay: stdDev,
      serviceLevelZ: serviceLevelZ,
      leadTimeDays: leadTimeDays,
    );
    final rop = ForecastEngine.reorderPoint(
      dailyAvg: dailyAvg,
      leadTimeDays: leadTimeDays,
      safetyStock: safety,
    );

    final model = ForecastModel(
      forecastId: 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      category: 'Demand',
      predictedDemand: forecast30,
      accuracyRate: accuracyPercent,
      updatedAt: DateTime.now(),
    );
    await _forecastRepository.create(model);
    return model;
  }
}
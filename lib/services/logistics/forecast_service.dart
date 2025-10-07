import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/forecast_result_model.dart';
import '../../models/transaction_model.dart';

class ForecastService {
  final FirebaseFirestore _firestore;
  ForecastService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

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
}
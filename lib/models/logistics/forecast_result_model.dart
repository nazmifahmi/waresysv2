class ForecastResultModel {
  final String productId;
  final double forecastedDemand;
  final int currentStock;
  final int recommendedPurchaseQuantity;
  final int safetyStockLevel;

  ForecastResultModel({
    required this.productId,
    required this.forecastedDemand,
    required this.currentStock,
    required this.recommendedPurchaseQuantity,
    required this.safetyStockLevel,
  });
}
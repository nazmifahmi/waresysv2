import 'dart:math';

class ForecastEngine {
  static double exponentialSmoothingNext(List<double> series, double alpha) {
    if (series.isEmpty) return 0.0;
    double s = series.first;
    for (int i = 1; i < series.length; i++) {
      s = alpha * series[i] + (1 - alpha) * s;
    }
    return s;
  }

  static List<double> exponentialSmoothingSeries(List<double> series, double alpha) {
    if (series.isEmpty) return <double>[];
    final result = List<double>.filled(series.length, 0.0);
    double s = series.first;
    result[0] = s;
    for (int i = 1; i < series.length; i++) {
      s = alpha * series[i] + (1 - alpha) * s;
      result[i] = s;
    }
    return result;
  }

  static double mape(List<double> actuals, List<double> forecasts) {
    final n = min(actuals.length, forecasts.length);
    if (n == 0) return 1.0;
    double sum = 0.0;
    int count = 0;
    for (int i = 0; i < n; i++) {
      final a = actuals[i];
      final f = forecasts[i];
      if (a <= 0) continue;
      sum += (a - f).abs() / a;
      count++;
    }
    if (count == 0) return 1.0;
    return sum / count;
  }

  static double mae(List<double> actuals, List<double> forecasts) {
    final n = min(actuals.length, forecasts.length);
    if (n == 0) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      sum += (actuals[i] - forecasts[i]).abs();
    }
    return sum / n;
  }

  static double rmse(List<double> actuals, List<double> forecasts) {
    final n = min(actuals.length, forecasts.length);
    if (n == 0) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      final e = actuals[i] - forecasts[i];
      sum += e * e;
    }
    return sqrt(sum / n);
  }

  static int safetyStock({
    required double demandStdDevPerDay,
    required double serviceLevelZ,
    required double leadTimeDays,
  }) {
    final value = serviceLevelZ * demandStdDevPerDay * sqrt(max(1.0, leadTimeDays));
    return max(0, value.round());
  }

  static int reorderPoint({
    required double dailyAvg,
    required double leadTimeDays,
    required int safetyStock,
  }) {
    final value = dailyAvg * leadTimeDays + safetyStock;
    return max(0, value.round());
  }
}
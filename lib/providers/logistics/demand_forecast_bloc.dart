import 'dart:async';
import '../../models/logistics/forecast_result_model.dart';
import '../../services/logistics/forecast_service.dart';

class DemandForecastBloc {
  final ForecastService _service;
  final _resultCtrl = StreamController<ForecastResultModel?>.broadcast();
  final _loadingCtrl = StreamController<bool>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();

  Stream<ForecastResultModel?> get result => _resultCtrl.stream;
  Stream<bool> get loading => _loadingCtrl.stream;
  Stream<String?> get error => _errorCtrl.stream;

  DemandForecastBloc({required ForecastService service}) : _service = service;

  Future<void> run(String productId) async {
    _loadingCtrl.add(true);
    try {
      final res = await _service.generateDemandForecast(productId);
      _resultCtrl.add(res);
      _errorCtrl.add(null);
    } catch (e) {
      _errorCtrl.add(e.toString());
    } finally {
      _loadingCtrl.add(false);
    }
  }

  void dispose() {
    _resultCtrl.close();
    _loadingCtrl.close();
    _errorCtrl.close();
  }
}
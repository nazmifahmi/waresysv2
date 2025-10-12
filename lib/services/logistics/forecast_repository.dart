import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/logistics/forecast_model.dart';

class ForecastRepository {
  final FirebaseFirestore _firestore;
  ForecastRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _forecasts => _firestore.collection('forecasts');

  Future<List<ForecastModel>> getAll({String? category}) async {
    Query query = _forecasts.orderBy('updatedAt', descending: true);
    if (category != null && category.trim().isNotEmpty) {
      query = _forecasts.where('category', isEqualTo: category);
    }
    final snap = await query.get();
    return snap.docs.map((d) => ForecastModel.fromDoc(d)).toList();
  }

  Stream<List<ForecastModel>> watchAll() {
    return _forecasts.orderBy('updatedAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => ForecastModel.fromDoc(d)).toList());
  }

  Future<ForecastModel?> getById(String id) async {
    final doc = await _forecasts.doc(id).get();
    if (!doc.exists) return null;
    return ForecastModel.fromDoc(doc);
  }

  Future<String> create(ForecastModel forecast) async {
    final ref = await _forecasts.add(forecast.toMap());
    await _forecasts.doc(ref.id).update({'forecastId': ref.id});
    return ref.id;
  }

  Future<void> update(ForecastModel forecast) async {
    await _forecasts.doc(forecast.forecastId).update(forecast.toMap());
  }

  Future<void> delete(String id) async {
    await _forecasts.doc(id).delete();
  }

  Stream<List<ForecastModel>> watchByCategory(String category) {
    return _forecasts.where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ForecastModel.fromDoc(d)).toList());
  }

  Future<List<ForecastModel>> getHighAccuracyForecasts({double minAccuracy = 0.8}) async {
    final snap = await _forecasts
        .where('accuracyRate', isGreaterThanOrEqualTo: minAccuracy)
        .orderBy('accuracyRate', descending: true)
        .get();
    return snap.docs.map((d) => ForecastModel.fromDoc(d)).toList();
  }

  Future<double> getAverageAccuracyByCategory(String category) async {
    final snap = await _forecasts.where('category', isEqualTo: category).get();
    if (snap.docs.isEmpty) return 0.0;
    
    final accuracies = snap.docs.map((d) => (d.data()['accuracyRate'] ?? 0.0) as double);
    return accuracies.reduce((a, b) => a + b) / accuracies.length;
  }
}
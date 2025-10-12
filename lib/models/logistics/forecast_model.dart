import 'package:cloud_firestore/cloud_firestore.dart';

class ForecastModel {
  final String forecastId;
  final String category;
  final double predictedDemand;
  final double accuracyRate;
  final DateTime updatedAt;

  ForecastModel({
    required this.forecastId,
    required this.category,
    required this.predictedDemand,
    required this.accuracyRate,
    required this.updatedAt,
  }) : assert(forecastId.isNotEmpty, 'forecastId cannot be empty'),
       assert(category.isNotEmpty, 'category cannot be empty'),
       assert(predictedDemand >= 0, 'predictedDemand must be >= 0'),
       assert(accuracyRate >= 0 && accuracyRate <= 100, 'accuracyRate must be between 0 and 100');

  Map<String, dynamic> toMap() => {
        'forecastId': forecastId,
        'category': category,
        'predictedDemand': predictedDemand,
        'accuracyRate': accuracyRate,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'categoryLower': category.toLowerCase(),
      };

  factory ForecastModel.fromMap(Map<String, dynamic> map) => ForecastModel(
        forecastId: map['forecastId'],
        category: map['category'],
        predictedDemand: (map['predictedDemand'] as num).toDouble(),
        accuracyRate: (map['accuracyRate'] as num).toDouble(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );

  factory ForecastModel.fromDoc(DocumentSnapshot doc) =>
      ForecastModel.fromMap({...doc.data() as Map<String, dynamic>, 'forecastId': doc.id});
}
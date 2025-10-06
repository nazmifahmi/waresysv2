enum InsightType {
  stockPrediction,
  financialHealth,
  salesForecast,
  smartAlert,
  customerBehavior,
  operationalOptimization,
  businessIntelligence,
  riskAssessment
}

enum InsightPriority {
  low,
  medium,
  high,
  critical
}

class AIInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final InsightPriority priority;
  final List<String>? recommendedActions;
  final double? confidence;

  AIInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.timestamp,
    required this.priority,
    this.recommendedActions,
    this.confidence,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.toString(),
    'title': title,
    'description': description,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'priority': priority.toString(),
    'recommendedActions': recommendedActions,
    'confidence': confidence,
  };

  factory AIInsight.fromMap(Map<String, dynamic> map) => AIInsight(
    id: map['id'],
    type: InsightType.values.firstWhere(
      (e) => e.toString() == map['type'],
      orElse: () => InsightType.stockPrediction,
    ),
    title: map['title'],
    description: map['description'],
    data: map['data'],
    timestamp: DateTime.parse(map['timestamp']),
    priority: InsightPriority.values.firstWhere(
      (e) => e.toString() == map['priority'],
      orElse: () => InsightPriority.medium,
    ),
    recommendedActions: List<String>.from(map['recommendedActions'] ?? []),
    confidence: map['confidence']?.toDouble(),
  );
} 
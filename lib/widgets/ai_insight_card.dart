import 'package:flutter/material.dart';
import '../models/ai_insight_model.dart';

class AIInsightCard extends StatelessWidget {
  final AIInsight insight;
  final VoidCallback? onActionTap;

  const AIInsightCard({
    Key? key,
    required this.insight,
    this.onActionTap,
  }) : super(key: key);

  Color _getPriorityColor() {
    switch (insight.priority) {
      case InsightPriority.critical:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return Colors.yellow;
      case InsightPriority.low:
        return Colors.green;
    }
  }

  IconData _getTypeIcon() {
    switch (insight.type) {
      case InsightType.stockPrediction:
        return Icons.inventory;
      case InsightType.financialHealth:
        return Icons.account_balance;
      case InsightType.salesForecast:
        return Icons.trending_up;
      case InsightType.smartAlert:
        return Icons.notification_important;
      case InsightType.customerBehavior:
        return Icons.people;
      case InsightType.operationalOptimization:
        return Icons.settings_suggest;
      case InsightType.businessIntelligence:
        return Icons.insights;
      case InsightType.riskAssessment:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onActionTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getTypeIcon(), color: _getPriorityColor()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (insight.confidence != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(insight.confidence! * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                insight.description,
                style: const TextStyle(fontSize: 14),
              ),
              if (insight.recommendedActions?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Recommended Actions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                ...insight.recommendedActions!.map((action) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          action,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 
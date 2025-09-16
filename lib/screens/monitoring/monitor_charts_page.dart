import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/transaction_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction_model.dart';
import '../../models/finance_model.dart';

class MonitorChartsPage extends StatefulWidget {
  const MonitorChartsPage({super.key});

  @override
  State<MonitorChartsPage> createState() => _MonitorChartsPageState();
}

class _MonitorChartsPageState extends State<MonitorChartsPage> {
  String _selectedType = 'Finance'; // Finance or Inventory
  String _selectedPeriod = 'Weekly'; // Weekly, Monthly, Yearly
  final _transactionService = TransactionService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle buttons for type selection
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(25),
              fillColor: Colors.green,
              selectedColor: Colors.white,
              color: Colors.grey,
              constraints: const BoxConstraints(
                minWidth: 120,
                minHeight: 40,
              ),
              isSelected: [
                _selectedType == 'Finance',
                _selectedType == 'Inventory',
              ],
              onPressed: (index) {
                setState(() {
                  _selectedType = index == 0 ? 'Finance' : 'Inventory';
                });
              },
              children: const [
                Row(
                  children: [
                    Icon(Icons.attach_money),
                    SizedBox(width: 8),
                    Text('Finance'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.inventory_2),
                    SizedBox(width: 8),
                    Text('Inventory'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Period selection
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(25),
              fillColor: Colors.green,
              selectedColor: Colors.white,
              color: Colors.grey,
              constraints: const BoxConstraints(
                minWidth: 100,
                minHeight: 40,
              ),
              isSelected: [
                _selectedPeriod == 'Weekly',
                _selectedPeriod == 'Monthly',
                _selectedPeriod == 'Yearly',
              ],
              onPressed: (index) {
                setState(() {
                  _selectedPeriod = index == 0 
                    ? 'Weekly' 
                    : index == 1 
                      ? 'Monthly' 
                      : 'Yearly';
                });
              },
              children: const [
                Text('Weekly'),
                Text('Monthly'),
                Text('Yearly'),
              ],
            ),
          ),
        ),

        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _selectedType == 'Finance'
                ? _buildFinanceChart()
                : _buildInventoryChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceChart() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactionsStream(
        type: TransactionType.sales,
        startDate: _getStartDate(),
      ),
      builder: (context, salesSnapshot) {
        return StreamBuilder<List<TransactionModel>>(
          stream: _transactionService.getTransactionsStream(
            type: TransactionType.purchase,
            startDate: _getStartDate(),
          ),
          builder: (context, purchaseSnapshot) {
            if (!salesSnapshot.hasData || !purchaseSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final salesData = _processTransactionData(
              salesSnapshot.data!.where((t) => t.paymentStatus == PaymentStatus.paid).toList()
            );
            final purchaseData = _processTransactionData(
              purchaseSnapshot.data!.where((t) => t.paymentStatus == PaymentStatus.paid).toList()
            );

            return LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact().format(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.now().subtract(
                          Duration(days: (_getMaxPoints() - value.toInt())),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: salesData,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: purchaseData,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryChart() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getStockLogsStream(startDate: _getStartDate()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stockInData = _processStockData(snapshot.data!, true);
        final stockOutData = _processStockData(snapshot.data!, false);

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.now().subtract(
                      Duration(days: (_getMaxPoints() - value.toInt())),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('d/M').format(date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // Stock In line
              LineChartBarData(
                spots: stockInData,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                dotData: FlDotData(show: false),
              ),
              // Stock Out line
              LineChartBarData(
                spots: stockOutData,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Weekly':
        return now.subtract(const Duration(days: 7));
      case 'Monthly':
        return DateTime(now.year, now.month - 1, now.day);
      case 'Yearly':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  int _getMaxPoints() {
    switch (_selectedPeriod) {
      case 'Weekly':
        return 7;
      case 'Monthly':
        return 30;
      case 'Yearly':
        return 12;
      default:
        return 7;
    }
  }

  List<FlSpot> _processTransactionData(List<TransactionModel> transactions) {
    final points = List.generate(_getMaxPoints(), (index) => 0.0);
    final now = DateTime.now();

    for (var transaction in transactions) {
      final diff = now.difference(transaction.createdAt).inDays;
      if (diff < _getMaxPoints()) {
        points[_getMaxPoints() - diff - 1] += transaction.total;
      }
    }

    return List.generate(
      _getMaxPoints(),
      (index) => FlSpot(index.toDouble(), points[index]),
    );
  }

  List<FlSpot> _processStockData(List<Map<String, dynamic>> logs, bool isStockIn) {
    final points = List.generate(_getMaxPoints(), (index) => 0.0);
    final now = DateTime.now();

    for (var log in logs) {
      final timestamp = (log['timestamp'] as Timestamp).toDate();
      final diff = now.difference(timestamp).inDays;
      final qty = (log['qty'] as num).toDouble();
      final type = log['type'] as String;

      if (diff < _getMaxPoints() && 
          ((isStockIn && type == 'in') || (!isStockIn && type == 'out'))) {
        points[_getMaxPoints() - diff - 1] += qty;
      }
    }

    return List.generate(
      _getMaxPoints(),
      (index) => FlSpot(index.toDouble(), points[index]),
    );
  }
} 
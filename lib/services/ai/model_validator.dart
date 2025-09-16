import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../firestore_service.dart';
import 'ai_logger.dart';
import 'tflite/custom_interpreter.dart';
import '../../models/transaction_model.dart';

class ModelValidator {
  static final ModelValidator _instance = ModelValidator._internal();
  factory ModelValidator() => _instance;
  
  final FirestoreService _firestoreService = FirestoreService();
  final AILogger _logger = AILogger();
  
  ModelValidator._internal();

  Future<Map<String, dynamic>> validateModel({
    required String modelName,
    required CustomInterpreter interpreter,
    required List<Map<String, dynamic>> testData,
    required Map<String, dynamic> Function(Map<String, dynamic>) prepareInput,
    required bool Function(Map<String, dynamic>, List<double>) validateOutput,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      int totalTests = 0;
      int passedTests = 0;
      double totalError = 0;
      List<Map<String, dynamic>> failedCases = [];
      
      final startTime = DateTime.now();
      
      for (var testCase in testData) {
        try {
          totalTests++;
          
          // Prepare input data
          final input = prepareInput(testCase);
          
          // Run prediction
          final predictions = await interpreter.predict(
            input['data'],
            outputLength: input['outputLength'] ?? 7,
          );
          
          // Validate output
          final isValid = validateOutput(testCase, predictions);
          if (isValid) {
            passedTests++;
          } else {
            failedCases.add({
              'input': testCase,
              'predictions': predictions,
              'expected': testCase['expected'],
            });
          }
          
          // Calculate error if expected values are available
          if (testCase['expected'] != null) {
            final expectedValues = List<double>.from(testCase['expected']);
            double error = 0;
            for (int i = 0; i < math.min(predictions.length, expectedValues.length); i++) {
              error += math.pow(predictions[i] - expectedValues[i], 2);
            }
            totalError += math.sqrt(error / predictions.length);
          }
        } catch (e, stackTrace) {
          await _logger.logError(
            component: 'model_validation',
            message: 'Test case failed',
            error: e,
            stackTrace: stackTrace,
            context: {'testCase': testCase},
          );
          failedCases.add({
            'input': testCase,
            'error': e.toString(),
          });
        }
      }
      
      final executionTime = DateTime.now().difference(startTime);
      final accuracy = totalTests > 0 ? passedTests / totalTests : 0;
      final averageError = totalTests > 0 ? totalError / totalTests : double.infinity;
      
      final results = {
        'modelName': modelName,
        'timestamp': DateTime.now().toIso8601String(),
        'totalTests': totalTests,
        'passedTests': passedTests,
        'accuracy': accuracy,
        'averageError': averageError,
        'executionTimeMs': executionTime.inMilliseconds,
        'failedCases': failedCases,
        'metadata': metadata,
      };
      
      // Log validation results
      await _logger.log(
        component: 'model_validation',
        message: 'Model validation completed',
        level: accuracy >= 0.95 ? AILogLevel.info : AILogLevel.warning,
        data: results,
        modelName: modelName,
      );
      
      return results;
    } catch (e, stackTrace) {
      await _logger.logError(
        component: 'model_validation',
        message: 'Model validation failed',
        error: e,
        stackTrace: stackTrace,
        context: {'modelName': modelName},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validateStockPredictor(CustomInterpreter interpreter) async {
    // Get historical data for testing
    final testData = await _generateStockTestData();
    
    return validateModel(
      modelName: 'stock_predictor',
      interpreter: interpreter,
      testData: testData,
      prepareInput: (testCase) {
        final List<double> stockLevels = List<double>.from(testCase['stockLevels']);
        return {
          'data': stockLevels,
          'outputLength': 7,
        };
      },
      validateOutput: (testCase, predictions) {
        if (testCase['expected'] == null) return true;
        
        final List<double> expected = List<double>.from(testCase['expected']);
        if (predictions.length != expected.length) return false;
        
        // Calculate mean absolute percentage error
        double totalError = 0;
        for (int i = 0; i < predictions.length; i++) {
          if (expected[i] != 0) {
            totalError += (predictions[i] - expected[i]).abs() / expected[i];
          }
        }
        final mape = totalError / predictions.length;
        
        // Accept if MAPE is less than 20%
        return mape < 0.2;
      },
      metadata: {'validationType': 'historical_comparison'},
    );
  }

  Future<Map<String, dynamic>> validateSalesPredictor(CustomInterpreter interpreter) async {
    final testData = await _generateSalesTestData();
    
    return validateModel(
      modelName: 'sales_predictor',
      interpreter: interpreter,
      testData: testData,
      prepareInput: (testCase) {
        final List<double> salesData = List<double>.from(testCase['salesData']);
        final Map<String, double> seasonalFactors = Map<String, double>.from(testCase['seasonalFactors']);
        
        return {
          'data': [...salesData, ...seasonalFactors.values],
          'outputLength': 30,
        };
      },
      validateOutput: (testCase, predictions) {
        if (testCase['expected'] == null) return true;
        
        final List<double> expected = List<double>.from(testCase['expected']);
        if (predictions.length != expected.length) return false;
        
        // Calculate R-squared value
        final meanExpected = expected.reduce((a, b) => a + b) / expected.length;
        double totalSS = 0;
        double residualSS = 0;
        
        for (int i = 0; i < predictions.length; i++) {
          totalSS += math.pow(expected[i] - meanExpected, 2);
          residualSS += math.pow(predictions[i] - expected[i], 2);
        }
        
        final rSquared = 1 - (residualSS / totalSS);
        
        // Accept if R-squared is greater than 0.7
        return rSquared > 0.7;
      },
      metadata: {'validationType': 'regression_analysis'},
    );
  }

  Future<List<Map<String, dynamic>>> _generateStockTestData() async {
    final products = await _firestoreService.getProducts();
    final testData = <Map<String, dynamic>>[];
    
    for (var product in products) {
      final stockLogs = await _firestoreService.getStockLogs(
        productId: product.id,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
      );
      
      if (stockLogs.length >= 30) {
        // Create test case from historical data
        final List<double> stockLevels = stockLogs
          .map((log) => (log['after'] as num).toDouble())
          .take(30)
          .toList();
        
        // Use next 7 days as expected values if available
        List<double>? expected;
        if (stockLogs.length >= 37) {
          expected = stockLogs
            .map((log) => (log['after'] as num).toDouble())
            .skip(30)
            .take(7)
            .toList();
        }
        
        testData.add({
          'productId': product.id,
          'stockLevels': stockLevels,
          'expected': expected,
        });
      }
    }
    
    return testData;
  }

  Future<List<Map<String, dynamic>>> _generateSalesTestData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 180));
    
    final transactions = await _firestoreService.getTransactions(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.sales,
    );
    
    // Group by product
    final productSales = <String, List<Map<String, dynamic>>>{};
    for (var trx in transactions) {
      // Get first product ID from transaction items
      if (trx.items.isEmpty) continue;
      final productId = trx.items.first.productId;
      productSales[productId] ??= [];
      productSales[productId]!.add({
        'date': trx.date,
        'total': trx.total.toDouble(),
      });
    }
    
    final testData = <Map<String, dynamic>>[];
    
    for (var entry in productSales.entries) {
      if (entry.value.length >= 90) {  // Need at least 90 days of data
        // Sort by date
        entry.value.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        
        // Calculate daily sales
        final dailySales = <double>[];
        var currentDate = entry.value.first['date'] as DateTime;
        var currentTotal = 0.0;
        
        for (var sale in entry.value) {
          final saleDate = sale['date'] as DateTime;
          if (saleDate.difference(currentDate).inDays > 0) {
            dailySales.add(currentTotal);
            currentDate = saleDate;
            currentTotal = (sale['total'] as double);
          } else {
            currentTotal += (sale['total'] as double);
          }
        }
        dailySales.add(currentTotal);
        
        // Calculate seasonal factors
        final weekdaySales = <int, List<double>>{};
        var date = entry.value.first['date'] as DateTime;
        for (var sale in dailySales) {
          final weekday = date.weekday;
          weekdaySales[weekday] ??= [];
          weekdaySales[weekday]!.add(sale);
          date = date.add(const Duration(days: 1));
        }
        
        final seasonalFactors = <String, double>{};
        final overallAverage = dailySales.reduce((a, b) => a + b) / dailySales.length;
        
        weekdaySales.forEach((weekday, sales) {
          final average = sales.reduce((a, b) => a + b) / sales.length;
          seasonalFactors['weekday_$weekday'] = average / overallAverage;
        });
        
        // Use first 150 days for input, last 30 for expected values
        if (dailySales.length >= 180) {
          testData.add({
            'productId': entry.key,
            'salesData': dailySales.sublist(0, 150),
            'seasonalFactors': seasonalFactors,
            'expected': dailySales.sublist(150, 180),
          });
        }
      }
    }
    
    return testData;
  }
} 
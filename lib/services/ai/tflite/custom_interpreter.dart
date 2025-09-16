import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'data_transformer.dart';

class CustomInterpreter {
  late final Interpreter _interpreter;
  bool _isInitialized = false;
  
  // Input shape information
  List<int>? _inputShape;
  List<int>? _outputShape;
  TfLiteType? _inputType;
  TfLiteType? _outputType;

  Future<void> loadModel(String modelPath) async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isInitialized = true;
      
      // Get model input/output information
      var inputTensor = _interpreter.getInputTensor(0);
      var outputTensor = _interpreter.getOutputTensor(0);
      
      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;
      
      // Get tensor types directly from the tensor
      _inputType = inputTensor.type as TfLiteType;
      _outputType = outputTensor.type as TfLiteType;
      
      debugPrint('Model loaded successfully');
      debugPrint('Input shape: $_inputShape');
      debugPrint('Output shape: $_outputShape');
      debugPrint('Input type: $_inputType');
      debugPrint('Output type: $_outputType');
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
      rethrow;
    }
  }

  Future<List<double>> predict(List<double> input, {int outputLength = 7}) async {
    if (!_isInitialized) {
      throw Exception('Interpreter not initialized. Call loadModel first.');
    }

    try {
      // Validate input
      if (input.isEmpty) {
        throw Exception('Input data cannot be empty');
      }

      // Convert input data using transformer
      final inputArray = DataTransformer.toFloat32List(input);
      final outputArray = Float32List(outputLength);

      // Create input and output buffers
      final inputBuffer = DataTransformer.toByteData(inputArray);
      final outputBuffer = DataTransformer.toByteData(outputArray);

      // Run inference using buffers
      try {
        _interpreter.run(inputBuffer, outputBuffer);
        final result = DataTransformer.fromFloat32List(
          DataTransformer.fromByteData(outputBuffer, outputLength)
        );
        return result;
      } catch (e) {
        debugPrint('Primary inference method failed: $e');
        // Fallback to alternative method
        final inputTensor = [input];
        final outputTensor = List<double>.filled(outputLength, 0.0);
        _interpreter.run(inputTensor, outputTensor);
        return outputTensor;
      }
    } catch (e) {
      debugPrint('Prediction error: $e');
      rethrow;
    }
  }

  List<int>? get inputShape => _inputShape;
  List<int>? get outputShape => _outputShape;
  TfLiteType? get inputType => _inputType;
  TfLiteType? get outputType => _outputType;

  void dispose() {
    if (_isInitialized) {
      try {
        _interpreter.close();
      } catch (e) {
        debugPrint('Error disposing interpreter: $e');
      } finally {
        _isInitialized = false;
      }
    }
  }
} 
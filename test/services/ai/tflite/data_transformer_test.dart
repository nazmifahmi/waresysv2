import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waresys_fix1/services/ai/tflite/data_transformer.dart';

void main() {
  group('DataTransformer Tests', () {
    test('toFloat32List should convert List<double> correctly', () {
      final input = [1.0, 2.0, 3.0, 4.0];
      final result = DataTransformer.toFloat32List(input);
      
      expect(result, isA<Float32List>());
      expect(result.length, equals(input.length));
      for (var i = 0; i < input.length; i++) {
        expect(result[i], equals(input[i]));
      }
    });

    test('fromFloat32List should convert Float32List correctly', () {
      final input = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
      final result = DataTransformer.fromFloat32List(input);
      
      expect(result, isA<List<double>>());
      expect(result.length, equals(input.length));
      for (var i = 0; i < input.length; i++) {
        expect(result[i], equals(input[i]));
      }
    });

    test('toByteData should convert Float32List to ByteData correctly', () {
      final input = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
      final result = DataTransformer.toByteData(input);
      
      expect(result, isA<ByteData>());
      expect(result.lengthInBytes, equals(input.length * 4)); // 4 bytes per float
    });

    test('fromByteData should convert ByteData to Float32List correctly', () {
      final originalData = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
      final byteData = DataTransformer.toByteData(originalData);
      final result = DataTransformer.fromByteData(byteData, originalData.length);
      
      expect(result, isA<Float32List>());
      expect(result.length, equals(originalData.length));
      for (var i = 0; i < originalData.length; i++) {
        expect(result[i], equals(originalData[i]));
      }
    });

    test('should handle empty input gracefully', () {
      final emptyList = <double>[];
      final result = DataTransformer.toFloat32List(emptyList);
      
      expect(result, isA<Float32List>());
      expect(result.length, equals(0));
    });

    test('should handle large numbers correctly', () {
      final largeNumbers = [1e10, 1e-10, double.maxFinite, double.minPositive];
      final result = DataTransformer.toFloat32List(largeNumbers);
      final converted = DataTransformer.fromFloat32List(result);
      
      for (var i = 0; i < largeNumbers.length; i++) {
        // Use closeTo for floating point comparison
        expect(converted[i], closeTo(largeNumbers[i], 1e-6));
      }
    });
  });
} 
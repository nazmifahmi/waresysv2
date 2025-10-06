import 'dart:typed_data';

/// Utility class for transforming data between different formats used in TFLite operations
class DataTransformer {
  /// Converts a List<double> to Float32List
  static Float32List toFloat32List(List<double> input) {
    return Float32List.fromList(input);
  }

  /// Converts a Float32List back to List<double>
  static List<double> fromFloat32List(Float32List input) {
    return input.toList();
  }

  /// Converts Float32List to ByteData
  static ByteData toByteData(Float32List input) {
    final buffer = input.buffer;
    return buffer.asByteData();
  }

  /// Converts ByteData back to Float32List
  static Float32List fromByteData(ByteData data, int length) {
    final buffer = data.buffer;
    return Float32List.view(buffer, 0, length);
  }
} 
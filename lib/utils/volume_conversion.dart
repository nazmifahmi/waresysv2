class VolumeConversion {
  static const Map<String, double> _toM3 = {
    'm3': 1.0,
    'liter': 0.001, // 1 L = 0.001 m3
    'l': 0.001,
    'cm3': 1e-6, // 1 cm3 = 1e-6 m3
    'cc': 1e-6,
    'ft3': 0.0283168466, // 1 ft3 = 0.0283168466 m3
  };

  static const Map<String, double> _fromM3 = {
    'm3': 1.0,
    'liter': 1000.0,
    'l': 1000.0,
    'cm3': 1e6,
    'cc': 1e6,
    'ft3': 35.3146667,
  };

  static double convert(double value, {required String from, required String to}) {
    final f = from.toLowerCase();
    final t = to.toLowerCase();
    if (!_toM3.containsKey(f)) {
      throw ArgumentError('Satuan volume tidak didukung: $from');
    }
    if (!_fromM3.containsKey(t)) {
      throw ArgumentError('Satuan volume tidak didukung: $to');
    }
    final inM3 = value * (_toM3[f]!);
    return inM3 * (_fromM3[t]!);
  }
}
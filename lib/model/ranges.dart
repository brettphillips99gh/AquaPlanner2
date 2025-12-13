import 'dart:math' as math;

/// Abstract base class for all biological ranges.
/// Defines the common structure and logic.
abstract class RangeValues {
  double get idealMin;
  double get idealMax;
  double get tolerableMin;
  double get tolerableMax;

  bool contains(double value) => value >= tolerableMin && value <= tolerableMax;

// Add the intersection method to the abstract base class.
  RangeValues? intersection(RangeValues other) {
    // The intersection should be based on the 'ideal' range, as that's the
    // truly safe overlapping zone for multiple species.
    final double newIdealMin = math.max(idealMin, other.idealMin);
    final double newIdealMax = math.min(idealMax, other.idealMax);

    // If the new ideal range is invalid (e.g., min > max), there is no valid intersection.
    if (newIdealMin >= newIdealMax) {
      return null;
    }

    // We have a valid intersection of ideal ranges. Now, we need to create
    // a new RangeValues object. Since we don't know which specific type
    // to return (Temp, pH, etc.), we can't use the specific constructors.
    // Instead, we'll create a new, generic private implementation.
    // This is a good use case for a private class that isn't one of the main four.
    return _GenericRange(
      idealMin: newIdealMin,
      idealMax: newIdealMax,
      // We can estimate the new tolerable range from the new ideal range
      // using a default padding, as the specific type is lost.
      tolerableMin: newIdealMin - ((newIdealMax - newIdealMin) * 0.15),
      tolerableMax: newIdealMax + ((newIdealMax - newIdealMin) * 0.15),
    );

  }
  @override
  String toString() =>
      'Tolerable: ${tolerableMin.toStringAsFixed(1)}-${tolerableMax.toStringAsFixed(1)}, Ideal: ${idealMin.toStringAsFixed(1)}-${idealMax.toStringAsFixed(1)}';
}

// We need a generic implementation for the intersection method to return.
class _GenericRange extends RangeValues {
  @override
  final double idealMin, idealMax, tolerableMin, tolerableMax;

  _GenericRange({
    required this.idealMin,
    required this.idealMax,
    required this.tolerableMin,
    required this.tolerableMax,
  });
}


// --- TYPE-SAFE, DISTINCT IMPLEMENTATIONS ---

/// A type-safe implementation for Temperature ranges.
class TemperatureRange extends RangeValues {
  static const _paddingPercent = 0.15;

  @override
  final double idealMin, idealMax, tolerableMin, tolerableMax;

  TemperatureRange({required double min, required double max})
      : idealMin = min,
        idealMax = max,
        tolerableMin = min - ((max - min) * _paddingPercent),
        tolerableMax = max + ((max - min) * _paddingPercent);
}

/// A type-safe implementation for pH ranges.
class PhRange extends RangeValues {
  static const _paddingAbsolute = 0.4;

  @override
  final double idealMin, idealMax, tolerableMin, tolerableMax;

  PhRange({required double min, required double max})
      : idealMin = min,
        idealMax = max,
        tolerableMin = min - _paddingAbsolute,
        tolerableMax = max + _paddingAbsolute;
}

/// A type-safe implementation for General Hardness (GH) ranges.
class GhRange extends RangeValues {
  static const _paddingPercent = 0.20;

  @override
  final double idealMin, idealMax, tolerableMin, tolerableMax;

  GhRange({required double min, required double max})
      : idealMin = min,
        idealMax = max,
        tolerableMin = math.max(0, min - ((max - min) * _paddingPercent)),
        tolerableMax = max + ((max - min) * _paddingPercent);
}

/// A type-safe implementation for Carbonate Hardness (KH) ranges.
class KhRange extends RangeValues {
  static const _paddingPercent = 0.25;

  @override
  final double idealMin, idealMax, tolerableMin, tolerableMax;

  KhRange({required double min, required double max})
      : idealMin = min,
        idealMax = max,
        tolerableMin = math.max(0, min - ((max - min) * _paddingPercent)),
        tolerableMax = max + ((max - min) * _paddingPercent);
}

/// A type-safe implementation for Total Dissolved Solids (TDS) ranges.
class TdsRange extends RangeValues {
  static const _paddingPercent = 0.25;

  @override
  final double idealMin, idealMax, tolerableMin, tolerableMax;

  TdsRange({required double min, required double max})
      : idealMin = min,
        idealMax = max,
        tolerableMin = math.max(0, min - ((max - min) * _paddingPercent)),
        tolerableMax = max + ((max - min) * _paddingPercent);
}

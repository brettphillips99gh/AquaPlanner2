import 'dart:math' as math;
import 'bioload/bioload.dart';
import 'filter/filter.dart';

export 'bioload/bioload.dart';
export 'filter/filter.dart';

// --- Configuration Enums ---
enum LidType { none, mesh, glass }
enum SurfaceAgitation { none, low, moderate, high }

// --- Data Structures ---

class RangeValues {
  final double min;
  final double max;
  const RangeValues(this.min, this.max);

  bool contains(double value) => value >= min && value <= max;

  RangeValues? intersection(RangeValues other) {
    double newMin = math.max(min, other.min);
    double newMax = math.min(this.max, other.max);
    if (newMin >= newMax) return null; // A single point is not a valid range
    return RangeValues(newMin, newMax);
  }

  @override
  String toString() => '${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)}';
}

class SpeciesDefinition {
  final String id;
  final String name;
  final double maxStandardLengthCm;
  final double averageAdultMassGrams;

  // Biological Properties
  final TrophicLevel trophicLevel;
  final ActivityLevel activityLevel;
  final AggressionType aggressionType;
  final int minShoalSize;

  // Water Parameters (The "Thriving" Zone)
  final RangeValues tempRange; // Celsius
  final RangeValues phRange;
  final RangeValues ghRange; // Degrees (General Hardness)
  final RangeValues khRange; // Degrees (Carbonate Hardness)

  const SpeciesDefinition({
    required this.id,
    required this.name,
    required this.maxStandardLengthCm,
    required this.averageAdultMassGrams,
    required this.trophicLevel,
    required this.activityLevel,
    required this.aggressionType,
    required this.minShoalSize,
    required this.tempRange,
    required this.phRange,
    required this.ghRange,
    required this.khRange,
  });
}

class StockedItem {
  final SpeciesDefinition species;
  final int count;
  final GrowthStage growthStage;
  final double? measuredLengthCm;

  StockedItem({
    required this.species,
    this.count = 1,
    this.growthStage = GrowthStage.adult,
    this.measuredLengthCm,
  });

  double get estimatedTotalMassGrams {
    double individualMass;
    if (growthStage == GrowthStage.adult) {
      individualMass = species.averageAdultMassGrams;
    } else {
      double lengthFactor = (growthStage == GrowthStage.juvenile) ? 0.3 : 0.7;
      individualMass = species.averageAdultMassGrams * math.pow(lengthFactor, 3);
    }
    return individualMass * count;
  }
}

class TankProfile {
  final double volumeLiters;
  final double surfaceAreaSqMeters;

  // Current Water Parameters
  final double tempC;
  final double ph;
  final double gh;
  final double kh;

  // Equipment
  final FilterProfile filter;
  final bool isPlanted;
  final bool hasAirstone;
  final LidType lidType;
  final SurfaceAgitation surfaceAgitation;

  TankProfile({
    required this.volumeLiters,
    required this.surfaceAreaSqMeters,
    required this.tempC,
    required this.ph,
    required this.gh,
    required this.kh,
    required this.filter,
    this.isPlanted = false,
    this.hasAirstone = false,
    this.lidType = LidType.none,
    this.surfaceAgitation = SurfaceAgitation.low,
  });
}

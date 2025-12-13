import 'dart:math' as math;

import 'bioload/bioload.dart';
import 'filter/filter.dart';
import 'ranges.dart';

export 'bioload/bioload.dart';
export 'filter/filter.dart';
export 'ranges.dart';

// --- Configuration Enums ---
enum LidType { none, mesh, glass }
enum SurfaceAgitation { none, low, moderate, high }

// --- DATA STRUCTURES ---

class SpeciesDefinition {
  final String id;
  final String name;
  final double maxStandardLengthCm;
  final double averageAdultMassGrams;

  final TrophicLevel trophicLevel;
  final ActivityLevel activityLevel;
  final AggressionType aggressionType;
  final int minShoalSize;

  // Now the types are distinct, concrete classes.
  final TemperatureRange tempRange;
  final PhRange phRange;
  final GhRange ghRange;
  final KhRange khRange;
  /// The target TDS range for this species in ppm.
  final TdsRange tdsRange;

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
    required this.tdsRange,
  });
}

// ... The rest of the file (StockedItem, TankProfile) remains unchanged ...
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

  final double tempC;
  final double ph;
  final double gh;
  final double kh;

  final FilterProfile filter;
  final bool isPlanted;
  final bool hasAirstone;
  final LidType lidType;
  final SurfaceAgitation surfaceAgitation;

  /// A reference ID to the WaterSourceProfile used for this tank.
  final String waterSourceId;

  TankProfile({
    required this.volumeLiters,
    required this.surfaceAreaSqMeters,
    required this.tempC,
    required this.ph,
    required this.gh,
    required this.kh,
    required this.filter,
    required this.waterSourceId,
    this.isPlanted = false,
    this.hasAirstone = false,
    this.lidType = LidType.none,
    this.surfaceAgitation = SurfaceAgitation.low,
  });
}

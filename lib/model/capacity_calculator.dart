import 'dart:math' as math;
import 'models.dart';

/// Calculates the processing capacity of the tank's filtration system.
class CapacityCalculator {
  // Base nitrification rate: 0.5g TAN per m2 per day (Standard Biofilm)
  static const double _baseNitrificationRatePerSqMeter = 0.5;

  /// Calculates the maximum grams of ammonia the filter can process per day.
  double calculateFilterCapacity(double tankVolumeLiters, double tempC, FilterProfile filter) {
    // Formula: SUM(Media Volume * Portion * Specific Surface Area) * Efficiency Factors

    double totalSurfaceArea = 0;
    for (var slot in filter.mediaSlots) {
      double mediaSSA = _getMediaSSA(slot.mediaType);
      double mediaVolumeForSlot = filter.filterMediaVolumeLiters * slot.portion;
      double filterMediaVolumeM3 = mediaVolumeForSlot / 1000.0;
      totalSurfaceArea += filterMediaVolumeM3 * mediaSSA;
    }

    // Temp Efficiency: Bacteria slow down below 25C
    double tempEfficiency = 1.0;
    if (tempC < 25) {
      // Approx -10% efficiency per degree drop below 25
      tempEfficiency = math.max(0.1, 1.0 - ((25 - tempC) * 0.1));
    }

    // Flow Efficiency: Turnover needs to be sufficient to deliver Oxygen to bacteria
    double turnover = filter.filterFlowRateLph / tankVolumeLiters;
    double flowEfficiency = (turnover >= 4.0) ? 1.0 : (turnover / 4.0);

    // THE SINK EQUATION:
    double maxRemovalCapacityGrams =
        totalSurfaceArea * _baseNitrificationRatePerSqMeter * tempEfficiency * flowEfficiency;

    return maxRemovalCapacityGrams;
  }

  // Returns Specific Surface Area (m2/m3)
  double _getMediaSSA(FilterMediaType type) {
    switch (type) {
      case FilterMediaType.sponge: return 800.0;
      case FilterMediaType.ceramicRings: return 1200.0;
      case FilterMediaType.bioBalls: return 350.0;
      case FilterMediaType.k1Micro: return 900.0;
    }
  }
}

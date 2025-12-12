import 'models.dart';

/// A report containing analysis of the physical tank setup.
class TankConfigurationReport {
  final List<String> warnings;
  final List<String> errors;

  TankConfigurationReport({this.warnings = const [], this.errors = const []});
}

/// Analyzes the physical properties and equipment of a tank.
class TankConfigurationEngine {
  TankConfigurationReport analyze(TankProfile tank) {
    final List<String> warnings = [];

    // --- Filter Flow Rate (Turnover) Check ---
    final double turnoverRate = tank.filter.filterFlowRateLph / tank.volumeLiters;

    if (turnoverRate < 5.0) {
      warnings.add(
          'Low Filter Turnover: The filter provides a turnover rate of ${turnoverRate.toStringAsFixed(1)}x per hour. A rate of 5x to 10x is recommended for most setups to ensure adequate filtration and oxygenation.');
    } else if (turnoverRate > 15.0) {
      warnings.add(
          'High Filter Turnover: The filter provides a turnover rate of ${turnoverRate.toStringAsFixed(1)}x per hour. This may create excessive current for certain species like bettas or long-finned fish.');
    }

    // --- Oxygenation & Gas Exchange Check ---
    bool hasGoodGasExchange = false;
    if (tank.hasAirstone) {
      hasGoodGasExchange = true;
    }
    if (tank.surfaceAgitation == SurfaceAgitation.moderate || tank.surfaceAgitation == SurfaceAgitation.high) {
      hasGoodGasExchange = true;
    }

    if (tank.lidType == LidType.glass && !hasGoodGasExchange) {
      warnings.add(
          'Oxygen Starvation Risk: A glass lid can trap gasses and limit oxygen exchange. With low surface agitation and no airstone, CO₂ can build up and oxygen levels can drop, especially at night. Consider adding an airstone or increasing surface agitation.');
    }

    if (tank.surfaceAgitation == SurfaceAgitation.none && !tank.hasAirstone) {
      warnings.add(
          'Poor Gas Exchange: The water surface is calm and there is no airstone. This can lead to low oxygen levels. Increasing surface agitation via the filter outlet or adding an airstone is highly recommended.');
    }

    return TankConfigurationReport(warnings: warnings);
  }
}

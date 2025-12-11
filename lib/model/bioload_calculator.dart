import 'dart:math' as math;
import 'models.dart';

class SystemHealthSnapshot {
  final double ammoniaStockingPercent; // > 100% means filter failure
  final double oxygenHeadroom; // > 0 is safe
  final double dailyAmmoniaProducedGrams;
  final double dailyAmmoniaProcessedGrams;
  final List<String> warnings;

  SystemHealthSnapshot({
    required this.ammoniaStockingPercent,
    required this.oxygenHeadroom,
    required this.dailyAmmoniaProducedGrams,
    required this.dailyAmmoniaProcessedGrams,
    required this.warnings,
  });
}

class BioloadCalculator {

  // --- Constants based on Aquaculture Engineering (Timmons & Ebeling) ---
  // Base nitrification rate: 0.5g TAN per m2 per day (Standard Biofilm)
  static const double _baseNitrificationRatePerSqMeter = 0.5;

  // Feed Rate: 1.5% of body weight per day (Standard Tropicals)
  static const double _dailyFeedRatePercent = 0.015;

  // Protein Chemistry: Protein is ~16% Nitrogen
  static const double _nitrogenInProtein = 0.16;

  // Excretion: ~80% of ingested Nitrogen becomes Total Ammonia Nitrogen (TAN)
  static const double _excretionRate = 0.80;

  SystemHealthSnapshot calculate(TankProfile tank, List<StockedItem> stock) {
    List<String> warnings = [];

    // --- STEP 1: CALCULATE THE INPUT (The Source) ---
    // Formula: Mass -> Feed -> Protein -> Nitrogen -> Ammonia

    double totalFeedGrams = 0.0;
    double metabolicLoadSum = 0.0; // Used for Oxygen calc

    for (var item in stock) {
      double batchMass = item.estimatedTotalMassGrams;

      // Activity Modifier (Active fish burn more energy/oxygen)
      double activityMod = 1.0;
      if (item.species.activityLevel == ActivityLevel.hyper) activityMod = 1.5;
      if (item.species.activityLevel == ActivityLevel.sedentary) activityMod = 0.7;

      // Feed Calculation
      totalFeedGrams += (batchMass * _dailyFeedRatePercent * activityMod);
      metabolicLoadSum += (batchMass * activityMod);
    }

    // Diet Modifier: Carnivores eat higher protein (50%+) vs Omnivores (40%)
    bool hasCarnivores = stock.any((i) => i.species.trophicLevel == TrophicLevel.carnivore);
    double averageProteinPct = hasCarnivores ? 0.50 : 0.40;

    // THE SOURCE EQUATION:
    double dailyAmmoniaGrams = totalFeedGrams * averageProteinPct * _nitrogenInProtein * _excretionRate;


    // --- STEP 2: CALCULATE THE OUTPUT (The Sink) ---
    // Formula: Media Volume * Specific Surface Area * Efficiency Factors

    double mediaSSA = _getMediaSSA(tank.mediaType);

    // FIX: Convert Liters to m3 (1000L = 1m3) before SSA calculation
    double filterMediaVolumeM3 = tank.filterMediaVolumeLiters / 1000.0;
    double totalSurfaceArea = filterMediaVolumeM3 * mediaSSA;

    // Temp Efficiency: Bacteria slow down below 25C
    double tempEfficiency = 1.0;
    if (tank.tempC < 25) {
      // Approx -10% efficiency per degree drop below 25
      tempEfficiency = math.max(0.1, 1.0 - ((25 - tank.tempC) * 0.1));
    }

    // Flow Efficiency: Turnover needs to be sufficient to deliver Oxygen to bacteria
    double turnover = tank.filterFlowRateLph / tank.volumeLiters;
    double flowEfficiency = (turnover >= 4.0) ? 1.0 : (turnover / 4.0);

    // THE SINK EQUATION:
    double maxRemovalCapacityGrams = totalSurfaceArea * _baseNitrificationRatePerSqMeter * tempEfficiency * flowEfficiency;


    // --- STEP 3: OXYGEN BUDGET ---
    // Simple heuristic model for O2

    // Supply: Surface Area (Gas Exchange)
    double oxygenSupplyIndex = tank.surfaceAreaSqMeters * 1000;
    if (tank.isPlanted) oxygenSupplyIndex *= 1.1; // Slight boost

    // Demand: Fish Mass + Bacterial Demand (Bacteria consume O2 to process Ammonia)
    double bacterialDemand = dailyAmmoniaGrams * 4.57; // Stoichiometry: 4.57g O2 per 1g Ammonia
    double fishDemand = metabolicLoadSum * 0.5; // Arbitrary metabolic constant
    double totalDemand = bacterialDemand + fishDemand;

    // Temp Penalty for O2 Solubility (Water holds less O2 as it gets hotter)
    double solubilityFactor = 1.0 - ((tank.tempC - 20) * 0.015);
    double oxygenHeadroom = (oxygenSupplyIndex * solubilityFactor) - totalDemand;


    // --- STEP 4: GENERATE REPORT ---
    double stockingPercent = (maxRemovalCapacityGrams > 0)
        ? (dailyAmmoniaGrams / maxRemovalCapacityGrams)
        : 999.0; // Divide by zero protection

    if (stockingPercent > 1.0) {
      warnings.add("CRITICAL: Bio-load (${dailyAmmoniaGrams.toStringAsFixed(2)}g/day) exceeds filter capacity.");
    } else if (stockingPercent > 0.85) {
      warnings.add("WARNING: Filter is running at ${(stockingPercent * 100).toStringAsFixed(0)}% capacity.");
    }

    if (oxygenHeadroom < 0) {
      warnings.add("DANGER: Oxygen demand exceeds supply. Risk of hypoxia at night.");
    }

    if (turnover < 3.0) {
      warnings.add("Flow Rate Low: ${turnover.toStringAsFixed(1)}x turnover. Aim for 4x-6x.");
    }

    return SystemHealthSnapshot(
      ammoniaStockingPercent: stockingPercent * 100,
      oxygenHeadroom: oxygenHeadroom,
      dailyAmmoniaProducedGrams: dailyAmmoniaGrams,
      dailyAmmoniaProcessedGrams: maxRemovalCapacityGrams,
      warnings: warnings,
    );
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
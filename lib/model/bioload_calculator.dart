import 'models.dart';
import 'capacity_calculator.dart';

class BioloadCalculator {
  // Feed Rate: 1.5% of body weight per day (Standard Tropicals)
  static const double _dailyFeedRatePercent = 0.015;

  // Protein Chemistry: Protein is ~16% Nitrogen
  static const double _nitrogenInProtein = 0.16;

  // Excretion: ~80% of ingested Nitrogen becomes Total Ammonia Nitrogen (TAN)
  static const double _excretionRate = 0.80;

  final CapacityCalculator _capacityCalculator;

  BioloadCalculator({CapacityCalculator? capacityCalculator})
      : _capacityCalculator = capacityCalculator ?? CapacityCalculator();

  SystemHealthSnapshot calculate(TankProfile tank, List<StockedItem> stock) {
    List<String> warnings = [];

    // --- STEP 1: CALCULATE THE INPUT (The Source) ---
    double dailyAmmoniaGrams = _calculateAmmoniaProduction(stock);
    double metabolicLoadSum = _calculateMetabolicLoad(stock);

    // --- STEP 2: CALCULATE THE OUTPUT (The Sink) ---
    double maxRemovalCapacityGrams = _capacityCalculator.calculateFilterCapacity(
      tank.volumeLiters, 
      tank.tempC, 
      tank.filter
    );

    // --- STEP 3: OXYGEN BUDGET ---
    double oxygenHeadroom = _calculateOxygenBudget(tank, dailyAmmoniaGrams, metabolicLoadSum);

    // --- STEP 4: GENERATE REPORT ---
    double stockingPercent = (maxRemovalCapacityGrams > 0)
        ? (dailyAmmoniaGrams / maxRemovalCapacityGrams)
        : 999.0; // Divide by zero protection

    if (stockingPercent > 1.0) {
      warnings.add(
          "CRITICAL: Bio-load (${dailyAmmoniaGrams.toStringAsFixed(2)}g/day) exceeds filter capacity.");
    } else if (stockingPercent > 0.85) {
      warnings.add(
          "WARNING: Filter is running at ${(stockingPercent * 100).toStringAsFixed(0)}% capacity.");
    }

    if (oxygenHeadroom < 0) {
      warnings.add("DANGER: Oxygen demand exceeds supply. Risk of hypoxia at night.");
    }

    double turnover = tank.filter.filterFlowRateLph / tank.volumeLiters;
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

  double _calculateAmmoniaProduction(List<StockedItem> stock) {
    double totalFeedGrams = 0.0;
    for (var item in stock) {
      double batchMass = item.estimatedTotalMassGrams;
      double activityMod = _getActivityModifier(item.species.activityLevel);
      totalFeedGrams += (batchMass * _dailyFeedRatePercent * activityMod);
    }

    bool hasCarnivores = stock.any((i) => i.species.trophicLevel == TrophicLevel.carnivore);
    double averageProteinPct = hasCarnivores ? 0.50 : 0.40;

    return totalFeedGrams * averageProteinPct * _nitrogenInProtein * _excretionRate;
  }

  double _calculateMetabolicLoad(List<StockedItem> stock) {
    double metabolicLoadSum = 0.0;
    for (var item in stock) {
      double activityMod = _getActivityModifier(item.species.activityLevel);
      metabolicLoadSum += (item.estimatedTotalMassGrams * activityMod);
    }
    return metabolicLoadSum;
  }

  double _calculateOxygenBudget(
      TankProfile tank, double dailyAmmoniaGrams, double metabolicLoadSum) {
    // Supply: Surface Area (Gas Exchange)
    double oxygenSupplyIndex = tank.surfaceAreaSqMeters * 1000;
    if (tank.isPlanted) oxygenSupplyIndex *= 1.1; // Slight boost

    // Demand: Fish Mass + Bacterial Demand
    double bacterialDemand = dailyAmmoniaGrams * 4.57; // Stoichiometry
    double fishDemand = metabolicLoadSum * 0.5; // Arbitrary metabolic constant
    double totalDemand = bacterialDemand + fishDemand;

    // Temp Penalty for O2 Solubility
    double solubilityFactor = 1.0 - ((tank.tempC - 20) * 0.015);
    return (oxygenSupplyIndex * solubilityFactor) - totalDemand;
  }

  double _getActivityModifier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.hyper: return 1.5;
      case ActivityLevel.sedentary: return 0.7;
      default: return 1.0;
    }
  }
}

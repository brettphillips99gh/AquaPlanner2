import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_planner_2/model/models.dart';
import 'package:aqua_planner_2/model/bioload_calculator.dart';
import 'package:aqua_planner_2/model/compatibility_engine.dart';

void main() {
  // --- MOCK DATA SETUP ---

  // 1. The "Canary in the Coal Mine" (Sensitive Nano Fish)
  final neonTetra = SpeciesDefinition(
      id: 'neon', name: 'Neon Tetra',
      maxStandardLengthCm: 3.5, averageAdultMassGrams: 2.0,
      trophicLevel: TrophicLevel.omnivore, activityLevel: ActivityLevel.active,
      aggressionType: AggressionType.peaceful, minShoalSize: 6,
      tempRange: RangeValues(22, 28), phRange: RangeValues(6.0, 7.5),
      ghRange: RangeValues(2, 10), khRange: RangeValues(0, 5)
  );

  // 2. The "Tank Buster" (Messy, Cold Water Fish)
  final goldfish = SpeciesDefinition(
      id: 'goldfish', name: 'Comet Goldfish',
      maxStandardLengthCm: 25.0, averageAdultMassGrams: 150.0, // Heavy!
      trophicLevel: TrophicLevel.omnivore, activityLevel: ActivityLevel.active,
      aggressionType: AggressionType.semiAggressive, minShoalSize: 1,
      tempRange: RangeValues(10, 22), // Cold water only
      phRange: RangeValues(7.0, 8.0),
      ghRange: RangeValues(10, 20), khRange: RangeValues(5, 15)
  );

  // 3. The "Predator"
  final oscar = SpeciesDefinition(
      id: 'oscar', name: 'Oscar Cichlid',
      maxStandardLengthCm: 35.0, averageAdultMassGrams: 1100.0,
      trophicLevel: TrophicLevel.carnivore, activityLevel: ActivityLevel.sedentary,
      aggressionType: AggressionType.predatory, minShoalSize: 1,
      tempRange: RangeValues(22, 28), phRange: RangeValues(6.0, 8.0),
      ghRange: RangeValues(5, 20), khRange: RangeValues(2, 15)
  );

  final calc = BioloadCalculator();
  final linter = CompatibilityEngine();

  // --- TEST GROUPS ---

  group('Physics Engine Stress Tests', () {

    test('Scenario: "The Goldfish Paradox" (High Mass vs Small Filter)', () {
      // Setup: User puts a big Goldfish in a 10 Gallon (38L) tank with a small sponge filter
      final smallTank = TankProfile(
          volumeLiters: 38, surfaceAreaSqMeters: 0.1,
          tempC: 20, ph: 7.5, gh: 12, kh: 6,
          filterFlowRateLph: 200, // Weak flow
          filterMediaVolumeLiters: 0.5,
          mediaType: FilterMediaType.sponge // Low efficiency
      );

      final stock = [StockedItem(species: goldfish, count: 1)];

      final snapshot = calc.calculate(smallTank, stock);

      // Expectation: The filter cannot handle 150g of fish waste
      expect(snapshot.ammoniaStockingPercent, greaterThan(100.0),
          reason: "Stocking should exceed 100% capacity");
      expect(snapshot.warnings, contains(contains("Bio-load")),
          reason: "Should warn about Bio-load capacity");
    });

    test('Scenario: "The Hypoxia Crash" (Heatwave + Overstocking)', () {
      // Setup: Good filter, but water is 30°C (86°F) and overstocked
      final hotTank = TankProfile(
          volumeLiters: 200, surfaceAreaSqMeters: 0.5,
          tempC: 30.0, // HOT water holds less Oxygen
          ph: 7.0, gh: 5, kh: 3,
          filterFlowRateLph: 1000,
          filterMediaVolumeLiters: 2.0,
          mediaType: FilterMediaType.ceramicRings
      );

      // Heavy stocking of active fish consumes massive O2
      final stock = [StockedItem(species: oscar, count: 2)];

      final snapshot = calc.calculate(hotTank, stock);

      // Expectation: Filter handles Ammonia, but Oxygen runs out
      expect(snapshot.oxygenHeadroom, lessThan(0),
          reason: "Oxygen headroom should be negative in hot, overstocked water");
      expect(snapshot.warnings, contains(contains("Hypoxia")),
          reason: "Should trigger Hypoxia warning");
    });
  });

  group('Compatibility Engine Tests', () {

    test('Scenario: "Temperature Shock" (Tropical vs Coldwater)', () {
      // User tries to mix Neon Tetra (Tropical) and Goldfish (Cold)
      // Tank is set to Tropical (25C)
      final tropicalTank = TankProfile(
          volumeLiters: 200, surfaceAreaSqMeters: 0.5,
          tempC: 25.0, ph: 7.0, gh: 6, kh: 4,
          filterFlowRateLph: 1000, filterMediaVolumeLiters: 1.0, mediaType: FilterMediaType.sponge
      );

      final stock = [
        StockedItem(species: neonTetra, count: 10),
        StockedItem(species: goldfish, count: 1)
      ];

      final report = linter.validate(tropicalTank, stock);

      // Expectation: Species ranges do not overlap -> Fatal Error
      expect(report.isCompatible, isFalse, reason: "Tropical and Coldwater fish cannot coexist");
      expect(report.errors.toString(), contains("Temp Mismatch"),
          reason: "Should flag specific Temp Mismatch error");
    });

    test('Scenario: "The Buffet" (Predator vs Prey)', () {
      // User puts Oscar (Predator) with Neon Tetras (Snack)
      final bigTank = TankProfile(
          volumeLiters: 400, surfaceAreaSqMeters: 1.0,
          tempC: 26.0, ph: 7.0, gh: 10, kh: 5,
          filterFlowRateLph: 2000, filterMediaVolumeLiters: 5.0, mediaType: FilterMediaType.ceramicRings
      );

      final stock = [
        StockedItem(species: oscar, count: 1),
        StockedItem(species: neonTetra, count: 10)
      ];

      final report = linter.validate(bigTank, stock);

      // Expectation: Predation Error
      expect(report.errors.toString(), contains("PREDATION RISK"),
          reason: "Should detect that Oscar eats Neons");
    });

    test('Scenario: "Social Stress" (Shoal too small)', () {
      final tank = TankProfile(
          volumeLiters: 100, surfaceAreaSqMeters: 0.3,
          tempC: 24, ph: 7, gh: 5, kh: 3,
          filterFlowRateLph: 500, filterMediaVolumeLiters: 1, mediaType: FilterMediaType.sponge
      );

      // Neon Tetras need 6+, we only add 2
      final stock = [StockedItem(species: neonTetra, count: 2)];

      final report = linter.validate(tank, stock);

      // Expectation: Warning (not Error) about shoaling
      expect(report.warnings.toString(), contains("needs group of"),
          reason: "Should warn about minimum shoal size");
    });
  });
}

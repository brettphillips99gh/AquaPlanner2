import 'package:test/test.dart';
import 'package:aqua_planner_2/model/models.dart';
import 'package:aqua_planner_2/model/user_profile.dart';import 'package:aqua_planner_2/model/bioload_calculator.dart';
import 'package:aqua_planner_2/model/compatibility_engine.dart';
import 'package:aqua_planner_2/model/filter/filter.dart';

void main() {
  // --- MOCK DATA SETUP ---
  // This section defines the standardized "actors" for our tests.

  // A small, peaceful, schooling fish sensitive to water parameters.
  final neonTetra = SpeciesDefinition(
      id: 'neon',
      name: 'Neon Tetra',
      maxStandardLengthCm: 3.5,
      averageAdultMassGrams: 2.0,
      trophicLevel: TrophicLevel.omnivore,
      activityLevel: ActivityLevel.active,
      aggressionType: AggressionType.peaceful,
      minShoalSize: 6,
      tempRange: TemperatureRange(min: 22, max: 28),
      phRange: PhRange(min: 6.0, max: 7.5),
      ghRange: GhRange(min: 2, max: 10),
      khRange: KhRange(min: 0, max: 5),
      tdsRange: TdsRange(min: 50, max: 150));

  // A large, messy, cold-water fish with a high bioload.
  final goldfish = SpeciesDefinition(
      id: 'goldfish',
      name: 'Comet Goldfish',
      maxStandardLengthCm: 25.0,
      averageAdultMassGrams: 150.0,
      trophicLevel: TrophicLevel.omnivore,
      activityLevel: ActivityLevel.active,
      aggressionType: AggressionType.semiAggressive,
      minShoalSize: 1,
      tempRange: TemperatureRange(min: 10, max: 22),
      phRange: PhRange(min: 7.0, max: 8.0),
      ghRange: GhRange(min: 10, max: 20),
      khRange: KhRange(min: 5, max: 15),
      tdsRange: TdsRange(min: 200, max: 400));

  // A very large predatory fish with a huge bioload, used for stress testing.
  final oscar = SpeciesDefinition(
      id: 'oscar',
      name: 'Oscar Cichlid',
      maxStandardLengthCm: 35.0,
      averageAdultMassGrams: 1100.0,
      trophicLevel: TrophicLevel.carnivore,
      activityLevel: ActivityLevel.sedentary,
      aggressionType: AggressionType.predatory,
      minShoalSize: 1,
      tempRange: TemperatureRange(min: 22, max: 28),
      phRange: PhRange(min: 6.0, max: 8.0),
      ghRange: GhRange(min: 5, max: 20),
      khRange: KhRange(min: 2, max: 15),
      tdsRange: TdsRange(min: 100, max: 350));

  // A standard water source for many tests.
  final standardWaterSource = WaterSourceProfile(
      id: 'ws-1',
      name: 'Standard Tap',
      ph: 7.2,
      gh: 8,
      kh: 4,
      tds: 180);

  // Instantiate the engines once for all tests.
  final calc = BioloadCalculator();
  final linter = CompatibilityEngine();

  // --- MODEL VALIDATION TESTS ---
  group('RangeValues Model Integrity', () {
    test('TemperatureRange calculates correct percentage-based padding', () {
      final range = TemperatureRange(min: 20, max: 30); // 10 degree range
      expect(range.tolerableMin, closeTo(18.5, 0.01));
      expect(range.tolerableMax, closeTo(31.5, 0.01));
    });

    test('PhRange calculates correct absolute-based padding', () {
      final range = PhRange(min: 6.5, max: 7.5);
      expect(range.tolerableMin, closeTo(6.1, 0.01));
      expect(range.tolerableMax, closeTo(7.9, 0.01));
    });

    test('GhRange respects the zero boundary', () {
      final lowRange = GhRange(min: 0.1, max: 0.2);
      expect(lowRange.tolerableMin, closeTo(0.08, 0.001));

      final veryLowRange = GhRange(min: 0.1, max: 1.1);
      expect(veryLowRange.tolerableMin, 0);
    });

    test('Intersection returns null for non-overlapping ranges', () {
      final rangeA = TemperatureRange(min: 20, max: 22);
      final rangeB = TemperatureRange(min: 25, max: 28);
      final intersection = rangeA.intersection(rangeB);
      expect(intersection, isNull);
    });
  });

  // --- ENGINE EDGE CASE TESTS ---
  group('Engine Edge Cases', () {
    test('BioloadCalculator returns zero-state for empty stock list', () {
      final emptyStockTank = TankProfile(
          volumeLiters: 100,
          surfaceAreaSqMeters: 0.3,
          tempC: 25,
          ph: 7,
          gh: 5,
          kh: 3,
          waterSourceId: 'ws-1',
          filter:
          const FilterProfile(filterFlowRateLph: 500, filterMediaVolumeLiters: 1));
      final snapshot = calc.calculate(emptyStockTank, []);
      expect(snapshot.ammoniaStockingPercent, 0);
    });

    test('BioloadCalculator handles zero filter capacity', () {
      final tankWithNoFilter = TankProfile(
          volumeLiters: 100,
          surfaceAreaSqMeters: 0.3,
          tempC: 25,
          ph: 7,
          gh: 5,
          kh: 3,
          waterSourceId: 'ws-1',
          filter:
          const FilterProfile(filterFlowRateLph: 0, filterMediaVolumeLiters: 0));
      final stock = [StockedItem(species: neonTetra, count: 5)];
      final snapshot = calc.calculate(tankWithNoFilter, stock);
      expect(snapshot.ammoniaStockingPercent, greaterThan(998));
    });

    test('CompatibilityEngine returns valid report for empty stock list',
            () {
          final emptyStockTank = TankProfile(
              volumeLiters: 100,
              surfaceAreaSqMeters: 0.3,
              tempC: 25,
              ph: 7,
              gh: 5,
              kh: 3,
              waterSourceId: 'ws-1',
              filter:
              const FilterProfile(filterFlowRateLph: 500, filterMediaVolumeLiters: 1));
          final report = linter.validate(emptyStockTank, [], [standardWaterSource]);
          expect(report.isCompatible, isTrue);
          expect(report.errors, isEmpty);
          expect(report.warnings, isEmpty);
        });

    test(
        'CompatibilityEngine returns error if waterSourceId is not found',
            () {
          final tankWithBadId = TankProfile(
              volumeLiters: 100,
              surfaceAreaSqMeters: 0.3,
              tempC: 25,
              ph: 7,
              gh: 5,
              kh: 3,
              waterSourceId: 'bad-id', // This ID does not exist in the provided list
              filter:
              const FilterProfile(filterFlowRateLph: 500, filterMediaVolumeLiters: 1));
          final report = linter.validate(tankWithBadId, [], [standardWaterSource]);
          expect(report.isCompatible, isFalse);
          expect(report.errors, contains(contains('could not be found')));
        });
  });

  // --- FULL SCENARIO STRESS TESTS ---
  group('Full Scenario Stress Tests', () {
    test('Scenario: "The Goldfish Paradox" (High Mass vs Small Filter)', () {
      final smallTank = TankProfile(
        volumeLiters: 38,
        surfaceAreaSqMeters: 0.1,
        tempC: 20,
        ph: 7.5,
        gh: 12,
        kh: 6,
        waterSourceId: 'ws-1',
        filter: const FilterProfile(
          filterFlowRateLph: 200,
          filterMediaVolumeLiters: 0.5,
          mediaSlots: [
            FilterMediaSlot(mediaType: FilterMediaType.sponge, portion: 1.0)
          ],
        ),
      );
      final stock = [StockedItem(species: goldfish, count: 1)];
      final snapshot = calc.calculate(smallTank, stock);
      expect(snapshot.ammoniaStockingPercent, greaterThan(100.0));
      expect(snapshot.warnings, contains(contains("Bio-load")));
    });

    test('Scenario: "The Hypoxia Crash" (Heatwave + Overstocking)', () {
      final hotTank = TankProfile(
        volumeLiters: 200,
        surfaceAreaSqMeters: 0.5,
        tempC: 30.0,
        ph: 7.0,
        gh: 5,
        kh: 3,
        waterSourceId: 'ws-1',
        filter: const FilterProfile(
          filterFlowRateLph: 1000,
          filterMediaVolumeLiters: 2.0,
          mediaSlots: [
            FilterMediaSlot(
                mediaType: FilterMediaType.ceramicRings, portion: 1.0)
          ],
        ),
      );
      final stock = [StockedItem(species: oscar, count: 2)];
      final snapshot = calc.calculate(hotTank, stock);
      expect(snapshot.oxygenHeadroom, lessThan(0));
      expect(snapshot.warnings, contains(contains("hypoxia")));
    });

    test('Scenario: "Temperature Shock" (Tropical vs Coldwater)', () {
      final tropicalTank = TankProfile(
        volumeLiters: 200,
        surfaceAreaSqMeters: 0.5,
        tempC: 25.0,
        ph: 7.0,
        gh: 6,
        kh: 4,
        waterSourceId: 'ws-1',
        filter: const FilterProfile(
          filterFlowRateLph: 1000,
          filterMediaVolumeLiters: 1.0,
          mediaSlots: [
            FilterMediaSlot(mediaType: FilterMediaType.sponge, portion: 1.0)
          ],
        ),
      );
      final stock = [
        StockedItem(species: neonTetra, count: 10),
        StockedItem(species: goldfish, count: 1)
      ];
      final report = linter.validate(tropicalTank, stock, [standardWaterSource]);
      expect(report.isCompatible, isFalse);
      expect(report.errors.toString(), contains("Temp Mismatch"));
    });

    test('Scenario: "The Buffet" (Predator vs Prey)', () {
      final bigTank = TankProfile(
        volumeLiters: 400,
        surfaceAreaSqMeters: 1.0,
        tempC: 26.0,
        ph: 7.0,
        gh: 10,
        kh: 5,
        waterSourceId: 'ws-1',
        filter: const FilterProfile(
          filterFlowRateLph: 2000,
          filterMediaVolumeLiters: 5.0,
          mediaSlots: [
            FilterMediaSlot(
                mediaType: FilterMediaType.ceramicRings, portion: 1.0)
          ],
        ),
      );
      final stock = [
        StockedItem(species: oscar, count: 1),
        StockedItem(species: neonTetra, count: 10)
      ];
      final report = linter.validate(bigTank, stock, [standardWaterSource]);
      expect(report.errors.toString(), contains("PREDATION RISK"));
    });

    test('Scenario: "Social Stress" (Shoal too small)', () {
      final tank = TankProfile(
        volumeLiters: 100,
        surfaceAreaSqMeters: 0.3,
        tempC: 24,
        ph: 7,
        gh: 5,
        kh: 3,
        waterSourceId: 'ws-1',
        filter: const FilterProfile(
          filterFlowRateLph: 500,
          filterMediaVolumeLiters: 1,
          mediaSlots: [
            FilterMediaSlot(mediaType: FilterMediaType.sponge, portion: 1.0)
          ],
        ),
      );
      final stock = [StockedItem(species: neonTetra, count: 2)];
      final report = linter.validate(tank, stock, [standardWaterSource]);
      expect(report.warnings.toString(), contains("needs group of"));
    });
  });
}

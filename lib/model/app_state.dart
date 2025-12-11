import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'bioload_calculator.dart';
import 'compatibility_engine.dart';

// 1. Define the State
class AppState {
  final SystemHealthSnapshot? health;
  final CompatibilityReport? compatibility;
  final bool analysisRun;

  AppState({
    this.health,
    this.compatibility,
    this.analysisRun = false,
  });

  AppState copyWith({
    SystemHealthSnapshot? health,
    CompatibilityReport? compatibility,
    bool? analysisRun,
  }) {
    return AppState(
      health: health ?? this.health,
      compatibility: compatibility ?? this.compatibility,
      analysisRun: analysisRun ?? this.analysisRun,
    );
  }
}

// 2. Define the Notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  final _bioloadCalculator = BioloadCalculator();
  final _compatibilityEngine = CompatibilityEngine();

  void runAnalysis() {
    // Mock data for demonstration
    final neonTetra = SpeciesDefinition(
        id: 'neon', name: 'Neon Tetra',
        maxStandardLengthCm: 3.5, averageAdultMassGrams: 2.0,
        trophicLevel: TrophicLevel.omnivore, activityLevel: ActivityLevel.active,
        aggressionType: AggressionType.peaceful, minShoalSize: 6,
        tempRange: RangeValues(21, 27), phRange: RangeValues(6.0, 7.5),
        ghRange: RangeValues(2, 10), khRange: RangeValues(0, 5)
    );

    final angelfish = SpeciesDefinition(
        id: 'angel', name: 'Angelfish',
        maxStandardLengthCm: 15.0, averageAdultMassGrams: 40.0,
        trophicLevel: TrophicLevel.carnivore, activityLevel: ActivityLevel.sedentary,
        aggressionType: AggressionType.semiAggressive, minShoalSize: 1,
        tempRange: RangeValues(24, 30), phRange: RangeValues(6.0, 7.5),
        ghRange: RangeValues(3, 12), khRange: RangeValues(0, 8)
    );

    final myTank = TankProfile(
        volumeLiters: 200,
        surfaceAreaSqMeters: 0.5,
        tempC: 25.0, ph: 6.8, gh: 6.0, kh: 3.0,
        filterFlowRateLph: 800,
        filterMediaVolumeLiters: 1.5,
        mediaType: FilterMediaType.ceramicRings,
        isPlanted: true
    );

    final myStock = [
      StockedItem(species: neonTetra, count: 15, growthStage: GrowthStage.adult),
      StockedItem(species: angelfish, count: 2, growthStage: GrowthStage.subAdult),
    ];

    final health = _bioloadCalculator.calculate(myTank, myStock);
    final compat = _compatibilityEngine.validate(myTank, myStock);

    state = state.copyWith(health: health, compatibility: compat, analysisRun: true);
  }
}

// 3. Define the Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

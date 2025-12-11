import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/bioload_calculator.dart';
import '../model/compatibility_engine.dart';
import '../model/models.dart';
import 'tank_providers.dart';

// 1. A simple class to hold the combined results of our simulation.
class LocalSimulationResult {
  final SystemHealthSnapshot health;
  final CompatibilityReport compatibility;

  LocalSimulationResult(this.health, this.compatibility);
}

// 2. The core provider that performs the calculation.
final simulationResultProvider = Provider<LocalSimulationResult>((ref) {
  // Watch the input providers. When they change, this provider will re-run.
  final tank = ref.watch(tankProfileProvider);
  final stock = ref.watch(stockListProvider);

  // Instantiate the calculation engines.
  final bioloadCalculator = BioloadCalculator();
  final compatibilityEngine = CompatibilityEngine();

  // Perform the calculations.
  final healthResult = bioloadCalculator.calculate(tank, stock);
  final compatibilityResult = compatibilityEngine.validate(tank, stock);

  // Return the combined result.
  return LocalSimulationResult(healthResult, compatibilityResult);
});

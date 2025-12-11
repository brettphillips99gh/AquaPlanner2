import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/tank_providers.dart';
import '../model/models.dart' as model;

class SimulationView extends ConsumerWidget {
  const SimulationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulationResult = ref.watch(simulationResultProvider);
    final stock = ref.watch(stockListProvider);
    final stockNotifier = ref.read(stockListProvider.notifier);

    // Mock data for a species to add. In a real app, this would come from a database.
    final neonTetra = model.SpeciesDefinition(
        id: 'neon',
        name: 'Neon Tetra',
        maxStandardLengthCm: 3.5,
        averageAdultMassGrams: 2.0,
        trophicLevel: model.TrophicLevel.omnivore,
        activityLevel: model.ActivityLevel.active,
        aggressionType: model.AggressionType.peaceful,
        minShoalSize: 6,
        tempRange: const model.RangeValues(22, 28),
        phRange: const model.RangeValues(6.0, 7.5),
        ghRange: const model.RangeValues(2, 10),
        khRange: const model.RangeValues(0, 5));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Aquarium Simulation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Input Panel ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Input Controls', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => stockNotifier.addSpecies(neonTetra),
                        child: const Text('Add 1 Neon Tetra'),
                      ),
                      ElevatedButton(
                        onPressed: () => stockNotifier.clear(),
                        child: const Text('Clear Stock'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Current Stock Display ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Stock', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      if (stock.isEmpty)
                        const Text('No fish in the tank yet.')
                      else
                        ...stock.map((item) => Text('${item.count}x ${item.species.name}', style: Theme.of(context).textTheme.bodyLarge)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Output Panel ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Simulation Results', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      Text('Stocking Level: ${simulationResult.health.ammoniaStockingPercent.toStringAsFixed(1)}%'),
                      Text('Oxygen Headroom: ${simulationResult.health.oxygenHeadroom.toStringAsFixed(1)}'),
                      const Divider(height: 32),
                      if (simulationResult.compatibility.errors.isNotEmpty)
                        ...simulationResult.compatibility.errors.map((e) => Text('ERROR: $e', style: const TextStyle(color: Colors.red)))
                      else if (simulationResult.compatibility.warnings.isNotEmpty)
                        ...simulationResult.compatibility.warnings.map((w) => Text('WARN: $w', style: const TextStyle(color: Colors.orange)))
                      else
                        const Text('All species are compatible.', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

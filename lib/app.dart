import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model/app_state.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Aqua Planner'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (appState.analysisRun)
                _buildResults(context, appState)
              else
                const Center(child: Text('Tap the button to analyze your tank setup.')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(appStateProvider.notifier).runAnalysis(),
        tooltip: 'Run Analysis',
        child: const Icon(Icons.science_outlined),
      ),
    );
  }

  Widget _buildResults(BuildContext context, AppState appState) {
    final textTheme = Theme.of(context).textTheme;
    final health = appState.health!;
    final compat = appState.compatibility!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aquarium Analysis', style: textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text('Stocking Level: ${health.ammoniaStockingPercent.toStringAsFixed(1)}%', style: textTheme.bodyLarge),
        Text('Ammonia Input:  ${health.dailyAmmoniaProducedGrams.toStringAsFixed(3)}g / day', style: textTheme.bodyLarge),
        Text('Filter Capacity: ${health.dailyAmmoniaProcessedGrams.toStringAsFixed(3)}g / day', style: textTheme.bodyLarge),
        Text('Oxygen Status:  ${health.oxygenHeadroom > 0 ? "Good" : "Hypoxia Risk"}', style: textTheme.bodyLarge),
        const SizedBox(height: 24),
        if (compat.errors.isNotEmpty)
          _buildSection('Critical Errors', compat.errors, Colors.red, textTheme),
        if (health.warnings.isNotEmpty || compat.warnings.isNotEmpty)
          _buildSection('Warnings', [...health.warnings, ...compat.warnings], Colors.orange, textTheme),
        if (compat.isCompatible)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('[OK] Species are compatible.', style: textTheme.headlineMedium?.copyWith(color: Colors.green)),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, Color color, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.headlineSmall?.copyWith(color: color)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text('• $item', style: textTheme.bodyLarge),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

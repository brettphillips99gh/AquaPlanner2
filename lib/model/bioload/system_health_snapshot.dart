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
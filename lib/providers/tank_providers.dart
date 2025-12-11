import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/models.dart' as model;

// A default tank setup to start with.
final tankProfileProvider = StateProvider<model.TankProfile>((ref) {
  return model.TankProfile(
      volumeLiters: 100,
      surfaceAreaSqMeters: 0.3,
      tempC: 25.0,
      ph: 7.0,
      gh: 5.0,
      kh: 3.0,
      filterFlowRateLph: 500,
      filterMediaVolumeLiters: 1.0,
      mediaType: model.FilterMediaType.sponge,
      isPlanted: false
  );
});

// 1. The Notifier class to manage the list of stocked items.
class StockNotifier extends StateNotifier<List<model.StockedItem>> {
  StockNotifier() : super([]);

  // Method to add a species to the stock.
  // It handles incrementing the count if the species already exists.
  void addSpecies(model.SpeciesDefinition species, {int quantity = 1}) {
    final List<model.StockedItem> currentStock = state;
    // Check if the species is already in the stock.
    final int existingIndex = currentStock.indexWhere((item) => item.species.id == species.id);

    if (existingIndex != -1) {
      // If it exists, create a new item with an incremented count.
      final existingItem = currentStock[existingIndex];
      final updatedItem = model.StockedItem(
          species: existingItem.species,
          count: existingItem.count + quantity,
          growthStage: existingItem.growthStage
      );
      // Create a new list with the updated item.
      final List<model.StockedItem> updatedStock = List.from(currentStock);
      updatedStock[existingIndex] = updatedItem;
      state = updatedStock;
    } else {
      // If it doesn't exist, add a new StockedItem to the list.
      state = [...state, model.StockedItem(species: species, count: quantity)];
    }
  }

  void clear() {
    state = [];
  }
}

// 2. The provider is now a StateNotifierProvider.
final stockListProvider = StateNotifierProvider<StockNotifier, List<model.StockedItem>>((ref) {
  return StockNotifier();
});

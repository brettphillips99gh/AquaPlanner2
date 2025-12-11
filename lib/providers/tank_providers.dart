import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/models.dart';

// A default tank setup to start with.
final tankProfileProvider = StateProvider<TankProfile>((ref) {
  return TankProfile(
      volumeLiters: 100,
      surfaceAreaSqMeters: 0.3,
      tempC: 25.0,
      ph: 7.0,
      gh: 5.0,
      kh: 3.0,
      filterFlowRateLph: 500,
      filterMediaVolumeLiters: 1.0,
      mediaType: FilterMediaType.sponge,
      isPlanted: false
  );
});

// The list of fish currently in the tank.
final stockListProvider = StateProvider<List<StockedItem>>((ref) => []);

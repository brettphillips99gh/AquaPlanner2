import 'package:uuid/uuid.dart';
import 'models.dart'; // We'll need Tank from here later

/// Represents the chemical makeup of a user's water source.
class WaterSourceProfile {
  final String id;
  final String name; // e.g., "Kitchen Tap Water", "RO Unit"

  final double ph;
  final double gh;
  final double kh;
  final double tds; // TDS in parts per million (ppm)

  WaterSourceProfile({
    String? id,
    required this.name,
    required this.ph,
    required this.gh,
    required this.kh,
    required this.tds,
  }) : id = id ?? Uuid().v4();
}

/// Represents the top-level user account, containing their water sources and tanks.
class UserProfile {
  final String userId;
  final String displayName;
  final List<WaterSourceProfile> waterSources;
  final List<TankProfile> tanks; // We will use the existing TankProfile for now

  UserProfile({
    required this.userId,
    required this.displayName,
    this.waterSources = const [],
    this.tanks = const [],
  });
}

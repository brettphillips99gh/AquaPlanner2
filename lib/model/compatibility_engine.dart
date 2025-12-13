import 'package:aqua_planner_2/model/user_profile.dart';

import 'models.dart';

class CompatibilityReport {
  final bool isCompatible;
  final List<String> errors; // Fatal
  final List<String> warnings; // Advisory
  final RangeValues? safeTemp;
  final RangeValues? safePh;
  final RangeValues? safeGh;
  final RangeValues? safeKh;

  CompatibilityReport({
    required this.isCompatible,
    required this.errors,
    required this.warnings,
    this.safeTemp,
    this.safePh,
    this.safeGh,
    this.safeKh,
  });
}

class CompatibilityEngine {

  CompatibilityReport validate(TankProfile tank, List<StockedItem> stock, List<WaterSourceProfile> waterSources) {
    List<String> errors = [];
    List<String> warnings = [];

    // --- NEW: LOOKUP THE WATER SOURCE ---
    WaterSourceProfile? sourceWater;
    try {
      sourceWater = waterSources.firstWhere((ws) => ws.id == tank.waterSourceId);
    } catch (e) {
      // This is a data integrity error.
      errors.add('Data Error: The water source with ID "${tank.waterSourceId}" could not be found.');
      // Return early as further checks are unreliable.
      return CompatibilityReport(
          isCompatible: false, // Explicitly false because of the data error.
          errors: errors,      // The list containing our error message.
          warnings: warnings,    // The empty list of warnings.
          // Explicitly nullify the safe ranges as they cannot be calculated.
          safeTemp: null,
          safePh: null,
          safeGh: null,
          safeKh: null,
      );
    }


    if (stock.isEmpty) {
      return CompatibilityReport(
        isCompatible: true,
        errors: [],
        warnings: [],
        // Ensure all other fields are non-null
        safeTemp: null,
        safePh: null,
        safeGh: null,
        safeKh: null,
      );
    }

    // --- CHECK 0: SOURCE WATER SUITABILITY (using the looked-up sourceWater) ---
    for (final item in stock) {
      final species = item.species;
      // Check if source water pH is suitable
      if (!species.phRange.contains(sourceWater.ph)) {
        warnings.add(
            "Source Water Alert for ${species.name}: Your '${sourceWater.name}' pH (${sourceWater.ph}) is outside this species' tolerable range.");
      }
      // Check for GH, KH, and now TDS
      if (!species.tdsRange.contains(sourceWater.tds)) {
        warnings.add(
            "Source Water Alert for ${species.name}: Your '${sourceWater.name}' TDS (${sourceWater.tds.toStringAsFixed(0)}ppm) is outside this species' preferred range.");
      }
      // ... more source water checks ...
    }

    // --- CHECK 1: FIND COMMON WATER PARAMETERS ---
    var first = stock.first.species;
    RangeValues? safeTemp = first.tempRange;
    RangeValues? safePh = first.phRange;
    RangeValues? safeGh = first.ghRange;
    RangeValues? safeKh = first.khRange;

    for (int i = 1; i < stock.length; i++) {
      var s = stock[i].species;

      safeTemp = safeTemp?.intersection(s.tempRange);
      safePh = safePh?.intersection(s.phRange);
      safeGh = safeGh?.intersection(s.ghRange);
      safeKh = safeKh?.intersection(s.khRange);

      if (safeTemp == null) errors.add("Temp Mismatch: ${first.name} vs ${s.name}");
      if (safePh == null) errors.add("pH Mismatch: ${first.name} vs ${s.name}");
      if (safeGh == null) errors.add("gH Mismatch: ${first.name} vs ${s.name}");
    }

    // --- CHECK 2: VALIDATE AGAINST TANK ---
    // Only check if we found a valid intersection
    if (safeTemp != null && !safeTemp.contains(tank.tempC)) {
      warnings.add("Tank Temp (${tank.tempC}) is outside safe range ($safeTemp)");
    }
    if (safePh != null && !safePh.contains(tank.ph)) {
      warnings.add("Tank pH (${tank.ph}) is outside safe range ($safePh)");
    }
    if (safeGh != null && !safeGh.contains(tank.gh)) {
      warnings.add("Tank gH (${tank.gh}) is outside safe range ($safeGh)");
    }

    // --- CHECK 3: BIOLOGICAL & SOCIAL ---
    for (var item in stock) {
      // Shoaling
      if (item.count < item.species.minShoalSize) {
        warnings.add("Stress Warning: ${item.species.name} needs group of ${item.species.minShoalSize}+");
      }

      // Predation (The "Mouth Rule")
      if (item.species.aggressionType == AggressionType.predatory) {
        for (var prey in stock) {
          if (item == prey) continue;
          // If predator is 3x larger than prey, it's food.
          if (item.species.maxStandardLengthCm > (prey.species.maxStandardLengthCm * 3)) {
            errors.add("PREDATION RISK: ${item.species.name} will likely eat ${prey.species.name}");
          }
        }
      }
    }

    return CompatibilityReport(
      isCompatible: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      safeTemp: safeTemp,
      safePh: safePh,
      safeGh: safeGh,
      safeKh: safeKh,
    );
  }
}
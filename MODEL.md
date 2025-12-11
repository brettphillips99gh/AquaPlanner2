# AquaPlanner Simulation Engine Model

This document describes the internal logic of the two core simulation engines used in AquaPlanner: the `BioloadCalculator` and the `CompatibilityEngine`.

---

## 1. Bioload & System Health Engine (`BioloadCalculator`)

This engine simulates the chemical and biological balance of the aquarium, focusing on the nitrogen cycle and oxygen levels. The model is based on established principles from aquaculture engineering, primarily from the textbook "Aquaculture Engineering" by Timmons and Ebeling.

### a) The Nitrogen Cycle Model

The simulation models the two primary components of the nitrogen cycle: the production of ammonia by fish and the processing of ammonia by the filter.

#### The Source (Ammonia Production)

Ammonia production is calculated based on the total biomass of the fish and their diet. The formula is as follows:

`Total Fish Mass -> Daily Feed -> Protein Intake -> Nitrogen Waste -> Ammonia`

1.  **Total Mass**: Calculated from `StockedItem.estimatedTotalMassGrams` for all fish.
2.  **Daily Feed**: Assumed to be **1.5%** of total body weight per day. This is modified by the species' `ActivityLevel` (more active fish eat more).
3.  **Protein Intake**: Assumes a standard protein percentage in fish food (**40%** for omnivores/herbivores, **50%** for carnivores).
4.  **Nitrogen Waste**: Assumes protein is **16%** nitrogen by mass.
5.  **Ammonia (TAN)**: Assumes that **80%** of ingested nitrogen is excreted as Total Ammonia Nitrogen (TAN).

#### The Sink (Ammonia Processing)

The filter's capacity to process ammonia is calculated based on the surface area available to beneficial bacteria.

`Filter Media Volume -> Total Surface Area -> Nitrification Rate -> Adjusted Capacity`

1.  **Media Volume**: The volume of the filter media in Liters, provided by the `TankProfile`.
2.  **Total Surface Area**: The media volume is converted to cubic meters and multiplied by the **Specific Surface Area (SSA)** of the selected `FilterMediaType`. The SSA (in m²/m³) is a key metric representing how much area is available for bacteria to colonize.
3.  **Base Nitrification Rate**: A constant of **0.5g** of ammonia processed per square meter of surface area per day.
4.  **Adjusted Capacity**: This base rate is then adjusted by two efficiency factors:
    *   **Temperature Efficiency**: Bacterial activity decreases at lower temperatures (modeled as a -10% efficiency drop per degree below 25°C).
    *   **Flow Efficiency**: The filter's turnover rate (flow rate / tank volume) must be sufficient to deliver oxygen to the bacteria. Efficiency scales linearly up to a 4x turnover rate.

### b) The Oxygen Budget Model

This is a heuristic model that balances oxygen supply and demand.

-   **Oxygen Supply**: Primarily driven by the tank's **surface area** (for gas exchange). This value is given a slight boost if the tank is planted.
-   **Oxygen Demand**: The sum of two factors:
    1.  **Fish Respiration**: Proportional to the total metabolic mass of the fish.
    2.  **Bacterial Respiration**: The nitrification process itself consumes a significant amount of oxygen (stoichiometrically, 4.57g of O₂ is used for every 1g of ammonia processed).
-   **Oxygen Headroom**: The final value is calculated by taking the supply, reducing it based on the water temperature (hotter water holds less dissolved oxygen), and subtracting the total demand.

---

## 2. Species Compatibility Engine (`CompatibilityEngine`)

This engine validates whether a given group of species can coexist peacefully and healthily in the specified tank.

### a) Water Parameter Compatibility

This check determines if a set of shared water parameters exists for all species in the tank.

1.  **Find Intersection**: The engine takes the "thriving" ranges for Temperature, pH, and gH for the first species.
2.  **Iterate and Narrow**: It iterates through the rest of the stocked species, calculating the **intersection** of the current safe range and the next species' range.
3.  **Check for Failure**: If at any point the intersection results in `null` or an invalid range (e.g., `min >= max`), it means there is no overlapping parameter that satisfies all species, and a fatal **compatibility error** is generated.

### b) Tank Parameter Validation

If a common "safe range" was successfully found, this check validates the actual tank's parameters against it. If the tank's `tempC`, `ph`, or `gh` fall outside the calculated safe range, a **warning** is generated.

### c) Biological & Social Compatibility

This check looks at direct inter-species interactions.

-   **Shoaling Behavior**: It checks if the `count` for each `StockedItem` is less than the species' `minShoalSize`. If so, a **stress warning** is generated.
-   **Predation Risk**: A simple "Mouth Rule" is applied. If a species is marked as `predatory` and its maximum size is more than **3 times** the maximum size of another species in the tank, a fatal **predation error** is generated.

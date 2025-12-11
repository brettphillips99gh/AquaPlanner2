# Aqua Planner 2

A Flutter-based application for simulating and managing aquarium ecosystems.

## Data Model & Simulation Engine

The core of this application is a reactive simulation engine built entirely in Dart, using Riverpod for state management. This allows for real-time feedback to the user without the need for a backend server.

### Core Concepts

- **Declarative UI (Flutter & Riverpod):** The UI is built with Flutter and is powered by Riverpod. Widgets watch state providers, and the UI automatically updates in response to state changes.

- **Immutable State:** All model and state classes are immutable. When a change is made (e.g., adding a fish), a new state object is created, which efficiently triggers UI updates.

- **Reactive Calculation:** A central `simulationResultProvider` watches the input providers (`tankProfileProvider`, `stockListProvider`). When any input changes, this provider automatically re-runs the simulation and the UI instantly reflects the new results.

### Key Classes & Models

- **`SpeciesDefinition`**: An immutable class that defines the biological and environmental parameters of a fish species (e.g., temperature range, aggression, size).

- **`StockedItem`**: Represents a group of a single species within a tank, including the count.

- **`TankProfile`**: Holds the physical and chemical properties of the aquarium itself, such as volume, temperature, and filter setup.

- **`BioloadCalculator`**: A pure Dart class that calculates the biological load on the aquarium. It determines the ammonia production from fish waste and the filter's capacity to process it, based on principles from aquaculture engineering.

- **`CompatibilityEngine`**: Analyzes the social and environmental compatibility of the fish stock. It checks for parameter mismatches (like temperature or pH) and biological conflicts (like predation).

### State Management (Riverpod)

- **`tankProfileProvider` (StateProvider):** Holds the current `TankProfile`.

- **`stockListProvider` (StateNotifierProvider):** Manages the list of `StockedItem`s. The `StockNotifier` contains the business logic for adding and grouping fish correctly, preventing duplicate entries for the same species.

- **`simulationResultProvider` (Provider):** The heart of the reactive system. It watches the input providers and orchestrates the simulation by calling the `BioloadCalculator` and `CompatibilityEngine`.

## Getting Started

This project is a starting point for a Flutter application.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

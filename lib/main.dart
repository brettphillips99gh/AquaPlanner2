import 'model/models.dart';
import 'model/bioload_calculator.dart';
import 'model/compatibility_engine.dart';

void main() {
  // 1. Define The Encyclopedia
  final neonTetra = SpeciesDefinition(
      id: 'neon', name: 'Neon Tetra',
      maxStandardLengthCm: 3.5, averageAdultMassGrams: 2.0,
      trophicLevel: TrophicLevel.omnivore, activityLevel: ActivityLevel.active,
      aggressionType: AggressionType.peaceful, minShoalSize: 6,
      tempRange: RangeValues(21, 27), phRange: RangeValues(6.0, 7.5),
      ghRange: RangeValues(2, 10), khRange: RangeValues(0, 5)
  );

  final angelfish = SpeciesDefinition(
      id: 'angel', name: 'Angelfish',
      maxStandardLengthCm: 15.0, averageAdultMassGrams: 40.0,
      trophicLevel: TrophicLevel.carnivore, activityLevel: ActivityLevel.sedentary,
      aggressionType: AggressionType.semiAggressive, minShoalSize: 1,
      tempRange: RangeValues(24, 30), phRange: RangeValues(6.0, 7.5),
      ghRange: RangeValues(3, 12), khRange: RangeValues(0, 8)
  );

  // 2. Setup Tank (A 55 Gallon Setup)
  final myTank = TankProfile(
      volumeLiters: 200,
      surfaceAreaSqMeters: 0.5,
      tempC: 25.0, ph: 6.8, gh: 6.0, kh: 3.0, // Soft, acidic water
      filterFlowRateLph: 800,
      filterMediaVolumeLiters: 1.5,
      mediaType: FilterMediaType.ceramicRings,
      isPlanted: true
  );

  // 3. Stock the Tank
  final myStock = [
    StockedItem(species: neonTetra, count: 15, growthStage: GrowthStage.adult),
    StockedItem(species: angelfish, count: 2, growthStage: GrowthStage.subAdult),
  ];

  // 4. Run the Engines
  final calc = BioloadCalculator();
  final linter = CompatibilityEngine();

  final health = calc.calculate(myTank, myStock);
  final compat = linter.validate(myTank, myStock);

  // 5. Output
  print("--- AQUARIUM ANALYSIS ---");
  print("Stocking Level: ${health.ammoniaStockingPercent.toStringAsFixed(1)}%");
  print("Ammonia Input:  ${health.dailyAmmoniaProducedGrams.toStringAsFixed(3)}g / day");
  print("Filter Capacity:${health.dailyAmmoniaProcessedGrams.toStringAsFixed(3)}g / day");
  print("Oxygen Status:  ${health.oxygenHeadroom > 0 ? "Good" : "Hypoxia Risk"}");

  print("\n--- WARNINGS ---");
  health.warnings.forEach((w) => print("[SYS] $w"));
  compat.warnings.forEach((w) => print("[BIO] $w"));

  if (compat.errors.isNotEmpty) {
    print("\n--- CRITICAL ERRORS ---");
    compat.errors.forEach((e) => print("[!!!] $e"));
  } else {
    print("\n[OK] Species are compatible.");
  }
}

// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: .fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: .center,
//           children: [
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
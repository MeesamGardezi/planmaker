import 'package:flutter/material.dart';
import 'screens/floor_plan_editor.dart';
import 'models/enums.dart';

void main() => runApp(const FloorPlanDesignerApp());

class FloorPlanDesignerApp extends StatelessWidget {
  const FloorPlanDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floor Plan Designer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FloorPlanApp(),
    );
  }
}

class FloorPlanApp extends StatelessWidget {
  const FloorPlanApp({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: FloorPlanEditor(),
      );
}
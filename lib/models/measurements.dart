// Create a new file: lib/models/measurement.dart
import 'dart:ui';

class Measurement {
  final Offset start;
  final Offset end;
  final double measuredLength; // In pixels
  final DateTime timestamp;
  bool isTemporary;
  
  Measurement({
    required this.start,
    required this.end,
    required this.measuredLength,
    this.isTemporary = true,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  // Get measurement line as vector
  Offset get vector => end - start;
  
  // Get midpoint of measurement
  Offset get midpoint => Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
}
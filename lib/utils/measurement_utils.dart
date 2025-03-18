import '../models/enums.dart';

class MeasurementUtils {
  static String formatLength(double meters, MeasurementUnit unit) {
    final converted = meters * unit.conversionFromMeters;
    return '${converted.toStringAsFixed(2)}${unit.symbol}';
  }
  
  static String formatArea(double squareMeters, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        return '${squareMeters.toStringAsFixed(2)}m²';
      case MeasurementUnit.feet:
        final sqft = squareMeters * 10.7639;
        return '${sqft.toStringAsFixed(2)}ft²';
      case MeasurementUnit.inches:
        final sqin = squareMeters * 1550;
        return '${sqin.toStringAsFixed(2)}in²';
    }
  }
  
  static String formatVolume(double cubicMeters, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        return '${cubicMeters.toStringAsFixed(2)}m³';
      case MeasurementUnit.feet:
        final cuft = cubicMeters * 35.3147;
        return '${cuft.toStringAsFixed(2)}ft³';
      case MeasurementUnit.inches:
        final cuin = cubicMeters * 61023.7;
        return '${cuin.toStringAsFixed(2)}in³';
    }
  }
  
  // Convert from grid to real world and vice versa
  static double gridToReal(double gridValue, double gridSize, double gridRealSize) {
    return gridValue * gridRealSize / gridSize;
  }
  
  static double realToGrid(double realValue, double gridSize, double gridRealSize) {
    return realValue * gridSize / gridRealSize;
  }
  
  // Parse user input dimension
  static double parseUserDimension(String input, MeasurementUnit unit) {
    // Remove any unit symbols that might be included
    String cleanInput = input.replaceAll(unit.symbol, '').trim();
    
    // Try to parse as double
    double? value = double.tryParse(cleanInput);
    
    // Return value or default
    return value ?? 0;
  }
  
  // Format with unit for display in text fields
  static String formatWithUnit(double value, MeasurementUnit unit) {
    return '${value.toStringAsFixed(2)} ${unit.symbol}';
  }
}
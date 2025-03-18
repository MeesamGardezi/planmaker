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
  
  // Grid to real world conversion
  static double gridToReal(double gridValue, double gridSize, double gridRealSize) {
    return gridValue * gridRealSize / gridSize;
  }
  
  // Real world to grid conversion
  static double realToGrid(double realValue, double gridSize, double gridRealSize) {
    return realValue * gridSize / gridRealSize;
  }
}
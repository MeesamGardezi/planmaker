enum ElementType {
  door('Door'),
  window('Window'),
  line('Line');

  final String label;
  const ElementType(this.label);
}

enum MeasurementUnit {
  feet('ft', 3.28084),
  meters('m', 1.0),
  inches('in', 39.3701);

  final String symbol;
  final double conversionFromMeters;
  const MeasurementUnit(this.symbol, this.conversionFromMeters);
}

enum EditorMode {
  select('Select'),
  room('Room'),
  door('Door'),
  window('Window'),
  line('Line'),
  measure('Measure'),
  delete('Delete');
  final String label;
  const EditorMode(this.label);
}

// Simplified snap types
enum SnapType {
  none('No Snap'),
  corner('Corner Snap'),
  wall('Wall Snap');

  final String label;
  const SnapType(this.label);
}
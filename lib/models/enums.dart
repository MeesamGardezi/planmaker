enum ElementType {
  door('Door'),
  window('Window');

  final String label;
  const ElementType(this.label);
}

enum MeasurementUnit {
  meters('m', 1.0),
  feet('ft', 3.28084),
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
  delete('Delete');

  final String label;
  const EditorMode(this.label);
}
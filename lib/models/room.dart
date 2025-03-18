import 'dart:ui';
import 'element.dart';

class Room {
  String name;
  Color color;
  bool selected;
  double width;
  double height;
  Offset position;
  bool isDragging = false;
  List<ArchitecturalElement> elements = [];

  Room({
    required this.name,
    required this.color,
    this.selected = false,
    this.width = 200,
    this.height = 150,
    required this.position,
  });

  bool containsPoint(Offset point) {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    
    return point.dx >= position.dx - halfWidth &&
           point.dx <= position.dx + halfWidth &&
           point.dy >= position.dy - halfHeight &&
           point.dy <= position.dy + halfHeight;
  }
  
  void move(Offset delta) {
    position += delta;
    
    // Update all elements
    for (var element in elements) {
      element.position += delta;
    }
  }

  Rect get rect => Rect.fromCenter(
    center: position,
    width: width,
    height: height,
  );

  // Get wall points as a list of points (clockwise)
  List<Offset> getWallPoints() {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    
    return [
      Offset(position.dx - halfWidth, position.dy - halfHeight), // Top-left
      Offset(position.dx + halfWidth, position.dy - halfHeight), // Top-right
      Offset(position.dx + halfWidth, position.dy + halfHeight), // Bottom-right
      Offset(position.dx - halfWidth, position.dy + halfHeight), // Bottom-left
    ];
  }

  // Get wall segments as a list of (start, end) point pairs
  List<(Offset, Offset)> getWallSegments() {
    final points = getWallPoints();
    
    return [
      (points[0], points[1]), // Top wall
      (points[1], points[2]), // Right wall
      (points[2], points[3]), // Bottom wall
      (points[3], points[0]), // Left wall
    ];
  }

  // Check if a point is near any wall
  bool isPointNearWall(Offset point, double tolerance) {
    for (var segment in getWallSegments()) {
      if (isPointNearLineSegment(point, segment.$1, segment.$2, tolerance)) {
        return true;
      }
    }
    return false;
  }
  
  // Find the wall segment nearest to a point
  (Offset, Offset)? findNearestWallSegment(Offset point, double tolerance) {
    (Offset, Offset)? nearestSegment;
    double minDistance = double.infinity;
    
    for (var segment in getWallSegments()) {
      final distance = distanceToLineSegment(point, segment.$1, segment.$2);
      if (distance < minDistance && distance <= tolerance) {
        minDistance = distance;
        nearestSegment = segment;
      }
    }
    
    return nearestSegment;
  }
  
  // Helper: Check if a point is near a line segment
  bool isPointNearLineSegment(Offset point, Offset start, Offset end, double tolerance) {
    return distanceToLineSegment(point, start, end) <= tolerance;
  }
  
  // Helper: Calculate distance from point to line segment
  double distanceToLineSegment(Offset point, Offset start, Offset end) {
    final l2 = (end - start).distanceSquared;
    if (l2 == 0) return (point - start).distance; // Start and end are the same point
    
    // Consider the line extending the segment, parameterized as start + t (end - start)
    // We find projection of point onto the line
    final t = ((point - start).dx * (end - start).dx + (point - start).dy * (end - start).dy) / l2;
    
    if (t < 0) return (point - start).distance;       // Beyond the start point
    if (t > 1) return (point - end).distance;         // Beyond the end point
    
    final projection = start + (end - start) * t;     // Projection on the line segment
    return (point - projection).distance;
  }

  // Get area in square meters
  double getArea(double gridSize, double gridRealSize) {
    return width * height * (gridRealSize / gridSize) * (gridRealSize / gridSize);
  }
  
  // Get perimeter in meters
  double getPerimeter(double gridSize, double gridRealSize) {
    return 2 * (width + height) * (gridRealSize / gridSize);
  }
}
import 'dart:ui';
import 'dart:math' as math;
import 'enums.dart';

class ArchitecturalElement {
  final ElementType type;
  Offset position;
  double rotation; // in radians
  double width;
  double height;
  bool isSelected;
  String? name;
  bool isDragging = false;

  static const double defaultDoorWidth = 30.0;
  static const double defaultDoorHeight = 6.0;
  static const double defaultWindowWidth = 40.0;
  static const double defaultWindowHeight = 6.0;

  ArchitecturalElement({
    required this.type,
    required this.position,
    this.rotation = 0,
    double? width,
    double? height,
    this.isSelected = false,
    this.name,
  })  : width = width ?? _getDefaultWidth(type),
        height = height ?? _getDefaultHeight(type);

  static double _getDefaultWidth(ElementType type) {
    switch (type) {
      case ElementType.door: 
        return defaultDoorWidth;
      case ElementType.window: 
        return defaultWindowWidth;
      default:
        return 30.0;
    }
  }

  static double _getDefaultHeight(ElementType type) {
    switch (type) {
      case ElementType.door: 
        return defaultDoorHeight;
      case ElementType.window: 
        return defaultWindowHeight;
      default:
        return 30.0;
    }
  }

  bool containsPoint(Offset point) {
    // Transform point to element's local coordinate system
    final dx = point.dx - position.dx;
    final dy = point.dy - position.dy;
    final rotatedX = dx * math.cos(-rotation) - dy * math.sin(-rotation);
    final rotatedY = dx * math.sin(-rotation) + dy * math.cos(-rotation);

    return rotatedX.abs() <= width / 2 &&
        rotatedY.abs() <= height / 2;
  }

  // Snap to a wall segment
  void snapToWall((Offset, Offset) wallSegment, double wallThickness) {
    final start = wallSegment.$1;
    final end = wallSegment.$2;
    
    // Calculate wall angle
    final wallAngle = math.atan2(
      end.dy - start.dy,
      end.dx - start.dx,
    );

    // Snap rotation to wall
    rotation = wallAngle;

    // Place element at midpoint of the wall
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    position = Offset(midX, midY);

    // Offset position perpendicular to wall by half the wall thickness
    final perpAngle = wallAngle + math.pi / 2;
    position = Offset(
      position.dx + math.cos(perpAngle) * wallThickness / 2,
      position.dy + math.sin(perpAngle) * wallThickness / 2,
    );
  }
}
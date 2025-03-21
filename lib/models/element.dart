import 'dart:ui';
import 'dart:math' as math;
import 'enums.dart';
import 'room.dart';

class ArchitecturalElement {
  final ElementType type;
  Offset position;
  double rotation; // in radians
  double width;
  double height;
  bool isSelected;
  String? name;
  bool isDragging = false;
  Room? room; // Reference to the room this element belongs to

  // Drag tracking
  Offset? dragStartPosition;
  Offset? lastDragPosition;

  static const double defaultDoorWidth = 30.0;
  static const double defaultDoorHeight = 6.0;
  static const double defaultWindowWidth = 40.0;
  static const double defaultWindowHeight = 6.0;

  Offset? startPoint;
  Offset? endPoint;

  // Selection hitbox expansion (makes selection easier)
  final double selectionPadding = 8.0;

  ArchitecturalElement({
    required this.type,
    required this.position,
    this.rotation = 0,
    double? width,
    double? height,
    this.isSelected = false,
    this.name,
    this.room,
    this.startPoint,
    this.endPoint,
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

  factory ArchitecturalElement.line({
    required Offset start,
    required Offset end,
    bool isSelected = false,
    String? name,
    Room? room,
  }) {
    final position = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // Calculate width (length of line) and angle
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);

    return ArchitecturalElement(
      type: ElementType.line,
      position: position,
      rotation: angle,
      width: length,
      height: 1.0, // Thin line
      isSelected: isSelected,
      name: name,
      room: room,
      startPoint: start,
      endPoint: end,
    );
  }

  bool containsPoint(Offset point) {
    // Expand hitbox if selected for easier manipulation
    final effectiveWidth = width + (isSelected ? selectionPadding * 2 : 0);
    final effectiveHeight = height + (isSelected ? selectionPadding * 2 : 0);

    // Transform point to element's local coordinate system
    final dx = point.dx - position.dx;
    final dy = point.dy - position.dy;
    final rotatedX = dx * math.cos(-rotation) - dy * math.sin(-rotation);
    final rotatedY = dx * math.sin(-rotation) + dy * math.cos(-rotation);

    return rotatedX.abs() <= effectiveWidth / 2 &&
        rotatedY.abs() <= effectiveHeight / 2;
  }

  void startDrag(Offset point) {
    isDragging = true;
    dragStartPosition = point;
    lastDragPosition = point;
  }

  void drag(Offset point) {
    if (!isDragging || lastDragPosition == null) return;

    final delta = point - lastDragPosition!;
    position += delta;
    lastDragPosition = point;
  }

  void endDrag() {
    isDragging = false;
    dragStartPosition = null;
    lastDragPosition = null;
  }

  // Snap to a corner
  void snapToCorner(Offset cornerPosition, Room targetRoom, int cornerIndex) {
    // Set position to the corner
    position = cornerPosition;

    // Get the angle based on which corner we're snapping to
    double angle;
    switch (cornerIndex) {
      case 0: // Top-left
        angle = -math.pi / 4; // 45 degrees inward
        break;
      case 1: // Top-right
        angle = -3 * math.pi / 4; // 135 degrees inward
        break;
      case 2: // Bottom-right
        angle = 3 * math.pi / 4; // 225 degrees inward
        break;
      case 3: // Bottom-left
        angle = math.pi / 4; // 315 degrees inward
        break;
      default:
        angle = 0;
    }

    // Set the rotation
    rotation = angle;

    // Update the room reference
    room = targetRoom;

    // Offset position slightly from corner (aesthetic adjustment)
    final offsetDistance = width / 4;
    position = Offset(position.dx + math.cos(angle) * offsetDistance,
        position.dy + math.sin(angle) * offsetDistance);
  }

  // Snap to a wall (placed at midpoint)
  void snapToWallMidpoint(Offset midpoint, (Offset, Offset) wallSegment) {
    final start = wallSegment.$1;
    final end = wallSegment.$2;

    // Calculate wall angle
    final wallAngle = math.atan2(
      end.dy - start.dy,
      end.dx - start.dx,
    );

    // Snap rotation to wall angle
    rotation = wallAngle;

    // Place element at midpoint of the wall
    position = midpoint;

    // Offset position perpendicular to wall (aesthetic adjustment)
    final perpAngle = wallAngle + math.pi / 2;
    position = Offset(position.dx + math.cos(perpAngle) * (height / 2),
        position.dy + math.sin(perpAngle) * (height / 2));
  }

  // Find the closest corner to snap to
  static (Offset, Room, int, double)? findClosestCorner(
      Offset position, List<Room> rooms, double maxDistance) {
    final result = Room.findClosestCorner(position, rooms, maxDistance);

    if (result != null) {
      final cornerPos = result.$1;
      final distance = result.$2;
      final cornerIndex = result.$3;
      final room = result.$4;

      return (cornerPos, room, cornerIndex, distance);
    }

    return null;
  }

  // Get bounds as a rotated rectangle (for visual feedback)
  List<Offset> getBounds() {
    final halfWidth = width / 2;
    final halfHeight = height / 2;

    final topLeft = _rotatePoint(Offset(-halfWidth, -halfHeight));
    final topRight = _rotatePoint(Offset(halfWidth, -halfHeight));
    final bottomRight = _rotatePoint(Offset(halfWidth, halfHeight));
    final bottomLeft = _rotatePoint(Offset(-halfWidth, halfHeight));

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  // Helper to rotate a point around the center
  Offset _rotatePoint(Offset localPoint) {
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);

    final rotatedX = localPoint.dx * cos - localPoint.dy * sin;
    final rotatedY = localPoint.dx * sin + localPoint.dy * cos;

    return Offset(position.dx + rotatedX, position.dy + rotatedY);
  }
}

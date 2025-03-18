// lib/models/room.dart
import 'dart:ui';
import 'element.dart';
import 'dart:math' as math;

// Extension to add normalization to Offset
extension OffsetExtension on Offset {
  Offset normalized() {
    if (distance == 0) return Offset.zero;
    return Offset(dx / distance, dy / distance);
  }
}

// Simplified Wall class - only has height
class Wall {
  double height;

  Wall({
    this.height = 8.0, // Default height in feet
  });

  // Deep copy constructor
  Wall.clone(Wall source)
      : height = source.height;
}

class Room {
  String name;
  Color color;
  bool selected;
  double width;
  double height;
  Offset position;
  bool isDragging = false;
  List<ArchitecturalElement> elements = [];

  // Wall properties - one Wall object for each wall
  final List<Wall> walls;

  // Track drag-related data
  Offset? dragStartPosition;
  Offset? lastDragPosition;

  // Selection hitbox expansion (makes selection easier)
  final double selectionPadding = 5.0;

  Room({
    required this.name,
    required this.color,
    this.selected = false,
    this.width = 200,
    this.height = 150,
    required this.position,
    List<Wall>? walls,
  }) : walls = walls ?? List.generate(4, (_) => Wall());

  bool containsPoint(Offset point) {
    final halfWidth = width / 2 + (selected ? selectionPadding : 0);
    final halfHeight = height / 2 + (selected ? selectionPadding : 0);

    return point.dx >= position.dx - halfWidth &&
        point.dx <= position.dx + halfWidth &&
        point.dy >= position.dy - halfHeight &&
        point.dy <= position.dy + halfHeight;
  }

  void startDrag(Offset point) {
    isDragging = true;
    dragStartPosition = point;
    lastDragPosition = point;
  }

  void drag(Offset point) {
    if (!isDragging || lastDragPosition == null) return;

    final delta = point - lastDragPosition!;
    move(delta);
    lastDragPosition = point;
  }

  void endDrag() {
    isDragging = false;
    dragStartPosition = null;
    lastDragPosition = null;
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

  // Selection visual rect (slightly larger than the room for easier selection)
  Rect get selectionRect => Rect.fromCenter(
        center: position,
        width: width + (selected ? selectionPadding * 2 : 0),
        height: height + (selected ? selectionPadding * 2 : 0),
      );

  // Get room corners
  List<Offset> getCorners() {
    final halfWidth = width / 2;
    final halfHeight = height / 2;

    return [
      Offset(position.dx - halfWidth, position.dy - halfHeight), // Top-left
      Offset(position.dx + halfWidth, position.dy - halfHeight), // Top-right
      Offset(position.dx + halfWidth, position.dy + halfHeight), // Bottom-right
      Offset(position.dx - halfWidth, position.dy + halfHeight), // Bottom-left
    ];
  }

  // Get corner descriptions for tooltips and display
  List<String> getCornerDescriptions() {
    return [
      "Top-left",
      "Top-right",
      "Bottom-right",
      "Bottom-left",
    ];
  }

  // Get wall segments as a list of (start, end) point pairs
  List<(Offset, Offset)> getWallSegments() {
    final points = getCorners();

    return [
      (points[0], points[1]), // Top wall (0)
      (points[1], points[2]), // Right wall (1)
      (points[2], points[3]), // Bottom wall (2)
      (points[3], points[0]), // Left wall (3)
    ];
  }

  // Get wall descriptions for tooltips and display
  List<String> getWallDescriptions() {
    return [
      "Top wall",
      "Right wall",
      "Bottom wall",
      "Left wall",
    ];
  }

  // Get wall lengths in pixels
  List<double> getWallLengths() {
    final segments = getWallSegments();
    return segments
        .map((segment) => (segment.$2 - segment.$1).distance)
        .toList();
  }

  // Get wall lengths in real world units
  List<double> getWallRealLengths(double gridSize, double gridRealSize) {
    final pixelLengths = getWallLengths();
    return pixelLengths
        .map((length) => length * gridRealSize / gridSize)
        .toList();
  }

  // Helper method to calculate the distance from a point to a wall segment
  static double distanceToWall(Offset point, (Offset, Offset) wall) {
    final start = wall.$1;
    final end = wall.$2;

    // Vector from start to end
    final wallVector = end - start;
    final wallLength = wallVector.distance;

    // If wall has no length, return distance to start point
    if (wallLength < 0.001) return (point - start).distance;

    // Normalized wall vector
    final wallNormal = wallVector.normalized();

    // Vector from start to point
    final pointVector = point - start;

    // Project pointVector onto wallVector to find the closest point on the wall
    final projection =
        pointVector.dx * wallNormal.dx + pointVector.dy * wallNormal.dy;

    // Clamp projection to wall length
    final clampedProjection = projection.clamp(0.0, wallLength);

    // Calculate closest point on wall
    final closestPoint = start +
        Offset(wallNormal.dx * clampedProjection,
            wallNormal.dy * clampedProjection);

    // Return distance from point to closest point on wall
    return (point - closestPoint).distance;
  }

  // Determine if a point is inside the wall segment with given tolerance
  static bool isPointOnWall(
      Offset point, (Offset, Offset) wall, double tolerance) {
    return distanceToWall(point, wall) <= tolerance;
  }

  // Find closest corner for snapping
  static (Offset, double, int, Room)? findClosestCorner(
      Offset point, List<Room> rooms, double snapDistance) {
    Offset closestPoint = point;
    double minDistance = double.infinity;
    int cornerIndex = -1;
    Room? closestRoom;

    for (var room in rooms) {
      final corners = room.getCorners();
      for (int i = 0; i < corners.length; i++) {
        final distance = (point - corners[i]).distance;
        if (distance < minDistance && distance <= snapDistance) {
          minDistance = distance;
          closestPoint = corners[i];
          cornerIndex = i;
          closestRoom = room;
        }
      }
    }

    return (minDistance < snapDistance && closestRoom != null)
        ? (closestPoint, minDistance, cornerIndex, closestRoom)
        : null;
  }

  // Find closest point on any wall
  static (Offset, double, (Offset, Offset), Room)? findClosestWallPoint(
      Offset point, List<Room> rooms, double snapDistance) {
    double minDistance = double.infinity;
    Offset closestPoint = point;
    (Offset, Offset) closestWall = (Offset.zero, Offset.zero);
    Room? closestRoom;

    for (var room in rooms) {
      final walls = room.getWallSegments();

      for (var wall in walls) {
        final start = wall.$1;
        final end = wall.$2;

        // Vector from start to end
        final wallVector = end - start;
        final wallLength = wallVector.distance;

        // Normalized wall vector
        final wallNormal = wallVector.normalized();

        // Vector from start to point
        final pointVector = point - start;

        // Project pointVector onto wallVector
        final projection =
            pointVector.dx * wallNormal.dx + pointVector.dy * wallNormal.dy;

        // Clamp projection to wall length
        final clampedProjection = projection.clamp(0.0, wallLength);

        // Calculate closest point on wall
        final pointOnWall = start +
            Offset(wallNormal.dx * clampedProjection,
                wallNormal.dy * clampedProjection);

        // Calculate distance to wall
        final distance = (point - pointOnWall).distance;

        if (distance < minDistance && distance <= snapDistance) {
          minDistance = distance;
          closestPoint = pointOnWall;
          closestWall = wall;
          closestRoom = room;
        }
      }
    }

    return (minDistance < snapDistance && closestRoom != null)
        ? (closestPoint, minDistance, closestWall, closestRoom)
        : null;
  }

  
  
  // Check if two walls are parallel
  static bool areWallsParallel((Offset, Offset) wall1, (Offset, Offset) wall2) {
    final wall1Vector = wall1.$2 - wall1.$1;
    final wall2Vector = wall2.$2 - wall2.$1;

    // Skip very short walls
    if (wall1Vector.distance < 1.0 || wall2Vector.distance < 1.0) {
      return false;
    }

    // Calculate normalized directional vectors
    final wall1Dir = wall1Vector.normalized();
    final wall2Dir = wall2Vector.normalized();

    // Dot product close to 1 or -1 means parallel
    final dot = wall1Dir.dx * wall2Dir.dx + wall1Dir.dy * wall2Dir.dy;

    // Check if walls are primarily in the same direction
    final isHorizontal1 = wall1Vector.dx.abs() > wall1Vector.dy.abs();
    final isHorizontal2 = wall2Vector.dx.abs() > wall2Vector.dy.abs();

    // More lenient check (0.85 instead of 0.9)
    return (dot.abs() > 0.85) && (isHorizontal1 == isHorizontal2);
  }
  
  // Get wall alignment offset to align a wall with another wall
  static Offset getWallAlignmentOffset((Offset, Offset) sourceWall, (Offset, Offset) targetWall) {
    if (!areWallsParallel(sourceWall, targetWall)) return Offset.zero;

    final sourceVector = sourceWall.$2 - sourceWall.$1;
    final isHorizontal = sourceVector.dx.abs() > sourceVector.dy.abs();

    if (isHorizontal) {
      // For horizontal walls, align y coordinates
      return Offset(0, targetWall.$1.dy - sourceWall.$1.dy);
    } else {
      // For vertical walls, align x coordinates
      return Offset(targetWall.$1.dx - sourceWall.$1.dx, 0);
    }
  }
}
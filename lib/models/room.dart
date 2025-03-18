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

  // Track drag-related data
  Offset? dragStartPosition;
  Offset? lastDragPosition;
  
  // Track which corner was closest to the drag point (for corner-to-corner snapping)
  int? draggedCornerIndex;
  
  // Selection hitbox expansion (makes selection easier)
  final double selectionPadding = 5.0;

  Room({
    required this.name,
    required this.color,
    this.selected = false,
    this.width = 200,
    this.height = 150,
    required this.position,
  });

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
    
    // Determine which corner is closest to the drag point
    final corners = getCorners();
    double minDistance = double.infinity;
    
    for (int i = 0; i < corners.length; i++) {
      final distance = (corners[i] - point).distance;
      if (distance < minDistance) {
        minDistance = distance;
        draggedCornerIndex = i;
      }
    }
    
    // Debug info
    print("Started drag near corner $draggedCornerIndex");
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
    // DO NOT clear draggedCornerIndex here - we need it for the snap!
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
  
  // Get opposite corner index
  int getOppositeCornerIndex(int cornerIndex) {
    return (cornerIndex + 2) % 4;
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
      (points[0], points[1]), // Top wall
      (points[1], points[2]), // Right wall
      (points[2], points[3]), // Bottom wall
      (points[3], points[0]), // Left wall
    ];
  }

  // Find closest corner for snapping
  static (Offset, double, int, Room)? findClosestCorner(Offset point, List<Room> rooms, double snapDistance) {
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
  
  // Find closest midpoint between two corners
  static (Offset, double)? findClosestMidpoint(Offset point, List<Room> rooms, double snapDistance) {
    Offset closestPoint = point;
    double minDistance = double.infinity;
    
    for (var room in rooms) {
      final corners = room.getCorners();
      // Check midpoints of all wall segments
      for (int i = 0; i < corners.length; i++) {
        final nextIndex = (i + 1) % corners.length;
        final midpoint = Offset(
          (corners[i].dx + corners[nextIndex].dx) / 2,
          (corners[i].dy + corners[nextIndex].dy) / 2,
        );
        
        final distance = (point - midpoint).distance;
        if (distance < minDistance && distance <= snapDistance) {
          minDistance = distance;
          closestPoint = midpoint;
        }
      }
    }
    
    return minDistance < snapDistance 
        ? (closestPoint, minDistance) 
        : null;
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
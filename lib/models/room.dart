import 'dart:ui';
import 'element.dart';

class Wall {
  double height;
  double breadth;
  String? material;
  Color? color;
  
  Wall({
    this.height = 2.4, // Default height in meters
    this.breadth = 0.15, // Default breadth/thickness in meters
    this.material,
    this.color,
  });
  
  // Deep copy constructor
  Wall.clone(Wall source)
      : height = source.height,
        breadth = source.breadth,
        material = source.material,
        color = source.color;
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
  
  // Shared wall tracking
  List<(Room, int, int)> sharedWalls = []; // (connected room, this wall index, other wall index)
  
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
  
  // Get wall directions (0 = horizontal, 1 = vertical)
  List<int> getWallDirections() {
    return [0, 1, 0, 1]; // top, right, bottom, left
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
    return segments.map((segment) => (segment.$2 - segment.$1).distance).toList();
  }
  
  // Get wall lengths in real world units
  List<double> getWallRealLengths(double gridSize, double gridRealSize) {
    final pixelLengths = getWallLengths();
    return pixelLengths.map((length) => length * gridRealSize / gridSize).toList();
  }
  
  // Calculate wall area for a specific wall
  double getWallArea(int wallIndex, double gridSize, double gridRealSize) {
    final pixelLength = getWallLengths()[wallIndex];
    final realLength = pixelLength * gridRealSize / gridSize;
    
    final wall = walls[wallIndex];
    return realLength * wall.height * wall.breadth;
  }
  
  // Calculate areas for all walls
  List<double> getAllWallAreas(double gridSize, double gridRealSize) {
    final realLengths = getWallRealLengths(gridSize, gridRealSize);
    
    List<double> areas = [];
    for (int i = 0; i < 4; i++) {
      areas.add(realLengths[i] * walls[i].height * walls[i].breadth);
    }
    
    return areas;
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
    final wallNormal = Offset(wallVector.dx / wallLength, wallVector.dy / wallLength);
    
    // Vector from start to point
    final pointVector = point - start;
    
    // Project pointVector onto wallVector to find the closest point on the wall
    final projection = pointVector.dx * wallNormal.dx + pointVector.dy * wallNormal.dy;
    
    // Clamp projection to wall length
    final clampedProjection = projection.clamp(0.0, wallLength);
    
    // Calculate closest point on wall
    final closestPoint = start + Offset(
      wallNormal.dx * clampedProjection,
      wallNormal.dy * clampedProjection
    );
    
    // Return distance from point to closest point on wall
    return (point - closestPoint).distance;
  }
  
  // Determine if a point is inside the wall segment with given tolerance
  static bool isPointOnWall(Offset point, (Offset, Offset) wall, double tolerance) {
    return distanceToWall(point, wall) <= tolerance;
  }

  // Check if two walls are parallel
  static bool areWallsParallel((Offset, Offset) wall1, (Offset, Offset) wall2) {
    final wall1Vector = wall1.$2 - wall1.$1;
    final wall2Vector = wall2.$2 - wall2.$1;
    
    // Calculate normalized directional vectors
    final wall1Dir = Offset(
      wall1Vector.dx / wall1Vector.distance,
      wall1Vector.dy / wall1Vector.distance
    );
    
    final wall2Dir = Offset(
      wall2Vector.dx / wall2Vector.distance,
      wall2Vector.dy / wall2Vector.distance
    );
    
    // Dot product close to 1 or -1 means parallel
    final dot = wall1Dir.dx * wall2Dir.dx + wall1Dir.dy * wall2Dir.dy;
    return (dot.abs() > 0.97); // Allow for small angle differences
  }
  
  // Check if two walls are aligned (parallel and collinear)
  static bool areWallsAligned((Offset, Offset) wall1, (Offset, Offset) wall2, double tolerance) {
    if (!areWallsParallel(wall1, wall2)) return false;
    
    // For aligned walls, the distance from any point of wall1 to wall2 should be small
    return distanceToWall(wall1.$1, wall2) <= tolerance &&
           distanceToWall(wall1.$2, wall2) <= tolerance;
  }
  
  // Check if two walls overlap
  static bool doWallsOverlap((Offset, Offset) wall1, (Offset, Offset) wall2, double tolerance) {
    if (!areWallsAligned(wall1, wall2, tolerance)) return false;
    
    // Project walls onto common axis to check for overlap
    final wall1Vector = wall1.$2 - wall1.$1;
    final isHorizontal = wall1Vector.dy.abs() < 0.001;
    
    if (isHorizontal) {
      // Sort x coordinates
      final x1 = [wall1.$1.dx, wall1.$2.dx]..sort();
      final x2 = [wall2.$1.dx, wall2.$2.dx]..sort();
      
      // Check for x overlap
      return !(x1[1] < x2[0] || x2[1] < x1[0]);
    } else {
      // Sort y coordinates
      final y1 = [wall1.$1.dy, wall1.$2.dy]..sort();
      final y2 = [wall2.$1.dy, wall2.$2.dy]..sort();
      
      // Check for y overlap
      return !(y1[1] < y2[0] || y2[1] < y1[0]);
    }
  }
  
  // Get the projection of a wall onto an axis
  static (double, double) projectWallToAxis((Offset, Offset) wall, bool horizontal) {
    if (horizontal) {
      final min = wall.$1.dx < wall.$2.dx ? wall.$1.dx : wall.$2.dx;
      final max = wall.$1.dx > wall.$2.dx ? wall.$1.dx : wall.$2.dx;
      return (min, max);
    } else {
      final min = wall.$1.dy < wall.$2.dy ? wall.$1.dy : wall.$2.dy;
      final max = wall.$1.dy > wall.$2.dy ? wall.$1.dy : wall.$2.dy;
      return (min, max);
    }
  }
  
  // Find the offset needed to align a wall with another wall
  static Offset getWallAlignmentOffset((Offset, Offset) sourceWall, (Offset, Offset) targetWall) {
    if (!areWallsParallel(sourceWall, targetWall)) return Offset.zero;
    
    final sourceVector = sourceWall.$2 - sourceWall.$1;
    final isHorizontal = sourceVector.dy.abs() < 0.001;
    
    if (isHorizontal) {
      // For horizontal walls, align y coordinates
      return Offset(0, targetWall.$1.dy - sourceWall.$1.dy);
    } else {
      // For vertical walls, align x coordinates
      return Offset(targetWall.$1.dx - sourceWall.$1.dx, 0);
    }
  }
  
  // Add a shared wall connection
  void addSharedWall(Room otherRoom, int thisWallIndex, int otherWallIndex) {
    // Check if connection already exists
    for (var connection in sharedWalls) {
      if (connection.$1 == otherRoom && 
          connection.$2 == thisWallIndex && 
          connection.$3 == otherWallIndex) {
        return; // Connection already exists
      }
    }
    
    // Add new connection
    sharedWalls.add((otherRoom, thisWallIndex, otherWallIndex));
    
    // Also add connection to the other room if not already there
    bool connectionExists = otherRoom.sharedWalls
        .any((conn) => conn.$1 == this && conn.$2 == otherWallIndex && conn.$3 == thisWallIndex);
        
    if (!connectionExists) {
      otherRoom.addSharedWall(this, otherWallIndex, thisWallIndex);
    }
  }
  
  // Remove all shared wall connections
  void clearSharedWalls() {
    // Remove this room from other rooms' shared walls
    for (var connection in sharedWalls) {
      final otherRoom = connection.$1;
      otherRoom.sharedWalls.removeWhere((conn) => conn.$1 == this);
    }
    
    // Clear this room's shared walls
    sharedWalls.clear();
  }
  
  // Check if a wall is shared with another room
  bool isWallShared(int wallIndex) {
    return sharedWalls.any((connection) => connection.$2 == wallIndex);
  }
  
  // Get all rooms that share a specific wall
  List<Room> getRoomsWithSharedWall(int wallIndex) {
    return sharedWalls
        .where((connection) => connection.$2 == wallIndex)
        .map((connection) => connection.$1)
        .toList();
  }

  // Find best wall-to-wall alignment between two rooms
  static (Offset, int, int)? findBestWallAlignment(Room room1, Room room2, double snapDistance) {
    if (room1 == room2) return null;
    
    final walls1 = room1.getWallSegments();
    final walls2 = room2.getWallSegments();
    
    double bestDistance = double.infinity;
    Offset bestOffset = Offset.zero;
    int bestWallIndex1 = -1;
    int bestWallIndex2 = -1;
    
    // Check all wall pairs
    for (int i = 0; i < walls1.length; i++) {
      for (int j = 0; j < walls2.length; j++) {
        if (areWallsParallel(walls1[i], walls2[j])) {
          final alignmentOffset = getWallAlignmentOffset(walls1[i], walls2[j]);
          final distance = alignmentOffset.distance;
          
          if (distance < bestDistance && distance <= snapDistance) {
            bestDistance = distance;
            bestOffset = alignmentOffset;
            bestWallIndex1 = i;
            bestWallIndex2 = j;
          }
        }
      }
    }
    
    if (bestWallIndex1 >= 0 && bestWallIndex2 >= 0) {
      return (bestOffset, bestWallIndex1, bestWallIndex2);
    }
    
    return null;
  }
  
  // Find possible wall alignments with other rooms
  static List<(Offset, Room, int, int)> findAllPossibleWallAlignments(
      Room room, List<Room> otherRooms, double snapDistance) {
    final List<(Offset, Room, int, int)> alignments = [];
    
    for (var otherRoom in otherRooms) {
      if (otherRoom == room) continue;
      
      final alignment = findBestWallAlignment(room, otherRoom, snapDistance);
      if (alignment != null) {
        alignments.add((alignment.$1, otherRoom, alignment.$2, alignment.$3));
      }
    }
    
    // Sort by distance (closest first)
    alignments.sort((a, b) => a.$1.distance.compareTo(b.$1.distance));
    
    return alignments;
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
  static (Offset, double, (Offset, Offset), Room)? findClosestMidpoint(
      Offset point, List<Room> rooms, double snapDistance) {
    Offset closestPoint = point;
    double minDistance = double.infinity;
    (Offset, Offset) closestWall = (Offset.zero, Offset.zero);
    Room? closestRoom;
    
    for (var room in rooms) {
      final walls = room.getWallSegments();
      
      for (int i = 0; i < walls.length; i++) {
        final midpoint = Offset(
          (walls[i].$1.dx + walls[i].$2.dx) / 2,
          (walls[i].$1.dy + walls[i].$2.dy) / 2,
        );
        
        final distance = (point - midpoint).distance;
        if (distance < minDistance && distance <= snapDistance) {
          minDistance = distance;
          closestPoint = midpoint;
          closestWall = walls[i];
          closestRoom = room;
        }
      }
    }
    
    return (minDistance < snapDistance && closestRoom != null) 
        ? (closestPoint, minDistance, closestWall, closestRoom) 
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
        final wallNormal = Offset(
          wallVector.dx / wallLength,
          wallVector.dy / wallLength
        );
        
        // Vector from start to point
        final pointVector = point - start;
        
        // Project pointVector onto wallVector
        final projection = pointVector.dx * wallNormal.dx + pointVector.dy * wallNormal.dy;
        
        // Clamp projection to wall length
        final clampedProjection = projection.clamp(0.0, wallLength);
        
        // Calculate closest point on wall
        final pointOnWall = start + Offset(
          wallNormal.dx * clampedProjection,
          wallNormal.dy * clampedProjection
        );
        
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
  
  // Get area in square meters
  double getArea(double gridSize, double gridRealSize) {
    return width * height * (gridRealSize / gridSize) * (gridRealSize / gridSize);
  }
  
  // Get perimeter in meters
  double getPerimeter(double gridSize, double gridRealSize) {
    // Calculate perimeter excluding shared walls
    double perimeter = 0;
    final walls = getWallSegments();
    
    for (int i = 0; i < walls.length; i++) {
      if (!isWallShared(i)) {
        // Only count non-shared walls
        final wallLength = (walls[i].$2 - walls[i].$1).distance;
        perimeter += wallLength;
      }
    }
    
    return perimeter * (gridRealSize / gridSize);
  }
}
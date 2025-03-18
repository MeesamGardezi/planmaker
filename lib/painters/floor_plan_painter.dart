import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/room.dart';
import '../models/element.dart';
import '../models/enums.dart';
import '../utils/measurement_utils.dart';

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final ArchitecturalElement? selectedElement;
  final Room? selectedRoom;
  final double gridSize;
  final double gridRealSize;
  final MeasurementUnit unit;
  final bool showGrid;
  final bool showMeasurements;
  final double wallThickness;
  final bool isDragging;
  final double cornerSnapDistance;
  final bool enableGridSnap;

  FloorPlanPainter({
    required this.rooms,
    this.selectedElement,
    this.selectedRoom,
    required this.gridSize,
    required this.gridRealSize,
    required this.unit,
    this.showGrid = true,
    this.showMeasurements = true,
    this.wallThickness = 4.0,
    this.isDragging = false,
    this.cornerSnapDistance = 25.0,
    this.enableGridSnap = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _drawGrid(canvas, size);
    }
    
    // Draw rooms in two passes
    // First draw room backgrounds
    for (var room in rooms) {
      _drawRoomBackground(canvas, room);
    }
    
    // Then draw walls and elements
    for (var room in rooms) {
      _drawRoomWalls(canvas, room);
      _drawRoomElements(canvas, room);
    }
    
    // Draw corner and midpoint snap points
    if (isDragging) {
      _drawSnapPoints(canvas);
    }
    
    // Draw drag and selection feedback
    if (isDragging) {
      _drawDragFeedback(canvas);
    }
    
    // Draw selected object highlights
    if (selectedRoom != null) {
      _drawSelectedRoomHighlight(canvas, selectedRoom!);
    } else if (selectedElement != null) {
      _drawSelectedElementHighlight(canvas, selectedElement!);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      // Emphasize major grid lines (every 5)
      if (x % (gridSize * 5) < 0.1) {
        gridPaint.color = Colors.grey.withOpacity(0.35);
        gridPaint.strokeWidth = 1.5;
      } else {
        gridPaint.color = Colors.grey.withOpacity(0.2);
        gridPaint.strokeWidth = 1.0;
      }
      
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
      // Emphasize major grid lines (every 5)
      if (y % (gridSize * 5) < 0.1) {
        gridPaint.color = Colors.grey.withOpacity(0.35);
        gridPaint.strokeWidth = 1.5;
      } else {
        gridPaint.color = Colors.grey.withOpacity(0.2);
        gridPaint.strokeWidth = 1.0;
      }
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }
  
  void _drawRoomBackground(Canvas canvas, Room room) {
    // Use a rectangle for the room background
    final rect = room.rect;
    
    // Fill with room color
    final fillPaint = Paint()
      ..color = room.selected ? room.color.withOpacity(0.85) : room.color.withOpacity(0.7);
    
    canvas.drawRect(rect, fillPaint);
    
    // Draw room name if showing measurements
    if (showMeasurements) {
      _drawRoomName(canvas, room);
    }
  }
  
  void _drawRoomName(Canvas canvas, Room room) {
    final textSpan = TextSpan(
      text: room.name,
      style: TextStyle(
        color: Colors.black87,
        fontSize: room.selected ? 15 : 14,
        fontWeight: room.selected ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Position text in center of room
    textPainter.paint(
      canvas,
      Offset(
        room.position.dx - textPainter.width / 2,
        room.position.dy - textPainter.height / 2,
      ),
    );
  }
  
  void _drawRoomWalls(Canvas canvas, Room room) {
    final wallSegments = room.getWallSegments();
    final isSelected = room == selectedRoom;
    
    final wallPaint = Paint()
      ..color = isSelected ? Colors.blue.shade800 : Colors.black87
      ..strokeWidth = wallThickness
      ..strokeCap = StrokeCap.butt;
    
    for (var segment in wallSegments) {
      final start = segment.$1;
      final end = segment.$2;
      
      // Draw wall line
      canvas.drawLine(start, end, wallPaint);
      
      // Draw wall measurement if enabled
      if (showMeasurements) {
        _drawWallMeasurement(canvas, start, end);
      }
    }
  }
  
  void _drawWallMeasurement(Canvas canvas, Offset start, Offset end) {
    // Calculate wall length
    final length = (end - start).distance;
    final realLength = length * gridRealSize / gridSize;
    final formattedLength = MeasurementUtils.formatLength(realLength, unit);
    
    // Create text
    final textSpan = TextSpan(
      text: formattedLength,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 10,
        backgroundColor: Colors.white70,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Position at midpoint of wall
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    
    textPainter.paint(
      canvas,
      Offset(
        midX - textPainter.width / 2,
        midY - textPainter.height / 2,
      ),
    );
  }
  
  void _drawRoomElements(Canvas canvas, Room room) {
    for (var element in room.elements) {
      // Save canvas state to handle rotation
      canvas.save();
      
      // Translate to element position and apply rotation
      canvas.translate(element.position.dx, element.position.dy);
      canvas.rotate(element.rotation);
      
      // Determine element style
      final paint = Paint()
        ..color = element.isSelected ? Colors.blue.shade700 : Colors.black87
        ..strokeWidth = element.isSelected ? 2.0 : 1.5
        ..style = PaintingStyle.stroke;
      
      // Draw appropriate element type
      if (element.type == ElementType.door) {
        _drawDoor(canvas, element, paint);
      } else if (element.type == ElementType.window) {
        _drawWindow(canvas, element, paint);
      }
      
      // Restore canvas state
      canvas.restore();
    }
  }
  
  void _drawDoor(Canvas canvas, ArchitecturalElement element, Paint paint) {
    // Draw door opening (two vertical lines)
    canvas.drawLine(
      Offset(-element.width / 2, -element.height / 2),
      Offset(-element.width / 2, element.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(element.width / 2, -element.height / 2),
      Offset(element.width / 2, element.height / 2),
      paint,
    );
    
    // Draw door arc
    final arcRect = Rect.fromCenter(
      center: Offset(-element.width / 2, 0),
      width: element.width,
      height: element.width,
    );
    canvas.drawArc(arcRect, -math.pi / 2, math.pi / 2, false, paint);
    
    // Draw door connecting line
    canvas.drawLine(
      Offset(-element.width / 2, 0),
      Offset(element.width / 2, 0),
      paint,
    );
    
    // Draw label if selected
    if (element.isSelected && element.name != null) {
      final textSpan = TextSpan(
        text: element.name!,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 10,
          backgroundColor: Colors.white70,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, element.width / 2 + 5),
      );
    }
  }
  
  void _drawWindow(Canvas canvas, ArchitecturalElement element, Paint paint) {
    // Draw window frame
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: element.width,
        height: element.height,
      ),
      paint,
    );
    
    // Draw window mullions (cross bars)
    canvas.drawLine(
      Offset(-element.width / 2, 0),
      Offset(element.width / 2, 0),
      paint,
    );
    
    // Draw label if selected
    if (element.isSelected && element.name != null) {
      final textSpan = TextSpan(
        text: element.name!,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 10,
          backgroundColor: Colors.white70,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, element.height / 2 + 5),
      );
    }
  }
  
  // Draw corner and midpoint snap points
  void _drawSnapPoints(Canvas canvas) {
    if (!enableGridSnap) {
      final cornerPaint = Paint()
        ..color = Colors.orange.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      // Draw room corners as potential snap points
      for (var room in rooms) {
        // Skip the currently dragged room
        if (room == selectedRoom && room.isDragging) continue;
        
        final corners = room.getCorners();
        
        for (var corner in corners) {
          canvas.drawCircle(corner, 4.0, cornerPaint);
        }
        
        // Also draw midpoints on walls
        final segments = room.getWallSegments();
        for (var segment in segments) {
          final midpoint = Offset(
            (segment.$1.dx + segment.$2.dx) / 2,
            (segment.$1.dy + segment.$2.dy) / 2,
          );
          
          canvas.drawCircle(midpoint, 3.0, cornerPaint);
        }
      }
    } else if (isDragging) {
      // When grid snapping is enabled and something is being dragged,
      // highlight the nearest grid intersection
      Offset? position;
      
      if (selectedRoom != null && selectedRoom!.isDragging) {
        position = selectedRoom!.position;
      } else if (selectedElement != null && selectedElement!.isDragging) {
        position = selectedElement!.position;
      }
      
      if (position != null) {
        // Calculate nearest grid point
        final gridX = (position.dx / gridSize).round() * gridSize;
        final gridY = (position.dy / gridSize).round() * gridSize;
        final gridPoint = Offset(gridX, gridY);
        
        // Draw grid snap indicator
        final gridSnapPaint = Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
          
        canvas.drawCircle(gridPoint, 6.0, gridSnapPaint);
        
        // Draw crosshairs
        canvas.drawLine(
          Offset(gridX - 10, gridY),
          Offset(gridX + 10, gridY),
          gridSnapPaint
        );
        
        canvas.drawLine(
          Offset(gridX, gridY - 10),
          Offset(gridX, gridY + 10),
          gridSnapPaint
        );
      }
    }
  }
  
  // Draw visual feedback for dragging operations
  void _drawDragFeedback(Canvas canvas) {
    if (selectedRoom != null && selectedRoom!.isDragging) {
      // Draw drag guidelines for room
      _drawDraggingRoomGuidelines(canvas, selectedRoom!);
    } else if (selectedElement != null && selectedElement!.isDragging) {
      // Draw drag guidelines for element
      _drawDraggingElementGuidelines(canvas, selectedElement!);
    }
  }
  
  // Draw guidelines for room dragging with appropriate snapping
  void _drawDraggingRoomGuidelines(Canvas canvas, Room room) {
    if (enableGridSnap) {
      // Draw grid snapping guidelines
      // Calculate nearest grid point
      final gridX = (room.position.dx / gridSize).round() * gridSize;
      final gridY = (room.position.dy / gridSize).round() * gridSize;
      final snappedPos = Offset(gridX, gridY);
      
      // Draw grid snap preview
      final snapPreviewRect = Rect.fromCenter(
        center: snappedPos,
        width: room.width,
        height: room.height,
      );
      
      final snapPreviewPaint = Paint()
        ..color = Colors.green.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(snapPreviewRect, snapPreviewPaint);
      
      // Draw the room outline
      final outlinePaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawRect(snapPreviewRect, outlinePaint);
      
      // Draw grid coordinate text
      final coordText = "Grid: (${(gridX / gridSize).round()}, ${(gridY / gridSize).round()})";
      final textSpan = TextSpan(
        text: coordText,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white70,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          snappedPos.dx - textPainter.width / 2,
          snappedPos.dy - room.height / 2 - 30,
        ),
      );
    } else {
      // Draw corner snapping guidelines
      // Find rooms to exclude from snapping (don't snap to self)
      final otherRooms = rooms.where((r) => r != room).toList();
      
      // Determine if room should snap to any corners
      final cornerResult = Room.findClosestCorner(room.position, otherRooms, cornerSnapDistance);
      
      if (cornerResult != null) {
        final snappedPos = cornerResult.$1;
        final distance = cornerResult.$2;
        final cornerIndex = cornerResult.$3;
        final targetRoom = cornerResult.$4;
        
        // Draw snap indicator
        final snapHighlightPaint = Paint()
          ..color = Colors.green
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        
        // Highlight the corner we're snapping to
        canvas.drawCircle(snappedPos, 8.0, snapHighlightPaint);
        
        // Draw a line to show the corner name
        final cornerNames = targetRoom.getCornerDescriptions();
        final cornerName = cornerNames[cornerIndex];
        
        final textSpan = TextSpan(
          text: cornerName,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white70,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            snappedPos.dx - textPainter.width / 2,
            snappedPos.dy - 25,
          ),
        );
        
        // Draw arrow indicating snap direction
        _drawSnapArrow(canvas, room.position, snappedPos);
        
        // Draw where it will snap to
        final snapPreviewRect = Rect.fromCenter(
          center: snappedPos,
          width: room.width,
          height: room.height,
        );
        
        final snapPreviewPaint = Paint()
          ..color = Colors.green.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(snapPreviewRect, snapPreviewPaint);
        
        // Draw snapped position text
        final snapText = "Snap: ${distance.toStringAsFixed(1)}px";
        final snapSpan = TextSpan(
          text: snapText,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white70,
          ),
        );
        
        final snapTextPainter = TextPainter(
          text: snapSpan,
          textDirection: TextDirection.ltr,
        );
        
        snapTextPainter.layout();
        snapTextPainter.paint(
          canvas,
          Offset(
            snappedPos.dx + 15,
            snappedPos.dy + 15,
          ),
        );
      } else {
        // Not snapping to any corner - show current position
        // Display current position coordinates
        final posText = "(${room.position.dx.toStringAsFixed(1)}, "
            "${room.position.dy.toStringAsFixed(1)})";
        
        final textSpan = TextSpan(
          text: posText,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 10,
            backgroundColor: Colors.white70,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            room.position.dx + 10,
            room.position.dy - 20,
          ),
        );
      }
    }
  }
  
  // Draw guidelines for element dragging
  void _drawDraggingElementGuidelines(Canvas canvas, ArchitecturalElement element) {
    if (enableGridSnap) {
      // Draw grid snapping guidelines
      // Calculate nearest grid point
      final gridX = (element.position.dx / gridSize).round() * gridSize;
      final gridY = (element.position.dy / gridSize).round() * gridSize;
      final snappedPos = Offset(gridX, gridY);
      
      // Draw grid snap indicator
      final gridSnapPaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2.0;
      
      // Draw a grid snap indicator
      canvas.save();
      canvas.translate(snappedPos.dx, snappedPos.dy);
      
      // Draw element preview at the grid point
      final previewPaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      // Draw simple element preview
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: element.width,
          height: element.height,
        ),
        previewPaint,
      );
      
      canvas.restore();
      
      // Draw position text
      final posText = "Grid: (${(gridX / gridSize).round()}, ${(gridY / gridSize).round()})";
      final textSpan = TextSpan(
        text: posText,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white70,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          snappedPos.dx + 15,
          snappedPos.dy - 25,
        ),
      );
    } else {
      // Try to find closest corner
      final cornerResult = ArchitecturalElement.findClosestCorner(element.position, rooms, cornerSnapDistance);
      
      if (cornerResult != null) {
        final cornerPos = cornerResult.$1;
        final room = cornerResult.$2;
        final cornerIndex = cornerResult.$3;
        final distance = cornerResult.$4;
        
        // Draw snap indicator
        final snapHighlightPaint = Paint()
          ..color = Colors.green
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        
        // Highlight the corner we're snapping to
        canvas.drawCircle(cornerPos, 8.0, snapHighlightPaint);
        
        // Draw a line to show the corner name
        final cornerNames = room.getCornerDescriptions();
        final cornerName = cornerNames[cornerIndex];
        
        final textSpan = TextSpan(
          text: cornerName,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white70,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            cornerPos.dx - textPainter.width / 2,
            cornerPos.dy - 25,
          ),
        );
        
        // Draw arrow indicating snap direction
        _drawSnapArrow(canvas, element.position, cornerPos);
        
        // Draw element preview at corner
        _drawElementCornerPreview(canvas, element, cornerPos, cornerIndex);
        
        // Draw snapped position text
        final snapText = "Snap: ${distance.toStringAsFixed(1)}px";
        final snapSpan = TextSpan(
          text: snapText,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white70,
          ),
        );
        
        final snapTextPainter = TextPainter(
          text: snapSpan,
          textDirection: TextDirection.ltr,
        );
        
        snapTextPainter.layout();
        snapTextPainter.paint(
          canvas,
          Offset(
            cornerPos.dx + 15,
            cornerPos.dy + 15,
          ),
        );
      } else {
        // Try midpoint snapping
        final midpointResult = Room.findClosestMidpoint(element.position, rooms, cornerSnapDistance);
        
        if (midpointResult != null) {
          final midpointPos = midpointResult.$1;
          final distance = midpointResult.$2;
          
          // Find which wall this midpoint belongs to
          for (var room in rooms) {
            for (var wallSegment in room.getWallSegments()) {
              final wallMidpoint = Offset(
                (wallSegment.$1.dx + wallSegment.$2.dx) / 2,
                (wallSegment.$1.dy + wallSegment.$2.dy) / 2,
              );
              
              if ((wallMidpoint - midpointPos).distanceSquared < 1.0) {
                // Draw snap indicator
                final snapHighlightPaint = Paint()
                  ..color = Colors.green
                  ..strokeWidth = 3.0
                  ..style = PaintingStyle.stroke;
                
                // Highlight the midpoint we're snapping to
                canvas.drawCircle(midpointPos, 6.0, snapHighlightPaint);
                
                // Draw arrow indicating snap direction
                _drawSnapArrow(canvas, element.position, midpointPos);
                
                // Draw element preview at midpoint
                _drawElementMidpointPreview(canvas, element, midpointPos, wallSegment);
                
                // Draw snapped position text
                final snapText = "Wall Midpoint: ${distance.toStringAsFixed(1)}px";
                final snapSpan = TextSpan(
                  text: snapText,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.white70,
                  ),
                );
                
                final snapTextPainter = TextPainter(
                  text: snapSpan,
                  textDirection: TextDirection.ltr,
                );
                
                snapTextPainter.layout();
                snapTextPainter.paint(
                  canvas,
                  Offset(
                    midpointPos.dx + 15,
                    midpointPos.dy + 15,
                  ),
                );
                
                break;
              }
            }
          }
        } else {
          // Not snapping to any point - show current position
          final posText = "(${element.position.dx.toStringAsFixed(1)}, "
              "${element.position.dy.toStringAsFixed(1)})";
          
          final textSpan = TextSpan(
            text: posText,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 10,
              backgroundColor: Colors.white70,
            ),
          );
          
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              element.position.dx + 10,
              element.position.dy - 20,
            ),
          );
        }
      }
    }
  }
  
  // Draw preview of element at corner
  void _drawElementCornerPreview(Canvas canvas, ArchitecturalElement element, 
                              Offset cornerPos, int cornerIndex) {
    canvas.save();
    
    // Calculate angle based on corner
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
    
    // Calculate adjusted position (offset from corner)
    final offsetDistance = element.width / 4;
    final adjustedPos = Offset(
      cornerPos.dx + math.cos(angle) * offsetDistance,
      cornerPos.dy + math.sin(angle) * offsetDistance
    );
    
    // Translate to position and apply rotation
    canvas.translate(adjustedPos.dx, adjustedPos.dy);
    canvas.rotate(angle);
    
    // Draw element preview
    final previewPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    if (element.type == ElementType.door) {
      // Simplified door preview
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: element.width,
          height: element.height,
        ),
        previewPaint,
      );
      
      // Door arc hint
      final arcRect = Rect.fromCenter(
        center: Offset(-element.width / 4, 0),
        width: element.width / 2,
        height: element.width / 2,
      );
      canvas.drawArc(arcRect, -math.pi / 2, math.pi / 2, false, previewPaint);
    } else if (element.type == ElementType.window) {
      // Window preview
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: element.width,
          height: element.height,
        ),
        previewPaint,
      );
    }
    
    // Restore canvas state
    canvas.restore();
  }
  
  // Draw preview of element at wall midpoint
  void _drawElementMidpointPreview(Canvas canvas, ArchitecturalElement element, 
                             Offset midpointPos, (Offset, Offset) wallSegment) {
    canvas.save();
    
    // Calculate wall angle
    final start = wallSegment.$1;
    final end = wallSegment.$2;
    
    final wallAngle = math.atan2(
      end.dy - start.dy,
      end.dx - start.dx,
    );
    
    // Calculate adjusted position (offset perpendicular to wall)
    final perpAngle = wallAngle + math.pi / 2;
    final offsetDistance = element.height / 2;
    final adjustedPos = Offset(
      midpointPos.dx + math.cos(perpAngle) * offsetDistance,
      midpointPos.dy + math.sin(perpAngle) * offsetDistance
    );
    
    // Translate to position and apply rotation
    canvas.translate(adjustedPos.dx, adjustedPos.dy);
    canvas.rotate(wallAngle);
    
    // Draw element preview
    final previewPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    if (element.type == ElementType.door) {
      // Simplified door preview
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: element.width,
          height: element.height,
        ),
        previewPaint,
      );
      
      // Door arc hint
      final arcRect = Rect.fromCenter(
        center: Offset(-element.width / 4, 0),
        width: element.width / 2,
        height: element.width / 2,
      );
      canvas.drawArc(arcRect, -math.pi / 2, math.pi / 2, false, previewPaint);
    } else if (element.type == ElementType.window) {
      // Window preview
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: element.width,
          height: element.height,
        ),
        previewPaint,
      );
    }
    
    // Restore canvas state
    canvas.restore();
  }
  
  // Draw an arrow indicating snap direction
  void _drawSnapArrow(Canvas canvas, Offset from, Offset to) {
    // Calculate distance and direction
    final delta = to - from;
    final distance = delta.distance;
    
    if (distance < 1.0) return; // Skip if positions are too close
    
    final direction = delta / distance;
    
    // Draw arrow line
    final arrowPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(from, to, arrowPaint);
    
    // Draw arrow head
    final arrowHeadSize = 8.0;
    final arrowHeadPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    // Calculate arrow head points
    final perpDirection = Offset(-direction.dy, direction.dx);
    
    final arrowPoint1 = to - direction * arrowHeadSize + perpDirection * arrowHeadSize / 2;
    final arrowPoint2 = to - direction * arrowHeadSize - perpDirection * arrowHeadSize / 2;
    
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();
    
    canvas.drawPath(path, arrowHeadPaint);
  }
  
  // Draw highlight for selected room
  void _drawSelectedRoomHighlight(Canvas canvas, Room room) {
    // Draw selection outline
    final selectionRect = room.selectionRect;
    
    final selectionPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(selectionRect, selectionPaint);
    
    // Draw selection handles at corners
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    for (var corner in room.getCorners()) {
      canvas.drawCircle(corner, 6.0, cornerPaint);
    }
    
    // Draw dimensions if room is selected
    if (showMeasurements) {
      final width = room.width * gridRealSize / gridSize;
      final height = room.height * gridRealSize / gridSize;
      
      final widthText = MeasurementUtils.formatLength(width, unit);
      final heightText = MeasurementUtils.formatLength(height, unit);
      
      // Draw width dimension text
      final widthTextSpan = TextSpan(
        text: widthText,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white70,
        ),
      );

      final widthTextPainter = TextPainter(
        text: widthTextSpan,
        textDirection: TextDirection.ltr,
      );

      widthTextPainter.layout();
      widthTextPainter.paint(
        canvas,
        Offset(
          room.position.dx - widthTextPainter.width / 2,
          room.position.dy - room.height / 2 - 20,
        ),
      );
      
      // Draw height dimension text
      final heightTextSpan = TextSpan(
        text: heightText,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white70,
        ),
      );

      final heightTextPainter = TextPainter(
        text: heightTextSpan,
        textDirection: TextDirection.ltr,
      );

      heightTextPainter.layout();
      heightTextPainter.paint(
        canvas,
        Offset(
          room.position.dx + room.width / 2 + 10,
          room.position.dy - heightTextPainter.width / 2,
        ),
      );
    }
  }
  
  // Draw highlight for selected element
  void _drawSelectedElementHighlight(Canvas canvas, ArchitecturalElement element) {
    canvas.save();
    
    // Translate to element position and apply rotation
    canvas.translate(element.position.dx, element.position.dy);
    canvas.rotate(element.rotation);
    
    // Draw selection outline
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: element.width + 10,
      height: element.height + 10,
    );
    
    final selectionPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(rect, selectionPaint);
    
    // Draw corner handles
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    final halfWidth = element.width / 2 + 5;
    final halfHeight = element.height / 2 + 5;
    
    canvas.drawCircle(Offset(-halfWidth, -halfHeight), 4, handlePaint);
    canvas.drawCircle(Offset(halfWidth, -halfHeight), 4, handlePaint);
    canvas.drawCircle(Offset(halfWidth, halfHeight), 4, handlePaint);
    canvas.drawCircle(Offset(-halfWidth, halfHeight), 4, handlePaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.rooms != rooms ||
        oldDelegate.selectedElement != selectedElement ||
        oldDelegate.selectedRoom != selectedRoom ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showMeasurements != showMeasurements ||
        oldDelegate.wallThickness != wallThickness ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.cornerSnapDistance != cornerSnapDistance ||
        oldDelegate.enableGridSnap != enableGridSnap;
  }
}
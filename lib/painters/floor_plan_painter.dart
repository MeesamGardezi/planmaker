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
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
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
      ..color = room.selected ? room.color.withOpacity(0.7) : room.color;
    
    canvas.drawRect(rect, fillPaint);
    
    // Draw room name if showing measurements
    if (showMeasurements) {
      _drawRoomName(canvas, room);
    }
  }
  
  void _drawRoomName(Canvas canvas, Room room) {
    final textSpan = TextSpan(
      text: room.name,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.bold,
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
    
    for (var segment in wallSegments) {
      final start = segment.$1;
      final end = segment.$2;
      
      // Determine wall style
      final paint = Paint()
        ..color = (room == selectedRoom) ? Colors.blue : Colors.black
        ..strokeWidth = wallThickness
        ..strokeCap = StrokeCap.butt;
      
      // Draw wall line
      canvas.drawLine(start, end, paint);
      
      // Draw wall measurement if enabled
      if (showMeasurements) {
        _drawWallMeasurement(canvas, start, end);
      }
    }
    
    // Draw corner handles if room is selected
    if (room == selectedRoom) {
      final points = room.getWallPoints();
      final handlePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.0
        ..style = PaintingStyle.fill;
      
      for (var point in points) {
        canvas.drawCircle(point, 6.0, handlePaint);
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
        ..color = (element == selectedElement) ? Colors.blue : Colors.black
        ..strokeWidth = (element == selectedElement) ? 2.0 : 1.5
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
    if (element == selectedElement && element.name != null) {
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
    if (element == selectedElement && element.name != null) {
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

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/measurements.dart';
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
  final double snapDistance;
  final bool enableGridSnap;
  final SnapType currentSnapType;
  final Room? targetSnapRoom;
  final int? sourceWallIndex;
  final int? targetWallIndex;
  final List<Measurement> measurements;
  final Measurement? activeMeasurement;
  final bool isDrawingLine;
  final Offset? lineStart;
  final Offset? lineEnd;

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
    this.snapDistance = 25.0,
    this.enableGridSnap = false,
    this.currentSnapType = SnapType.none,
    this.targetSnapRoom,
    this.sourceWallIndex,
    this.targetWallIndex,
    this.measurements = const [],
    this.activeMeasurement,
    this.isDrawingLine = false,
    this.lineStart,
    this.lineEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // First draw room backgrounds for all rooms
    for (var room in rooms) {
      _drawRoomBackground(canvas, room);
    }

    // Draw walls
    for (var room in rooms) {
      _drawRoomWalls(canvas, room);
    }

    // Draw elements
    for (var room in rooms) {
      _drawRoomElements(canvas, room);
    }

    // Draw measurements
    _drawMeasurements(canvas);

    // Draw temporary line during drawing
    _drawTemporaryLine(canvas);

    // Draw snap points and visual feedback when dragging
    if (isDragging) {
      _drawSnapPoints(canvas);
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

  void _drawLine(Canvas canvas, ArchitecturalElement element, Paint paint) {
    if (element.startPoint != null && element.endPoint != null) {
      // Draw the line from start to end
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
          Offset(-textPainter.width / 2, 10),
        );
      }
    } else {
      // Fallback - draw a simple line based on element width
      canvas.drawLine(
        Offset(-element.width / 2, 0),
        Offset(element.width / 2, 0),
        paint,
      );
    }
  }

  void _drawRoomBackground(Canvas canvas, Room room) {
    // Use a rectangle for the room background
    final rect = room.rect;

    // Fill with room color
    final fillPaint = Paint()
      ..color = room.selected
          ? room.color.withOpacity(0.85)
          : room.color.withOpacity(0.7);

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

  void _drawWallMeasurement(Canvas canvas, Offset start, Offset end) {
    // Calculate wall length in pixels
    final length = (end - start).distance;

    // Convert directly to the current unit system (e.g., feet)
    final realLength = length * gridRealSize / gridSize;

    // Format using the improved util method that doesn't double-convert
    final formattedLength =
        MeasurementUtils.formatLengthInUnit(realLength, unit);

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
      } else if (element.type == ElementType.line) {
        _drawLine(canvas, element, paint);
      }

      // Restore canvas state
      canvas.restore();
    }
  }

  void _drawTemporaryLine(Canvas canvas) {
    if (isDrawingLine && lineStart != null && lineEnd != null) {
      final linePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(lineStart!, lineEnd!, linePaint);
    }
  }

  void _drawMeasurements(Canvas canvas) {
    final measurementPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw saved measurements
    for (var measurement in measurements) {
      // Draw the measurement line
      canvas.drawLine(measurement.start, measurement.end, measurementPaint);

      // Draw the length text
      final realLength = measurement.measuredLength * gridRealSize / gridSize;
      final formattedLength =
          MeasurementUtils.formatLengthInUnit(realLength, unit);

      final textSpan = TextSpan(
        text: formattedLength,
        style: const TextStyle(
          color: Colors.purple,
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
          measurement.midpoint.dx - textPainter.width / 2,
          measurement.midpoint.dy - textPainter.height / 2,
        ),
      );
    }

    // Draw active measurement if any
    if (activeMeasurement != null) {
      // Draw the measurement line
      canvas.drawLine(
        activeMeasurement!.start,
        activeMeasurement!.end,
        measurementPaint..color = Colors.purple.withOpacity(0.7),
      );

      // Draw the length text if the line has meaningful length
      if ((activeMeasurement!.end - activeMeasurement!.start).distance > 5) {
        final realLength =
            activeMeasurement!.measuredLength * gridRealSize / gridSize;
        final formattedLength =
            MeasurementUtils.formatLengthInUnit(realLength, unit);

        final textSpan = TextSpan(
          text: formattedLength,
          style: const TextStyle(
            color: Colors.purple,
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
            activeMeasurement!.midpoint.dx - textPainter.width / 2,
            activeMeasurement!.midpoint.dy - textPainter.height / 2,
          ),
        );
      }
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

  // Draw snap points and potential connection points
  void _drawSnapPoints(Canvas canvas) {
    if (!isDragging) return;

    final snapPointPaint = Paint()
      ..color = Colors.orange.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw wall midpoints and corners for all rooms
    for (var room in rooms) {
      // Skip the currently dragged room
      if (room == selectedRoom && selectedRoom!.isDragging) continue;

      // Draw potential snap points
      final wallSegments = room.getWallSegments();

      // Draw walls with faint highlight to indicate snap targets
      final wallHighlightPaint = Paint()
        ..color = Colors.orange.withOpacity(0.2)
        ..strokeWidth = wallThickness * 1.2
        ..strokeCap = StrokeCap.butt;

      for (int i = 0; i < wallSegments.length; i++) {
        final wall = wallSegments[i];
        canvas.drawLine(wall.$1, wall.$2, wallHighlightPaint);

        // Draw midpoint
        final midpoint = Offset(
            (wall.$1.dx + wall.$2.dx) / 2, (wall.$1.dy + wall.$2.dy) / 2);

        canvas.drawCircle(midpoint, 3.0, snapPointPaint);
      }

      // Draw corners
      final corners = room.getCorners();
      for (var corner in corners) {
        canvas.drawCircle(corner, 5.0, snapPointPaint);
      }
    }

    // Draw specific feedback for current snap type
    if (currentSnapType == SnapType.wall &&
        selectedRoom != null &&
        targetSnapRoom != null &&
        sourceWallIndex != null &&
        targetWallIndex != null) {
      _drawWallSnapHighlight(canvas);
    }
  }

  // Draw visual feedback for wall snap
  void _drawWallSnapHighlight(Canvas canvas) {
    if (selectedRoom == null ||
        targetSnapRoom == null ||
        sourceWallIndex == null ||
        targetWallIndex == null) return;

    final sourceWalls = selectedRoom!.getWallSegments();
    final targetWalls = targetSnapRoom!.getWallSegments();

    if (sourceWallIndex! >= sourceWalls.length ||
        targetWallIndex! >= targetWalls.length) return;

    final sourceWall = sourceWalls[sourceWallIndex!];
    final targetWall = targetWalls[targetWallIndex!];

    // Draw highlighted walls
    final highlightPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = wallThickness * 1.5
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(sourceWall.$1, sourceWall.$2, highlightPaint);
    canvas.drawLine(targetWall.$1, targetWall.$2, highlightPaint);

    // Calculate midpoints
    final sourceMid = Offset((sourceWall.$1.dx + sourceWall.$2.dx) / 2,
        (sourceWall.$1.dy + sourceWall.$2.dy) / 2);

    final targetMid = Offset((targetWall.$1.dx + targetWall.$2.dx) / 2,
        (targetWall.$1.dy + targetWall.$2.dy) / 2);

    // Draw connecting line
    _drawSnapArrow(canvas, sourceMid, targetMid);

    // Draw alignment text
    final textSpan = TextSpan(
      text: "Wall Alignment",
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
        (sourceMid.dx + targetMid.dx) / 2 - textPainter.width / 2,
        (sourceMid.dy + targetMid.dy) / 2 - 20,
      ),
    );
  }

  // Draw visual feedback for dragging operations
  void _drawDragFeedback(Canvas canvas) {
    if (selectedRoom != null && selectedRoom!.isDragging) {
      // Display current snap type
      _drawSnapTypeIndicator(canvas, selectedRoom!);
    } else if (selectedElement != null && selectedElement!.isDragging) {
      // Draw element drag guidelines
      _drawDraggingElementGuidelines(canvas, selectedElement!);
    }
  }

  // Draw snap type indicator
  void _drawSnapTypeIndicator(Canvas canvas, Room room) {
    if (currentSnapType == SnapType.none) {
      // Draw current position
      final posText =
          "(${room.position.dx.toStringAsFixed(1)}, ${room.position.dy.toStringAsFixed(1)})";
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
          room.position.dx - textPainter.width / 2,
          room.position.dy - room.height / 2 - 20,
        ),
      );
      return;
    }

    // Determine color and text based on snap type
    Color indicatorColor;
    String indicatorText;

    switch (currentSnapType) {
      case SnapType.corner:
        indicatorColor = Colors.blue;
        indicatorText = "Corner Snap";
        break;
      case SnapType.wall:
        indicatorColor = Colors.green;
        indicatorText = "Wall Snap";
        break;
      default:
        indicatorColor = Colors.grey;
        indicatorText = "Free Move";
    }

    // Draw snap indicator text
    final textSpan = TextSpan(
      text: indicatorText,
      style: TextStyle(
        color: indicatorColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white.withOpacity(0.7),
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
        room.position.dx - textPainter.width / 2,
        room.position.dy - room.height / 2 - 30,
      ),
    );

    // Draw snap details
    if (currentSnapType == SnapType.wall &&
        targetSnapRoom != null &&
        sourceWallIndex != null &&
        targetWallIndex != null) {
      final detailsSpan = TextSpan(
        text:
            "${selectedRoom!.getWallDescriptions()[sourceWallIndex!]} ↔ ${targetSnapRoom!.getWallDescriptions()[targetWallIndex!]}",
        style: TextStyle(
          color: indicatorColor,
          fontSize: 12,
          fontStyle: FontStyle.italic,
          backgroundColor: Colors.white.withOpacity(0.7),
        ),
      );

      final detailsPainter = TextPainter(
        text: detailsSpan,
        textDirection: TextDirection.ltr,
      );

      detailsPainter.layout();
      detailsPainter.paint(
        canvas,
        Offset(
          room.position.dx - detailsPainter.width / 2,
          room.position.dy - room.height / 2 - 10,
        ),
      );
    }
  }

  // Draw guidelines for element dragging
  void _drawDraggingElementGuidelines(
      Canvas canvas, ArchitecturalElement element) {
    if (currentSnapType == SnapType.none) {
      // Show current position when not snapping
      final posText =
          "(${element.position.dx.toStringAsFixed(1)}, ${element.position.dy.toStringAsFixed(1)})";

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
      return;
    }

    // Find closest wall or corner for visual feedback
    final wallResult =
        Room.findClosestWallPoint(element.position, rooms, snapDistance);

    if (wallResult != null && currentSnapType == SnapType.wall) {
      final snapPoint = wallResult.$1;
      final wall = wallResult.$3;

      // Highlight the closest point on wall
      final snapHighlightPaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(snapPoint, 6.0, snapHighlightPaint);

      // Draw line from element to snap point
      _drawSnapArrow(canvas, element.position, snapPoint);

      // Draw wall highlight
      final wallHighlightPaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..strokeWidth = wallThickness * 1.2
        ..strokeCap = StrokeCap.butt;

      canvas.drawLine(wall.$1, wall.$2, wallHighlightPaint);

      // Draw element preview at wall
      _drawElementWallPreview(canvas, element, snapPoint, wall);

      // Draw distance text
      final distance = wallResult.$2;
      final snapText = "Wall Snap: ${distance.toStringAsFixed(1)}px";
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
          snapPoint.dx + 15,
          snapPoint.dy + 15,
        ),
      );
    } else if (currentSnapType == SnapType.corner) {
      // Try to find closest corner
      final cornerResult =
          Room.findClosestCorner(element.position, rooms, snapDistance);

      if (cornerResult != null) {
        final cornerPos = cornerResult.$1;
        final room = cornerResult.$4;
        final cornerIndex = cornerResult.$3;

        // Highlight the corner
        final snapHighlightPaint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(cornerPos, 7.0, snapHighlightPaint);

        // Draw arrow from element to corner
        _drawSnapArrow(canvas, element.position, cornerPos);

        // Draw element preview at corner
        _drawElementCornerPreview(canvas, element, cornerPos, cornerIndex);

        // Draw corner name and distance
        final distance = cornerResult.$2;
        final cornerName = room.getCornerDescriptions()[cornerIndex];
        final snapText = "$cornerName: ${distance.toStringAsFixed(1)}px";
        final snapSpan = TextSpan(
          text: snapText,
          style: const TextStyle(
            color: Colors.blue,
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
      }
    }
  }

  // Draw preview of element at wall
  void _drawElementWallPreview(Canvas canvas, ArchitecturalElement element,
      Offset snapPoint, (Offset, Offset) wall) {
    canvas.save();

    // Calculate wall angle
    final wallVector = wall.$2 - wall.$1;
    final wallAngle = math.atan2(wallVector.dy, wallVector.dx);

    // Calculate rotation perpendicular to wall
    final rotation = wallAngle + math.pi / 2;

    // Calculate adjusted position (offset from wall)
    final perpOffset = element.height / 2;
    final adjustedPos = Offset(snapPoint.dx + math.cos(rotation) * perpOffset,
        snapPoint.dy + math.sin(rotation) * perpOffset);

    // Translate to position and apply rotation
    canvas.translate(adjustedPos.dx, adjustedPos.dy);
    canvas.rotate(rotation);

    // Draw element preview
    final previewPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (element.type == ElementType.door) {
      // Draw door frame
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

      // Add cross bar
      canvas.drawLine(
        Offset(-element.width / 2, 0),
        Offset(element.width / 2, 0),
        previewPaint,
      );
    }

    // Restore canvas state
    canvas.restore();
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
    final adjustedPos = Offset(cornerPos.dx + math.cos(angle) * offsetDistance,
        cornerPos.dy + math.sin(angle) * offsetDistance);

    // Translate to position and apply rotation
    canvas.translate(adjustedPos.dx, adjustedPos.dy);
    canvas.rotate(angle);

    // Draw element preview
    final previewPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (element.type == ElementType.door) {
      // Draw door frame
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

      // Add cross bar
      canvas.drawLine(
        Offset(-element.width / 2, 0),
        Offset(element.width / 2, 0),
        previewPaint,
      );
    }

    // Restore canvas state
    canvas.restore();
  }

  // Draw an arrow between two points
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

    final arrowPoint1 =
        to - direction * arrowHeadSize + perpDirection * arrowHeadSize / 2;
    final arrowPoint2 =
        to - direction * arrowHeadSize - perpDirection * arrowHeadSize / 2;

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

      // Use the direct formatting without double conversion
      final widthText = MeasurementUtils.formatLengthInUnit(width, unit);
      final heightText = MeasurementUtils.formatLengthInUnit(height, unit);

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
  void _drawSelectedElementHighlight(
      Canvas canvas, ArchitecturalElement element) {
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

  void _drawRoomWalls(Canvas canvas, Room room) {
    final wallSegments = room.getWallSegments();
    final wallNames = room.getWallDescriptions();
    final isSelected = room == selectedRoom;

    final wallPaint = Paint()
      ..color = isSelected ? Colors.blue.shade800 : Colors.black87
      ..strokeWidth = wallThickness
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < wallSegments.length; i++) {
      final wall = wallSegments[i];

      // Draw wall line
      canvas.drawLine(wall.$1, wall.$2, wallPaint);

      // Draw wall measurement if enabled
      if (showMeasurements) {
        _drawWallMeasurement(canvas, wall.$1, wall.$2);
      }

      // Draw wall name label when room is selected or showMeasurements is true
      if (isSelected || showMeasurements) {
        _drawWallNameLabel(canvas, wall, wallNames[i], isSelected);
      }
    }
  }

  void _drawWallNameLabel(
      Canvas canvas, (Offset, Offset) wall, String wallName, bool isSelected) {
    // Calculate midpoint of the wall
    final midX = (wall.$1.dx + wall.$2.dx) / 2;
    final midY = (wall.$1.dy + wall.$2.dy) / 2;

    // Calculate wall angle to determine text rotation
    final wallVector = wall.$2 - wall.$1;
    final wallAngle = math.atan2(wallVector.dy, wallVector.dx);

    // Determine if wall is more horizontal or vertical
    final isHorizontal = wallVector.dx.abs() > wallVector.dy.abs();

    // Create text span for wall name
    final textSpan = TextSpan(
      text: wallName,
      style: TextStyle(
        color: isSelected ? Colors.blue.shade800 : Colors.black87,
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        backgroundColor: Colors.white.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Save canvas state for rotation
    canvas.save();

    // Position and rotate text
    if (isHorizontal) {
      // Place text above horizontal walls
      canvas.translate(midX, midY - 18);

      // Handle text orientation (flip for right-to-left walls)
      if (wall.$1.dx > wall.$2.dx) {
        canvas.rotate(math.pi); // Rotate 180 degrees
      }
    } else {
      // Place text beside vertical walls
      canvas.translate(midX + 18, midY);
      canvas.rotate(math.pi / 2); // Rotate 90 degrees

      // Handle text orientation (flip for bottom-to-top walls)
      if (wall.$1.dy > wall.$2.dy) {
        canvas.rotate(math.pi); // Rotate 180 degrees
      }
    }

    // Draw text
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Restore canvas
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
        oldDelegate.snapDistance != snapDistance ||
        oldDelegate.enableGridSnap != enableGridSnap ||
        oldDelegate.currentSnapType != currentSnapType ||
        oldDelegate.targetSnapRoom != targetSnapRoom ||
        oldDelegate.sourceWallIndex != sourceWallIndex ||
        oldDelegate.targetWallIndex != targetWallIndex;
  }
}

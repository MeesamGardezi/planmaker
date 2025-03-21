// lib/screens/floor_plan_editor.dart
import 'package:flutter/material.dart';
import '../models/measurements.dart';
import '../models/room.dart';
import '../models/element.dart';
import '../models/enums.dart';
import '../painters/floor_plan_painter.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/properties_panel.dart';
import '../widgets/status_bar.dart';
import '../utils/measurement_utils.dart';
import 'dart:math' as math;

class FloorPlanEditor extends StatefulWidget {
  const FloorPlanEditor({super.key});

  @override
  FloorPlanEditorState createState() => FloorPlanEditorState();

  static State<FloorPlanEditor> of(BuildContext context) {
    return context.findAncestorStateOfType<FloorPlanEditorState>()!;
  }
}

class FloorPlanEditorState extends State<FloorPlanEditor> {
  // Lists for storing floor plan data
  final List<Room> rooms = [];

  // Editor mode and states
  EditorMode mode = EditorMode.select;
  Room? selectedRoom;
  ArchitecturalElement? selectedElement;
  String projectName = "Untitled Project";
  bool showGrid = true;
  bool showMeasurements = true;

  // Grid and measurement settings
  double gridSize = 20.0; // Fixed grid size
  double gridRealSize = 1.0;
  MeasurementUnit unit = MeasurementUnit.feet;

  // Default wall height for new rooms
  double defaultWallHeight = 8.0; // Default in feet

  // Panel states
  bool showRightPanel = false;

  // Canvas state
  final transformationController = TransformationController();
  Offset? lastGlobalPosition;
  bool isCanvasDragging = false;

  // Interaction state flags
  bool isDraggingAnyObject = false;

  // Snapping
  double snapDistance = 25.0; // Universal snap distance for all snap types
  bool enableGridSnap = false; // Always use intelligent snapping

  // Snap type tracking
  SnapType currentSnapType = SnapType.none;

  // Room counter
  int roomCounter = 1;

  // Wall thickness
  double wallThickness = 4.0;

  // Current snap information
  Room? targetSnapRoom;
  int? sourceWallIndex;
  int? targetWallIndex;

  // Line drawing state
  bool isDrawingLine = false;
  Offset? lineStart;
  Offset? lineEnd;

  // Measurement state
  List<Measurement> measurements = [];
  Measurement? activeMeasurement;

  // Colors
  final List<Color> roomColors = [
    const Color(0xFFD8E5CE), // Light green
    const Color(0xFFB3CEE1), // Light blue
    const Color(0xFFEED7D1), // Light pink
    const Color(0xFFF5E3C7), // Light yellow
    const Color(0xFFDCD2E5), // Light purple
    const Color(0xFFCEE5E3), // Light teal
    const Color(0xFFEAD1DC), // Light rose
    const Color(0xFFF0E6C2), // Light cream
  ];

  @override
  void initState() {
    super.initState();
    // Add the first room after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rooms.isEmpty) {
        _addNewRoom();
      }
    });
  }

  void _addNewRoom() {
    // Default position in the center of the view
    var position = const Offset(500, 400);

    // If there are existing rooms, offset to the right
    if (rooms.isNotEmpty) {
      final maxX = rooms.fold<double>(
          0, (max, room) => math.max(max, room.position.dx + room.width / 2));
      // Position new room to the right of existing rooms with some margin
      position = Offset(maxX + 120, position.dy);
    }

    // Create walls with default height
    List<Wall> walls = List.generate(4, (_) => Wall(height: defaultWallHeight));

    // Create new room
    final newRoom = Room(
      name: 'Room ${roomCounter++}',
      color: roomColors[(rooms.length) % roomColors.length],
      position: position,
      width: 200,
      height: 150,
      walls: walls,
    );

    setState(() {
      // Deselect all existing rooms
      _clearAllSelections();

      // Add and select new room
      rooms.add(newRoom);
      _selectRoom(newRoom);
      showRightPanel = true;
    });
  }

  void _deleteRoom(Room room) {
    setState(() {
      // Remove room
      rooms.remove(room);

      if (selectedRoom == room) {
        selectedRoom = null;
        showRightPanel = false;
      }
    });
  }

  void _deleteSelected() {
    if (selectedRoom != null) {
      _deleteRoom(selectedRoom!);
    } else if (selectedElement != null) {
      // Find room containing element
      for (var room in rooms) {
        if (room.elements.contains(selectedElement)) {
          setState(() {
            room.elements.remove(selectedElement);
            selectedElement = null;
            showRightPanel = false;
          });
          break;
        }
      }
    }
  }

  void _selectRoom(Room room) {
    setState(() {
      // Clear previous selections
      _clearAllSelections();

      // Select the new room
      room.selected = true;
      selectedRoom = room;
      showRightPanel = true;
    });
  }

  void _selectElement(ArchitecturalElement element) {
    setState(() {
      // Clear previous selections
      _clearAllSelections();

      // Select the new element
      element.isSelected = true;
      selectedElement = element;
      showRightPanel = true;
    });
  }

  void _clearAllSelections() {
    // Clear room selections
    for (var room in rooms) {
      room.selected = false;
    }
    selectedRoom = null;

    // Clear element selections
    for (var room in rooms) {
      for (var element in room.elements) {
        element.isSelected = false;
      }
    }
    selectedElement = null;
  }

  void _handleRoomWidthChange(Room room, double newWidth) {
    setState(() {
      room.width = newWidth;
    });
  }

  void _handleRoomHeightChange(Room room, double newHeight) {
    setState(() {
      room.height = newHeight;
    });
  }

  void _handleRoomColorChange(Room room, Color newColor) {
    setState(() {
      room.color = newColor;
    });
  }

  void _handleRoomNameChange(Room room, String newName) {
    setState(() {
      room.name = newName;
    });
  }

  void _handleElementNameChange(ArchitecturalElement element, String newName) {
    setState(() {
      element.name = newName;
    });
  }

  void _handleElementWidthChange(
      ArchitecturalElement element, double newWidth) {
    setState(() {
      element.width = newWidth;
    });
  }

  void _handleElementHeightChange(
      ArchitecturalElement element, double newHeight) {
    setState(() {
      element.height = newHeight;
    });
  }

  void _handleElementRotationChange(
      ArchitecturalElement element, double newRotation) {
    setState(() {
      element.rotation = newRotation;
    });
  }

  void _handleModeChange(EditorMode newMode) {
    setState(() {
      mode = newMode;
      
      // Clear temporary states if mode changes
      if (isDrawingLine) {
        isDrawingLine = false;
        lineStart = null;
        lineEnd = null;
      }
      
      if (activeMeasurement != null) {
        activeMeasurement = null;
      }
    });
  }

  void _handleRightPanelToggle() {
    setState(() {
      showRightPanel = !showRightPanel;
    });
  }

  void _handleGridRealSizeChange(double newSize) {
    setState(() {
      gridRealSize = newSize;
    });
  }

  void _handleUnitChange(MeasurementUnit newUnit) {
    setState(() {
      // Calculate conversion factor
      final conversionFactor =
          newUnit.conversionFromMeters / unit.conversionFromMeters;

      // Update default wall height
      defaultWallHeight = MeasurementUtils.convertBetweenUnits(
          defaultWallHeight, unit, newUnit);

      // Update grid real size
      gridRealSize =
          MeasurementUtils.convertBetweenUnits(gridRealSize, unit, newUnit);

      // Update unit
      unit = newUnit;
    });
  }

  void _handleDefaultWallHeightChange(double newHeight) {
    setState(() {
      defaultWallHeight = newHeight;
    });
  }

  void _handleGridToggle() {
    setState(() {
      showGrid = !showGrid;
    });
  }

  void _handleMeasurementsToggle() {
    setState(() {
      showMeasurements = !showMeasurements;
    });
  }

  void _handleZoom(double scaleFactor) {
    final matrix = transformationController.value.clone();
    matrix.scale(scaleFactor);
    transformationController.value = matrix;
  }

  void _resetView() {
    transformationController.value = Matrix4.identity();
  }

  void _renameProject() {
    final controller = TextEditingController(text: projectName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Project"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Project Name",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                projectName = controller.text.isNotEmpty
                    ? controller.text
                    : "Untitled Project";
              });
              Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  // Calculate project statistics
  Map<String, dynamic> _calculateProjectStats() {
    // Count all elements
    int doorCount = 0;
    int windowCount = 0;
    int lineCount = 0;

    for (var room in rooms) {
      for (var element in room.elements) {
        if (element.type == ElementType.door) {
          doorCount++;
        } else if (element.type == ElementType.window) {
          windowCount++;
        } else if (element.type == ElementType.line) {
          lineCount++;
        }
      }
    }

    return {
      'roomCount': rooms.length,
      'doorCount': doorCount,
      'windowCount': windowCount,
      'lineCount': lineCount,
      'measurementCount': measurements.length,
    };
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        gridRealSize: gridRealSize,
        defaultWallHeight: defaultWallHeight,
        snapDistance: snapDistance,
        unit: unit,
        wallThickness: wallThickness,
        showGrid: showGrid,
        showMeasurements: showMeasurements,
        projectStats: _calculateProjectStats(),
        onGridRealSizeChanged: _handleGridRealSizeChange,
        onDefaultWallHeightChanged: _handleDefaultWallHeightChange,
        onSnapDistanceChanged: (value) {
          setState(() {
            snapDistance = value;
          });
        },
        onUnitChanged: _handleUnitChange,
        onWallThicknessChanged: (value) {
          setState(() {
            wallThickness = value;
          });
        },
        onShowGridChanged: (value) {
          setState(() {
            showGrid = value ?? true;
          });
        },
        onShowMeasurementsChanged: (value) {
          setState(() {
            showMeasurements = value ?? true;
          });
        },
      ),
    );
  }
  
  // Handle line drawing start
  void _handleLineDrawingStart(Offset point) {
    setState(() {
      isDrawingLine = true;
      lineStart = point;
      lineEnd = point; // Initialize with same point
    });
  }

  // Handle line drawing update
  void _handleLineDrawingUpdate(Offset point) {
    if (isDrawingLine && lineStart != null) {
      setState(() {
        lineEnd = point;
      });
    }
  }

  // Handle line drawing end
  void _handleLineDrawingEnd() {
    if (isDrawingLine && lineStart != null && lineEnd != null) {
      // Ensure the points are different
      if ((lineEnd! - lineStart!).distance > 5) {
        final newLine = ArchitecturalElement.line(
          start: lineStart!,
          end: lineEnd!,
          name: 'Line ${DateTime.now().millisecondsSinceEpoch}',
        );
        
        setState(() {
          // Add line to a room or to a separate list
          if (selectedRoom != null) {
            selectedRoom!.elements.add(newLine);
            _selectElement(newLine);
          } else if (rooms.isNotEmpty) {
            // If no room is selected, add to first room
            rooms.first.elements.add(newLine);
            _selectElement(newLine);
          }
        });
      }
      
      // Reset drawing state
      setState(() {
        isDrawingLine = false;
        lineStart = null;
        lineEnd = null;
      });
    }
  }

  // Handle measurement start
  void _handleMeasurementStart(Offset point) {
    setState(() {
      activeMeasurement = Measurement(
        start: point,
        end: point,
        measuredLength: 0,
      );
    });
  }

  // Handle measurement update
  void _handleMeasurementUpdate(Offset point) {
    if (activeMeasurement != null) {
      setState(() {
        activeMeasurement = Measurement(
          start: activeMeasurement!.start,
          end: point,
          measuredLength: (point - activeMeasurement!.start).distance,
        );
      });
    }
  }

  // Handle measurement end
  void _handleMeasurementEnd() {
    if (activeMeasurement != null) {
      // Check if the measurement is meaningful (not too short)
      if ((activeMeasurement!.end - activeMeasurement!.start).distance > 5) {
        setState(() {
          measurements.add(Measurement(
            start: activeMeasurement!.start,
            end: activeMeasurement!.end,
            measuredLength: activeMeasurement!.measuredLength,
            isTemporary: false,
          ));
        });
      }
      
      // Reset active measurement
      setState(() {
        activeMeasurement = null;
      });
    }
  }
  
  // Clear all measurements
  void _clearMeasurements() {
    setState(() {
      measurements.clear();
      activeMeasurement = null;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    final point = _transformPoint(event.localPosition);

    // Handle based on current mode
    if (mode == EditorMode.line) {
      _handleLineDrawingStart(point);
      return;
    } else if (mode == EditorMode.measure) {
      _handleMeasurementStart(point);
      return;
    } else if (mode == EditorMode.select) {
      // Try to find element under pointer
      ArchitecturalElement? element = _findElementAt(point);
      if (element != null) {
        setState(() {
          isDraggingAnyObject = true;
          element.startDrag(point);
          _selectElement(element);
        });
        return;
      }

      // Try to find room
      Room? room = _findRoomAt(point);
      if (room != null) {
        setState(() {
          isDraggingAnyObject = true;
          room.startDrag(point);
          _selectRoom(room);

          // Reset snap tracking
          currentSnapType = SnapType.none;
          targetSnapRoom = null;
          sourceWallIndex = null;
          targetWallIndex = null;
        });
        return;
      }

      // Nothing found, start canvas drag or clear selection
      if (event.buttons == 1) {
        // Primary button (left click)
        setState(() {
          _clearAllSelections();
          showRightPanel = false;
        });
      } else if (event.buttons == 4) {
        // Middle button
        // Start canvas dragging
        isCanvasDragging = true;
        lastGlobalPosition = event.position;
      }
    } else if (mode == EditorMode.door || mode == EditorMode.window) {
      // Try to find any wall to place element on
      final wallResult = Room.findClosestWallPoint(point, rooms, snapDistance);

      if (wallResult != null) {
        final snapPoint = wallResult.$1;
        final wall = wallResult.$3;
        final room = wallResult.$4;

        _addElementToWall(room, snapPoint, wall,
            mode == EditorMode.door ? ElementType.door : ElementType.window);
        return;
      }

      // Try to find any corner to place element at
      final cornerResult = Room.findClosestCorner(point, rooms, snapDistance);

      if (cornerResult != null) {
        final cornerPos = cornerResult.$1;
        final cornerIndex = cornerResult.$3;
        final room = cornerResult.$4;

        _addElementToCorner(room, cornerPos, cornerIndex,
            mode == EditorMode.door ? ElementType.door : ElementType.window);
      }
    } else if (mode == EditorMode.delete) {
      // Try to find element to delete
      ArchitecturalElement? element = _findElementAt(point);
      if (element != null) {
        for (var room in rooms) {
          if (room.elements.contains(element)) {
            setState(() {
              room.elements.remove(element);
              if (selectedElement == element) {
                selectedElement = null;
                showRightPanel = false;
              }
            });
            return;
          }
        }
      }

      // Try to find room to delete
      Room? room = _findRoomAt(point);
      if (room != null) {
        _deleteRoom(room);
        return;
      }
      
      // Delete measurement if in range
      for (int i = 0; i < measurements.length; i++) {
        final measurement = measurements[i];
        final line = (measurement.end - measurement.start);
        final length = line.distance;
        
        // Check if point is near the measurement line
        if (length > 0) {
          final normalized = line / length;
          final perpendicular = Offset(-normalized.dy, normalized.dx);
          
          // Project point onto line
          final v = point - measurement.start;
          final projection = v.dx * normalized.dx + v.dy * normalized.dy;
          
          // Check if projection is within line segment
          if (projection >= 0 && projection <= length) {
            // Calculate distance to line
            final projPoint = measurement.start + normalized * projection;
            final distance = (point - projPoint).distance;
            
            // If close enough, delete measurement
            if (distance <= 10.0) {
              setState(() {
                measurements.removeAt(i);
              });
              return;
            }
          }
        }
      }
    } else if (mode == EditorMode.room) {
      // Create walls with default height
      List<Wall> walls = List.generate(
          4, (_) => Wall(height: defaultWallHeight));

      // Create new room at the pointer position
      final newRoom = Room(
        name: 'Room ${roomCounter++}',
        color: roomColors[(rooms.length) % roomColors.length],
        position: point,
        width: 200,
        height: 150,
        walls: walls,
      );

      setState(() {
        // Deselect all existing rooms
        _clearAllSelections();

        // Add and select new room
        rooms.add(newRoom);
        _selectRoom(newRoom);
        showRightPanel = true;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final point = _transformPoint(event.localPosition);

    // Handle line drawing or measurement first
    if (isDrawingLine) {
      _handleLineDrawingUpdate(point);
      return;
    } else if (activeMeasurement != null) {
      _handleMeasurementUpdate(point);
      return;
    } else if (isCanvasDragging && lastGlobalPosition != null) {
      // Handle canvas dragging (panning the view)
      final delta = event.position - lastGlobalPosition!;
      final matrix = transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();

      matrix.translate(delta.dx / scale, delta.dy / scale);
      transformationController.value = matrix;

      lastGlobalPosition = event.position;
      return;
    }

    if (isDraggingAnyObject) {
      setState(() {
        if (selectedElement != null && selectedElement!.isDragging) {
          // Apply live dragging for elements
          selectedElement!.drag(point);

          // Check for potential snaps during dragging (for visual feedback)
          _checkElementSnapDuringDrag(selectedElement!);
        } else if (selectedRoom != null && selectedRoom!.isDragging) {
          // Apply live dragging for rooms
          selectedRoom!.drag(point);

          // Check for potential snaps during dragging (for visual feedback)
          _checkRoomSnapDuringDrag(selectedRoom!);
        }
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Handle line drawing or measurement completion
    if (isDrawingLine) {
      _handleLineDrawingEnd();
      return;
    } else if (activeMeasurement != null) {
      _handleMeasurementEnd();
      return;
    } else if (isCanvasDragging) {
      // End canvas dragging
      isCanvasDragging = false;
      lastGlobalPosition = null;
      return;
    }

    // Handle snapping on release of dragged objects
    if (isDraggingAnyObject) {
      setState(() {
        if (selectedElement != null && selectedElement!.isDragging) {
          // Apply final element snapping
          _snapElementToWall(selectedElement!);
          selectedElement!.endDrag();
        } else if (selectedRoom != null && selectedRoom!.isDragging) {
          // Try to snap walls
          if (_applyRoomWallSnap(selectedRoom!)) {
            // Wall snap occurred
          } else {
            // Reset snap type if no snap occurred
            currentSnapType = SnapType.none;
            targetSnapRoom = null;
            sourceWallIndex = null;
            targetWallIndex = null;
          }

          selectedRoom!.endDrag();
        }

        isDraggingAnyObject = false;
      });
    }
  }

  // Check and track potential room wall snaps during drag
  void _checkRoomSnapDuringDrag(Room room) {
    // Reset current snap info
    currentSnapType = SnapType.none;
    targetSnapRoom = null;
    sourceWallIndex = null;
    targetWallIndex = null;

    // Check for wall alignment snaps
    final otherRooms = rooms.where((r) => r != room).toList();
    if (otherRooms.isEmpty) return;

    // Find best wall alignment
    final wallAlignment = _findBestWallAlignment(room, otherRooms);
    if (wallAlignment != null) {
      currentSnapType = SnapType.wall;
      targetSnapRoom = wallAlignment.$1;
      sourceWallIndex = wallAlignment.$2;
      targetWallIndex = wallAlignment.$3;
    }
  }

  // Calculate wall alignment offset
  Offset _getWallAlignmentOffset((Offset, Offset) sourceWall, (Offset, Offset) targetWall) {
    // Get wall vectors
    final sourceVector = sourceWall.$2 - sourceWall.$1;
    final targetVector = targetWall.$2 - targetWall.$1;
    
    // Check if walls are primarily horizontal or vertical
    final isHorizontalSource = sourceVector.dx.abs() > sourceVector.dy.abs();
    final isHorizontalTarget = targetVector.dx.abs() > targetVector.dy.abs();
    
    // Only align walls with the same orientation
    if (isHorizontalSource != isHorizontalTarget) {
      return Offset.zero;
    }
    
    if (isHorizontalSource) {
      // For horizontal walls, align y coordinates
      return Offset(0, targetWall.$1.dy - sourceWall.$1.dy);
    } else {
      // For vertical walls, align x coordinates
      return Offset(targetWall.$1.dx - sourceWall.$1.dx, 0);
    }
  }

  // Find best wall alignment between rooms
  (Room, int, int)? _findBestWallAlignment(Room room, List<Room> otherRooms) {
    double bestDistance = double.infinity;
    Room? bestRoom;
    int bestWall1 = -1;
    int bestWall2 = -1;
    
    final walls1 = room.getWallSegments();
    
    for (var otherRoom in otherRooms) {
      final walls2 = otherRoom.getWallSegments();
      
      for (int i = 0; i < walls1.length; i++) {
        for (int j = 0; j < walls2.length; j++) {
          // Check if walls are potentially alignable (parallel)
          final wall1 = walls1[i];
          final wall2 = walls2[j];
          
          // Get wall vectors
          final vector1 = wall1.$2 - wall1.$1;
          final vector2 = wall2.$2 - wall2.$1;
          
          // Calculate normalized dot product to check if parallel
          final norm1 = vector1;
          final norm2 = vector2;
          final dot = norm1.dx * norm2.dx + norm1.dy * norm2.dy;
          
          // Check if walls are parallel (dot product close to 1 or -1)
          if (dot.abs() > 0.9) {
            // Get alignment offset
            final offset = _getWallAlignmentOffset(wall1, wall2);
            
            // Calculate distance (how far we need to move)
            final distance = offset.distance;
            
            if (distance < bestDistance && distance < snapDistance) {
              bestDistance = distance;
              bestRoom = otherRoom;
              bestWall1 = i;
              bestWall2 = j;
            }
          }
        }
      }
    }
    
    if (bestRoom != null) {
      return (bestRoom, bestWall1, bestWall2);
    }
    
    return null;
  }

  // Check element snap during drag (for visual feedback)
  void _checkElementSnapDuringDrag(ArchitecturalElement element) {
    // Try to find nearest wall
    final wallResult =
        Room.findClosestWallPoint(element.position, rooms, snapDistance);

    if (wallResult != null) {
      currentSnapType = SnapType.wall;
      return;
    }

    // Check for corner snap
    final cornerResult =
        Room.findClosestCorner(element.position, rooms, snapDistance);

    if (cornerResult != null) {
      currentSnapType = SnapType.corner;
      return;
    }

    // No snap found
    currentSnapType = SnapType.none;
  }

  // Apply wall-to-wall room snapping
  bool _applyRoomWallSnap(Room room) {
    // If we have tracked a potential snap during drag, use that
    if (currentSnapType == SnapType.wall &&
        targetSnapRoom != null &&
        sourceWallIndex != null &&
        targetWallIndex != null) {
      
      // Get the walls
      final sourceWalls = room.getWallSegments();
      final targetWalls = targetSnapRoom!.getWallSegments();
      
      if (sourceWallIndex! < sourceWalls.length && targetWallIndex! < targetWalls.length) {
        final sourceWall = sourceWalls[sourceWallIndex!];
        final targetWall = targetWalls[targetWallIndex!];
        
        // Calculate alignment offset
        final offset = _getWallAlignmentOffset(sourceWall, targetWall);
        
        // Apply offset to move room
        room.move(offset);
        
        return true;
      }
    }
    
    // If no snap was tracked during drag, find the best now
    final otherRooms = rooms.where((r) => r != room).toList();
    if (otherRooms.isEmpty) return false;
    
    final alignmentResult = _findBestWallAlignment(room, otherRooms);
    
    if (alignmentResult != null) {
      // Get the walls
      final sourceWalls = room.getWallSegments();
      final targetRoom = alignmentResult.$1;
      final sourceWallIndex = alignmentResult.$2;
      final targetWallIndex = alignmentResult.$3;
      final targetWalls = targetRoom.getWallSegments();
      
      // Calculate and apply offset
      final sourceWall = sourceWalls[sourceWallIndex];
      final targetWall = targetWalls[targetWallIndex];
      final offset = _getWallAlignmentOffset(sourceWall, targetWall);
      room.move(offset);
      
      // Update snap info
      this.sourceWallIndex = sourceWallIndex;
      this.targetWallIndex = targetWallIndex;
      this.targetSnapRoom = targetRoom;
      this.currentSnapType = SnapType.wall;
      
      return true;
    }
    
    return false;
  }

  // Snap element to the nearest wall
  bool _snapElementToWall(ArchitecturalElement element) {
    // Try to find nearest wall
    final wallResult =
        Room.findClosestWallPoint(element.position, rooms, snapDistance);

    if (wallResult != null) {
      final snapPoint = wallResult.$1;
      final wall = wallResult.$3;
      final room = wallResult.$4;

      // Calculate wall angle
      final wallVector = wall.$2 - wall.$1;
      final wallAngle = math.atan2(wallVector.dy, wallVector.dx);

      // Set position and rotation
      element.position = snapPoint;

      // Perpendicular to wall
      element.rotation = wallAngle + math.pi / 2;

      // Adjust position slightly away from wall
      final perpOffset = element.height / 2;
      element.position = Offset(
          snapPoint.dx + math.cos(element.rotation) * perpOffset,
          snapPoint.dy + math.sin(element.rotation) * perpOffset);

      // Update element's room reference
      element.room = room;

      currentSnapType = SnapType.wall;
      return true;
    }

    // Try to find a corner as fallback
    final cornerResult =
        Room.findClosestCorner(element.position, rooms, snapDistance);

    if (cornerResult != null) {
      final cornerPos = cornerResult.$1;
      final room = cornerResult.$4;
      final cornerIndex = cornerResult.$3;

      // Set position
      element.position = cornerPos;

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

      // Set the rotation
      element.rotation = angle;

      // Update the room reference
      element.room = room;

      // Offset position slightly from corner
      final offsetDistance = element.width / 4;
      element.position = Offset(cornerPos.dx + math.cos(angle) * offsetDistance,
          cornerPos.dy + math.sin(angle) * offsetDistance);

      currentSnapType = SnapType.corner;
      return true;
    }

    currentSnapType = SnapType.none;
    return false;
  }

  // Add element to a wall at a specific point
  void _addElementToWall(
      Room room, Offset position, (Offset, Offset) wall, ElementType type) {
    // Create element
    final element = ArchitecturalElement(
      type: type,
      position: position,
      room: room,
    );

    // Calculate wall angle
    final wallVector = wall.$2 - wall.$1;
    final wallAngle = math.atan2(wallVector.dy, wallVector.dx);

    // Set rotation perpendicular to wall
    element.rotation = wallAngle + math.pi / 2;

    // Adjust position slightly away from wall
    final perpOffset = element.height / 2;
    element.position = Offset(
        position.dx + math.cos(element.rotation) * perpOffset,
        position.dy + math.sin(element.rotation) * perpOffset);

    setState(() {
      room.elements.add(element);

      // Clear previous selections
      _clearAllSelections();

      // Select the new element
      _selectElement(element);

      // Switch to select mode
      mode = EditorMode.select;
    });
  }

  void _addElementToCorner(
      Room room, Offset cornerPos, int cornerIndex, ElementType type) {
    // Create element
    final element = ArchitecturalElement(
      type: type,
      position: cornerPos,
      room: room,
    );

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

    // Set the rotation
    element.rotation = angle;

    // Offset position slightly from corner
    final offsetDistance = element.width / 4;
    element.position = Offset(cornerPos.dx + math.cos(angle) * offsetDistance,
        cornerPos.dy + math.sin(angle) * offsetDistance);

    setState(() {
      room.elements.add(element);

      // Clear previous selections
      _clearAllSelections();

      // Select the new element
      _selectElement(element);

      // Switch to select mode
      mode = EditorMode.select;
    });
  }

  // Finds element at given point with tolerance consideration
  ArchitecturalElement? _findElementAt(Offset point) {
    // Try to find element under pointer, prioritizing selected ones
    ArchitecturalElement? foundElement;

    // First check already selected elements
    for (var room in rooms) {
      for (var element in room.elements) {
        if (element.isSelected && element.containsPoint(point)) {
          return element; // Return immediately if we find a selected element
        }
      }
    }

    // Then check unselected elements
    for (var room in rooms) {
      for (var element in room.elements) {
        if (element.containsPoint(point)) {
          foundElement = element;
          break;
        }
      }
      if (foundElement != null) break;
    }

    return foundElement;
  }

  // Finds room at given point with priority for selected rooms
  Room? _findRoomAt(Offset point) {
    // First check if point is within already selected room
    if (selectedRoom != null && selectedRoom!.containsPoint(point)) {
      return selectedRoom;
    }

    // Then check other rooms
    for (var room in rooms) {
      if (!room.selected && room.containsPoint(point)) {
        return room;
      }
    }

    return null;
  }

  // Transform point from screen space to canvas space
  Offset _transformPoint(Offset point) {
    final matrix = transformationController.value;
    final translation =
        Offset(matrix.getTranslation().x, matrix.getTranslation().y);
    final scale = matrix.getMaxScaleOnAxis();
    return (point - translation) / scale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Toolbar
          EditorToolbar(
            projectName: projectName,
            mode: mode,
            rooms: rooms,
            selectedRoom: selectedRoom,
            onModeChanged: _handleModeChange,
            onRoomSelected: _selectRoom,
            onRoomDeleted: _deleteRoom,
            onAddRoom: _addNewRoom,
            onRenameProject: _renameProject,
            onOpenSettings: _openSettings,
          ),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Canvas
                Expanded(
                  child: _buildCanvas(),
                ),

                // Right Properties Panel (conditional)
                if (showRightPanel)
                  SizedBox(
                    width: 300,
                    child: PropertiesPanel(
                      selectedRoom: selectedRoom,
                      selectedElement: selectedElement,
                      roomColors: roomColors,
                      onRoomWidthChanged: _handleRoomWidthChange,
                      onRoomHeightChanged: _handleRoomHeightChange,
                      onRoomColorChanged: _handleRoomColorChange,
                      onRoomNameChanged: _handleRoomNameChange,
                      onElementNameChanged: _handleElementNameChange,
                      onElementWidthChanged: _handleElementWidthChange,
                      onElementHeightChanged: _handleElementHeightChange,
                      onElementRotationChanged: _handleElementRotationChange,
                      onPanelClosed: _handleRightPanelToggle,
                      gridSize: gridSize,
                      gridRealSize: gridRealSize,
                      unit: unit,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Status Bar
          StatusBar(
            showGrid: showGrid,
            showMeasurements: showMeasurements,
            selectedRoom: selectedRoom,
            selectedElement: selectedElement,
            onGridToggled: _handleGridToggle,
            onMeasurementsToggled: _handleMeasurementsToggle,
            onZoomIn: () => _handleZoom(1.2),
            onZoomOut: () => _handleZoom(0.8),
            onResetView: _resetView,
            snapType: currentSnapType,
            currentMode: mode,
            measurements: measurements,
            onClearMeasurements: _clearMeasurements,
          ),
        ],
      ),
    );
  }

  // Build the interactive canvas with pointer event handling
  Widget _buildCanvas() {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: InteractiveViewer(
        transformationController: transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.1,
        maxScale: 5.0,
        panEnabled: false, // Disable default pan to use our custom implementation
        child: Container(
          width: 3000,
          height: 3000,
          color: Colors.grey[50],
          child: CustomPaint(
            painter: FloorPlanPainter(
              rooms: rooms,
              selectedElement: selectedElement,
              selectedRoom: selectedRoom,
              gridSize: gridSize,
              gridRealSize: gridRealSize,
              unit: unit,
              showGrid: showGrid,
              showMeasurements: showMeasurements,
              wallThickness: wallThickness,
              isDragging: isDraggingAnyObject || isCanvasDragging,
              snapDistance: snapDistance,
              enableGridSnap: enableGridSnap,
              currentSnapType: currentSnapType,
              targetSnapRoom: targetSnapRoom,
              sourceWallIndex: sourceWallIndex,
              targetWallIndex: targetWallIndex,
              measurements: measurements,
              activeMeasurement: activeMeasurement,
              isDrawingLine: isDrawingLine,
              lineStart: lineStart,
              lineEnd: lineEnd,
            ),
          ),
        ),
      ),
    );
  }
}

// Stateful Settings Dialog
class _SettingsDialog extends StatefulWidget {
  final double gridRealSize;
  final double defaultWallHeight;
  final double snapDistance;
  final MeasurementUnit unit;
  final double wallThickness;
  final bool showGrid;
  final bool showMeasurements;
  final Map<String, dynamic> projectStats;
  final Function(double) onGridRealSizeChanged;
  final Function(double) onDefaultWallHeightChanged;
  final Function(double) onSnapDistanceChanged;
  final Function(MeasurementUnit) onUnitChanged;
  final Function(double) onWallThicknessChanged;
  final Function(bool?) onShowGridChanged;
  final Function(bool?) onShowMeasurementsChanged;

  const _SettingsDialog({
    required this.gridRealSize,
    required this.defaultWallHeight,
    required this.snapDistance,
    required this.unit,
    required this.wallThickness,
    required this.showGrid,
    required this.showMeasurements,
    required this.projectStats,
    required this.onGridRealSizeChanged,
    required this.onDefaultWallHeightChanged,
    required this.onSnapDistanceChanged,
    required this.onUnitChanged,
    required this.onWallThicknessChanged,
    required this.onShowGridChanged,
    required this.onShowMeasurementsChanged,
  });

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late double gridRealSize;
  late double defaultWallHeight;
  late double snapDistance;
  late MeasurementUnit unit;
  late double wallThickness;
  late bool showGrid;
  late bool showMeasurements;

  @override
  void initState() {
    super.initState();
    gridRealSize = widget.gridRealSize;
    defaultWallHeight = widget.defaultWallHeight;
    snapDistance = widget.snapDistance;
    unit = widget.unit;
    wallThickness = widget.wallThickness;
    showGrid = widget.showGrid;
    showMeasurements = widget.showMeasurements;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Settings"),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Measurement Units Section
            const Text("Measurement Unit",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<MeasurementUnit>(
              value: unit,
              isExpanded: true,
              items: MeasurementUnit.values
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text("${u.name} (${u.symbol})"),
                      ))
                  .toList(),
              onChanged: (MeasurementUnit? newUnit) {
                if (newUnit != null) {
                  setState(() => unit = newUnit);
                }
              },
            ),

            const SizedBox(height: 16),

            // Grid Settings
            const Text("Grid Settings",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Grid Real Size
            Row(
              children: [
                const Text("Grid Unit Size: "),
                Expanded(
                  child: Slider(
                    value: gridRealSize,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    label: gridRealSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        gridRealSize = value;
                      });
                    },
                  ),
                ),
                Text("$gridRealSize ${unit.symbol}"),
              ],
            ),

            const SizedBox(height: 16),

            // Default Wall Height
            const Text("Default Wall Height",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text("Wall Height: "),
                Expanded(
                  child: Slider(
                    value: defaultWallHeight,
                    min: 6.0,
                    max: 20.0,
                    divisions: 28,
                    label: defaultWallHeight.toString(),
                    onChanged: (value) {
                      setState(() {
                        defaultWallHeight = value;
                      });
                    },
                  ),
                ),
                Text("$defaultWallHeight ${unit.symbol}"),
              ],
            ),

            const SizedBox(height: 16),

            // Snapping Settings
            const Text("Snapping Settings",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text("Snap Distance: "),
                Expanded(
                  child: Slider(
                    value: snapDistance,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: snapDistance.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        snapDistance = value;
                      });
                    },
                  ),
                ),
                Text("${snapDistance.round()}px"),
              ],
            ),

            const SizedBox(height: 16),

            // Wall Settings
            const Text("Wall Settings",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text("Wall Thickness: "),
                Expanded(
                  child: Slider(
                    value: wallThickness,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: wallThickness.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        wallThickness = value;
                      });
                    },
                  ),
                ),
                Text("${wallThickness.round()}px"),
              ],
            ),

            const SizedBox(height: 16),

            // Display Options
            const Text("Display Options",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text("Show Grid"),
              value: showGrid,
              onChanged: (value) {
                setState(() {
                  showGrid = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            CheckboxListTile(
              title: const Text("Show Measurements"),
              value: showMeasurements,
              onChanged: (value) {
                setState(() {
                  showMeasurements = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),

            // Project Statistics Section
            const Text("Project Statistics",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rooms: ${widget.projectStats['roomCount']}"),
                      Text("Doors: ${widget.projectStats['doorCount']}"),
                      Text("Windows: ${widget.projectStats['windowCount']}"),
                      Text("Lines: ${widget.projectStats['lineCount'] ?? 0}"),
                      Text("Measurements: ${widget.projectStats['measurementCount'] ?? 0}"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            // Apply all settings
            widget.onGridRealSizeChanged(gridRealSize);
            widget.onDefaultWallHeightChanged(defaultWallHeight);
            widget.onSnapDistanceChanged(snapDistance);
            widget.onUnitChanged(unit);
            widget.onWallThicknessChanged(wallThickness);
            widget.onShowGridChanged(showGrid);
            widget.onShowMeasurementsChanged(showMeasurements);
            Navigator.pop(context);
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }
}
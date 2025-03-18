import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/element.dart';
import '../models/enums.dart';
import '../painters/floor_plan_painter.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/properties_panel.dart';
import '../widgets/status_bar.dart';
import 'dart:math' as math;

class FloorPlanEditor extends StatefulWidget {
  const FloorPlanEditor({super.key});

  @override
  FloorPlanEditorState createState() => FloorPlanEditorState();
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
  MeasurementUnit unit = MeasurementUnit.meters;
  
  // Panel states
  bool showRightPanel = false;
  
  // Canvas state
  final transformationController = TransformationController();
  Offset? lastGlobalPosition;
  bool isCanvasDragging = false;
  
  // Interaction state flags
  bool isDraggingAnyObject = false;
  
  // Corner snapping
  double cornerSnapDistance = 25.0;
  bool enableGridSnap = false; // Always use corner-to-corner snapping
  
  // Room counter
  int roomCounter = 1;
  
  // Wall thickness
  double wallThickness = 4.0;
  
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
        0,
        (max, room) => math.max(max, room.position.dx + room.width / 2)
      );
      // Position new room to the right of existing rooms with some margin
      position = Offset(maxX + 120, position.dy);
    }
    
    // Create new room
    final newRoom = Room(
      name: 'Room ${roomCounter++}',
      color: roomColors[(rooms.length) % roomColors.length],
      position: position,
      width: 200,
      height: 150,
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
  
  void _handleElementWidthChange(ArchitecturalElement element, double newWidth) {
    setState(() {
      element.width = newWidth;
    });
  }
  
  void _handleElementHeightChange(ArchitecturalElement element, double newHeight) {
    setState(() {
      element.height = newHeight;
    });
  }
  
  void _handleElementRotationChange(ArchitecturalElement element, double newRotation) {
    setState(() {
      element.rotation = newRotation;
    });
  }
  
  void _handleModeChange(EditorMode newMode) {
    setState(() {
      mode = newMode;
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
      unit = newUnit;
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
  
  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid Settings (simplified)
              const Text("Grid Settings", style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              // Corner Snap Settings
              const Text("Box Snapping Settings", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Text("Snap Distance: "),
                  Expanded(
                    child: Slider(
                      value: cornerSnapDistance,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: cornerSnapDistance.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          cornerSnapDistance = value;
                        });
                      },
                    ),
                  ),
                  Text("${cornerSnapDistance.round()}px"),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Measurement Unit
              const Text("Measurement Unit", style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              // Wall Settings
              const Text("Wall Settings", style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text("Display Options", style: TextStyle(fontWeight: FontWeight.bold)),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    final point = _transformPoint(event.localPosition);
    
    if (mode == EditorMode.select) {
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
        });
        return;
      }
      
      // Nothing found, start canvas drag or clear selection
      if (event.buttons == 1) { // Primary button (left click)
        setState(() {
          _clearAllSelections();
          showRightPanel = false;
        });
      } else if (event.buttons == 4) { // Middle button
        // Start canvas dragging
        isCanvasDragging = true;
        lastGlobalPosition = event.position;
      }
    }
    else if (mode == EditorMode.door || mode == EditorMode.window) {
      // Try to find any corner to place element at
      final cornerResult = Room.findClosestCorner(point, rooms, cornerSnapDistance);
      
      if (cornerResult != null) {
        final cornerPos = cornerResult.$1;
        final cornerIndex = cornerResult.$3;
        final room = cornerResult.$4;
        
        _addElementToCorner(
          room,
          cornerPos,
          cornerIndex,
          mode == EditorMode.door 
              ? ElementType.door 
              : ElementType.window
        );
      }
      else {
        // Try to find midpoint of a wall
        final midpointResult = Room.findClosestMidpoint(point, rooms, cornerSnapDistance);
        
        if (midpointResult != null) {
          final midpointPos = midpointResult.$1;
          
          // Find which wall this midpoint belongs to
          for (var room in rooms) {
            for (var wallSegment in room.getWallSegments()) {
              final wallMidpoint = Offset(
                (wallSegment.$1.dx + wallSegment.$2.dx) / 2,
                (wallSegment.$1.dy + wallSegment.$2.dy) / 2,
              );
              
              if ((wallMidpoint - midpointPos).distanceSquared < 1.0) {
                _addElementToWallMidpoint(
                  room,
                  midpointPos,
                  wallSegment,
                  mode == EditorMode.door 
                      ? ElementType.door 
                      : ElementType.window
                );
                break;
              }
            }
          }
        }
      }
    }
    else if (mode == EditorMode.delete) {
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
    }
    else if (mode == EditorMode.room) {
      // Create new room at the pointer position
      final newRoom = Room(
        name: 'Room ${roomCounter++}',
        color: roomColors[(rooms.length) % roomColors.length],
        position: point,
        width: 200,
        height: 150,
      );
      
      setState(() {
        // Deselect all existing rooms
        _clearAllSelections();
        
        // Add and select new room
        rooms.add(newRoom);
        _selectRoom(newRoom);
      });
    }
  }
  
  void _handlePointerMove(PointerMoveEvent event) {
    final point = _transformPoint(event.localPosition);
    
    if (isCanvasDragging && lastGlobalPosition != null) {
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
        }
        else if (selectedRoom != null && selectedRoom!.isDragging) {
          // Apply live dragging for rooms
          selectedRoom!.drag(point);
        }
      });
    }
  }
  
  void _handlePointerUp(PointerUpEvent event) {
    // End canvas dragging
    if (isCanvasDragging) {
      isCanvasDragging = false;
      lastGlobalPosition = null;
      return;
    }
    
    // Handle snapping on release of dragged objects
    if (isDraggingAnyObject) {
      setState(() {
        if (selectedElement != null && selectedElement!.isDragging) {
          // Apply final element snapping
          _snapElementToNearbyCornersOrMidpoints(selectedElement!);
          selectedElement!.endDrag();
        }
        else if (selectedRoom != null && selectedRoom!.isDragging) {
          // Apply final corner-to-corner room snapping
          if (!_snapRoomCornerToCorner(selectedRoom!)) {
            // Debug info if snap fails
            print("Snap failed - no matching corners found within distance");
          }
          selectedRoom!.endDrag();
        }
        
        isDraggingAnyObject = false;
      });
    }
  }

  void _addElementToCorner(Room room, Offset cornerPos, int cornerIndex, ElementType type) {
    // Create element
    final element = ArchitecturalElement(
      type: type,
      position: cornerPos, // Will be adjusted in snapToCorner
      room: room,
    );
    
    // Snap to corner
    element.snapToCorner(cornerPos, room, cornerIndex);
    
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
  
  void _addElementToWallMidpoint(Room room, Offset midpointPos, (Offset, Offset) wallSegment, ElementType type) {
    // Create element
    final element = ArchitecturalElement(
      type: type,
      position: midpointPos, // Will be adjusted in snapToWallMidpoint
      room: room,
    );
    
    // Snap to midpoint
    element.snapToWallMidpoint(midpointPos, wallSegment);
    
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
  
  // Snap element to the nearest corner or midpoint
  bool _snapElementToNearbyCornersOrMidpoints(ArchitecturalElement element) {
    // Try to find a corner
    final cornerResult = ArchitecturalElement.findClosestCorner(
      element.position, 
      rooms, 
      cornerSnapDistance
    );
    
    if (cornerResult != null) {
      final cornerPos = cornerResult.$1;
      final room = cornerResult.$2;
      final cornerIndex = cornerResult.$3;
      
      // Snap element to corner
      element.snapToCorner(cornerPos, room, cornerIndex);
      return true;
    }
    
    // Try to find a wall midpoint
    final midpointResult = Room.findClosestMidpoint(
      element.position, 
      rooms, 
      cornerSnapDistance
    );
    
    if (midpointResult != null) {
      final midpointPos = midpointResult.$1;
      
      // Find which wall this midpoint belongs to
      for (var room in rooms) {
        for (var wallSegment in room.getWallSegments()) {
          final wallMidpoint = Offset(
            (wallSegment.$1.dx + wallSegment.$2.dx) / 2,
            (wallSegment.$1.dy + wallSegment.$2.dy) / 2,
          );
          
          if ((wallMidpoint - midpointPos).distanceSquared < 1.0) {
            // Snap element to midpoint
            element.snapToWallMidpoint(midpointPos, wallSegment);
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  // Fixed corner-to-corner room snapping
  bool _snapRoomCornerToCorner(Room room) {
    // Get rooms for snapping (exclude the room being dragged)
    final targetRooms = rooms.where((r) => r != room).toList();
    
    if (targetRooms.isEmpty) return false;
    
    // Make sure we have a dragged corner
    if (room.draggedCornerIndex == null) {
      print("No dragged corner index");
      return false;
    }
    
    final sourceCornerIndex = room.draggedCornerIndex!;
    final sourceCorners = room.getCorners();
    final sourceCorner = sourceCorners[sourceCornerIndex];
    
    // Find closest target corner within snap distance
    var minDistance = double.infinity;
    Offset? closestTargetCorner;
    
    for (var targetRoom in targetRooms) {
      final targetCorners = targetRoom.getCorners();
      for (int i = 0; i < targetCorners.length; i++) {
        final distance = (sourceCorner - targetCorners[i]).distance;
        if (distance < minDistance && distance <= cornerSnapDistance) {
          minDistance = distance;
          closestTargetCorner = targetCorners[i];
        }
      }
    }
    
    // If we found a corner within snap distance
    if (closestTargetCorner != null) {
      // Calculate the delta needed to move source corner to target corner
      final cornerDelta = closestTargetCorner - sourceCorner;
      
      // Calculate new room position by applying that delta
      final oldPosition = room.position;
      final newPosition = oldPosition + cornerDelta;
      
      print("Snapping: Corner delta: $cornerDelta");
      print("Old position: $oldPosition");
      print("New position: $newPosition");
      
      // First store the old position to calculate element position updates
      final oldRoomPos = room.position;
      
      // Update room position
      room.position = newPosition;
      
      // Calculate the delta and update all child elements
      final positionDelta = newPosition - oldRoomPos;
      for (var element in room.elements) {
        element.position += positionDelta;
      }
      
      return true;
    }
    
    return false;
  }

  // Transform point from screen space to canvas space
  Offset _transformPoint(Offset point) {
    final matrix = transformationController.value;
    final translation = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
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
              cornerSnapDistance: cornerSnapDistance,
              enableGridSnap: enableGridSnap,
            ),
          ),
        ),
      ),
    );
  }
}
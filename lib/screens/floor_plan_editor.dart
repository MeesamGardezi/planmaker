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
  double gridSize = 20.0;
  double gridRealSize = 1.0;
  MeasurementUnit unit = MeasurementUnit.meters;
  
  // Panel states
  bool showRightPanel = false;
  
  // Canvas state
  final transformationController = TransformationController();
  bool isDragging = false;
  Offset? dragStartPosition;
  
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
      for (var room in rooms) {
        room.selected = false;
      }
      
      // Add and select new room
      rooms.add(newRoom);
      selectedRoom = newRoom;
      selectedElement = null;
      newRoom.selected = true;
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
      // Deselect all rooms
      for (var r in rooms) {
        r.selected = false;
      }
      
      // Select the new room
      room.selected = true;
      selectedRoom = room;
      selectedElement = null;
      showRightPanel = true;
    });
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
  
  void _handleGridSizeChange(double newSize) {
    setState(() {
      gridSize = newSize;
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
              // Grid Settings
              const Text("Grid Settings", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Grid Size Slider
              Row(
                children: [
                  const Text("Grid Size: "),
                  Expanded(
                    child: Slider(
                      value: gridSize,
                      min: 10,
                      max: 50,
                      divisions: 8,
                      label: gridSize.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          gridSize = value;
                        });
                      },
                    ),
                  ),
                  Text("${gridSize.round()}px"),
                ],
              ),
              
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
              
              // Measurement Unit
              const Text("Measurement Unit", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              DropdownButton<MeasurementUnit>(
                value: unit,
                isExpanded: true,
                items: MeasurementUnit.values
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.name + " (" + u.symbol + ")"),
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
          isDragging = true;
          dragStartPosition = point;
          element.isDragging = true;
          
          selectedElement = element;
          selectedRoom = null;
          showRightPanel = true;
        });
        return;
      }
      
      // Try to find room
      Room? room = _findRoomAt(point);
      if (room != null) {
        setState(() {
          isDragging = true;
          dragStartPosition = point;
          room.isDragging = true;
          
          _selectRoom(room);
        });
        return;
      }
      
      // Nothing found, deselect all
      setState(() {
        for (var room in rooms) {
          room.selected = false;
        }
        selectedRoom = null;
        selectedElement = null;
        showRightPanel = false;
      });
    }
    else if (mode == EditorMode.door || mode == EditorMode.window) {
      // Try to find room wall nearest to pointer
      for (var room in rooms) {
        final nearestWall = room.findNearestWallSegment(point, 10.0);
        if (nearestWall != null) {
          _addElementToWall(
            room,
            nearestWall,
            mode == EditorMode.door 
                ? ElementType.door 
                : ElementType.window
          );
          break;
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
      // Create a new room at pointer location
      final position = _snapToGrid(point);
      final newRoom = Room(
        name: 'Room ${roomCounter++}',
        color: roomColors[(rooms.length) % roomColors.length],
        position: position,
        width: 200,
        height: 150,
      );
      
      setState(() {
        // Deselect all existing rooms
        for (var room in rooms) {
          room.selected = false;
        }
        
        // Add and select new room
        rooms.add(newRoom);
        selectedRoom = newRoom;
        selectedElement = null;
        newRoom.selected = true;
        showRightPanel = true;
      });
    }
  }
  
  void _handlePointerMove(PointerMoveEvent event) {
    if (!isDragging || dragStartPosition == null) return;
    
    final point = _transformPoint(event.localPosition);
    final delta = point - dragStartPosition!;
    
    // Skip if there's no movement
    if (delta == Offset.zero) return;
    
    setState(() {
      if (selectedElement != null && selectedElement!.isDragging) {
        // Move element
        selectedElement!.position += delta;
      }
      else if (selectedRoom != null && selectedRoom!.isDragging) {
        // Move room and all its elements
        selectedRoom!.move(delta);
      }
      
      dragStartPosition = point;
    });
  }
  
  void _handlePointerUp(PointerUpEvent event) {
    // Snap positions on release
    if (isDragging) {
      setState(() {
        if (selectedElement != null && selectedElement!.isDragging) {
          // Snap element position
          selectedElement!.position = _snapToGrid(selectedElement!.position);
          selectedElement!.isDragging = false;
        }
        else if (selectedRoom != null && selectedRoom!.isDragging) {
          // Snap room position
          selectedRoom!.position = _snapToGrid(selectedRoom!.position);
          selectedRoom!.isDragging = false;
        }
        
        isDragging = false;
        dragStartPosition = null;
      });
    }
  }

  void _addElementToWall(Room room, (Offset, Offset) wallSegment, ElementType type) {
    // Create element
    final midPoint = Offset(
      (wallSegment.$1.dx + wallSegment.$2.dx) / 2,
      (wallSegment.$1.dy + wallSegment.$2.dy) / 2,
    );
    
    final element = ArchitecturalElement(
      type: type,
      position: midPoint,
    );
    
    // Snap to wall
    element.snapToWall(wallSegment, wallThickness);
    
    setState(() {
      room.elements.add(element);
      
      // Select the new element
      selectedElement = element;
      selectedRoom = null;
      showRightPanel = true;
      
      // Switch to select mode
      mode = EditorMode.select;
    });
  }

  // Finds element at given point
  ArchitecturalElement? _findElementAt(Offset point) {
    for (var room in rooms) {
      for (var element in room.elements) {
        if (element.containsPoint(point)) {
          return element;
        }
      }
    }
    return null;
  }
  
  // Finds room at given point
  Room? _findRoomAt(Offset point) {
    for (var room in rooms) {
      if (room.containsPoint(point)) {
        return room;
      }
    }
    return null;
  }

  Offset _transformPoint(Offset point) {
    final matrix = transformationController.value;
    final translation = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
    final scale = matrix.getMaxScaleOnAxis();
    return (point - translation) / scale;
  }

  Offset _snapToGrid(Offset position) {
    return Offset(
      (position.dx / gridSize).round() * gridSize,
      (position.dy / gridSize).round() * gridSize,
    );
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
            gridSize: gridSize,
            showGrid: showGrid,
            showMeasurements: showMeasurements,
            selectedRoom: selectedRoom,
            selectedElement: selectedElement,
            onGridSizeChanged: _handleGridSizeChange,
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
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FloorPlanApp(),
    ));

class FloorPlanApp extends StatelessWidget {
  const FloorPlanApp({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: FloorPlanEditor(),
      );
}

// ==================== MODELS ====================

class Room {
  String name;
  final List<WallLine> walls = [];
  final List<ArchitecturalElement> elements = [];
  Color color;
  bool selected;
  double width;
  double height;
  Offset position;
  bool isDragging = false;

  Room({
    required this.name,
    required this.color,
    this.selected = false,
    this.width = 200,
    this.height = 150,
    required this.position,
  });

  void updateDimensions(double newWidth, double newHeight) {
    width = newWidth;
    height = newHeight;
    
    // Clear existing walls
    walls.clear();
    
    // Create rectangle walls
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    
    final topLeft = Offset(position.dx - halfWidth, position.dy - halfHeight);
    final topRight = Offset(position.dx + halfWidth, position.dy - halfHeight);
    final bottomRight = Offset(position.dx + halfWidth, position.dy + halfHeight);
    final bottomLeft = Offset(position.dx - halfWidth, position.dy + halfHeight);
    
    walls.add(WallLine(topLeft, topRight, room: this));
    walls.add(WallLine(topRight, bottomRight, room: this));
    walls.add(WallLine(bottomRight, bottomLeft, room: this));
    walls.add(WallLine(bottomLeft, topLeft, room: this));
  }
  
  bool containsPoint(Offset point) {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    
    return point.dx >= position.dx - halfWidth &&
           point.dx <= position.dx + halfWidth &&
           point.dy >= position.dy - halfHeight &&
           point.dy <= position.dy + halfHeight;
  }
  
  void move(Offset delta) {
    position += delta;
    
    // Update all walls
    for (var wall in walls) {
      wall.start += delta;
      wall.end += delta;
    }
    
    // Update all elements
    for (var element in elements) {
      element.position += delta;
    }
  }
}

enum ArchitecturalElementType {
  door('Door'),
  window('Window');

  final String label;
  const ArchitecturalElementType(this.label);
}

enum MeasurementUnit {
  meters('m', 1.0),
  feet('ft', 3.28084),
  inches('in', 39.3701);

  final String symbol;
  final double conversionFromMeters;
  const MeasurementUnit(this.symbol, this.conversionFromMeters);
}

enum EditorMode {
  select('Select'),
  room('Room'),
  door('Door'),
  window('Window'),
  delete('Delete');

  final String label;
  const EditorMode(this.label);
}

class WallLine {
  Offset start;
  Offset end;
  final double thickness;
  Room? room;
  bool isSelected;
  bool isDragging = false;
  bool isStartDragging = false;
  bool isEndDragging = false;

  WallLine(this.start, this.end, {this.thickness = 4.0, this.room, this.isSelected = false});

  double get length => (end - start).distance;

  bool containsPoint(Offset point, double tolerance) {
    // First check if it's near the start or end points
    if ((point - start).distance <= tolerance * 2) {
      return true;
    }
    
    if ((point - end).distance <= tolerance * 2) {
      return true;
    }
    
    // Check if it's near the line segment
    final l2 = math.pow(end.dx - start.dx, 2) + math.pow(end.dy - start.dy, 2);
    if (l2 == 0) return false; // Start and end are the same point

    final t = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        l2;

    if (t < 0 || t > 1) return false; // Point is not within the line segment

    final projection = Offset(
      start.dx + t * (end.dx - start.dx),
      start.dy + t * (end.dy - start.dy),
    );

    return (point - projection).distance <= tolerance;
  }
  
  bool isPointNearStart(Offset point, double tolerance) {
    return (point - start).distance <= tolerance * 2;
  }
  
  bool isPointNearEnd(Offset point, double tolerance) {
    return (point - end).distance <= tolerance * 2;
  }
  
  Offset get midPoint => Offset(
    (start.dx + end.dx) / 2,
    (start.dy + end.dy) / 2,
  );
}

class ArchitecturalElement {
  final ArchitecturalElementType type;
  Offset position;
  double rotation; // in radians
  double width;
  double height;
  bool isSelected;
  Room? room;
  String? name;
  bool isDragging = false;

  static const double defaultDoorWidth = 30.0;
  static const double defaultDoorHeight = 6.0;
  static const double defaultWindowWidth = 40.0;
  static const double defaultWindowHeight = 6.0;

  ArchitecturalElement({
    required this.type,
    required this.position,
    this.rotation = 0,
    double? width,
    double? height,
    this.isSelected = false,
    this.room,
    this.name,
  })  : width = width ?? _getDefaultWidth(type),
        height = height ?? _getDefaultHeight(type);

  static double _getDefaultWidth(ArchitecturalElementType type) {
    if (type == ArchitecturalElementType.door) return defaultDoorWidth;
    if (type == ArchitecturalElementType.window) return defaultWindowWidth;
    return 30.0;
  }

  static double _getDefaultHeight(ArchitecturalElementType type) {
    if (type == ArchitecturalElementType.door) return defaultDoorHeight;
    if (type == ArchitecturalElementType.window) return defaultWindowHeight;
    return 30.0;
  }

  bool containsPoint(Offset point) {
    // Transform point to element's local coordinate system
    final dx = point.dx - position.dx;
    final dy = point.dy - position.dy;
    final rotatedX = dx * math.cos(-rotation) - dy * math.sin(-rotation);
    final rotatedY = dx * math.sin(-rotation) + dy * math.cos(-rotation);

    return rotatedX >= -width / 2 &&
        rotatedX <= width / 2 &&
        rotatedY >= -height / 2 &&
        rotatedY <= height / 2;
  }

  void snapToWall(WallLine wall) {
    // Calculate wall angle
    final wallAngle = math.atan2(
      wall.end.dy - wall.start.dy,
      wall.end.dx - wall.start.dx,
    );

    // Snap rotation to wall
    rotation = wallAngle;

    // Get midpoint of the wall
    final midX = (wall.start.dx + wall.end.dx) / 2;
    final midY = (wall.start.dy + wall.end.dy) / 2;
    
    // Place element at midpoint
    position = Offset(midX, midY);

    // Offset position perpendicular to wall
    final perpAngle = wallAngle + math.pi / 2;
    position = Offset(
      position.dx + math.cos(perpAngle) * wall.thickness,
      position.dy + math.sin(perpAngle) * wall.thickness,
    );
  }
}

// ==================== MAIN EDITOR SCREEN ====================

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
  WallLine? selectedWall;
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
  bool _isDragging = false;
  Offset? _dragStartPosition;
  
  // Room counter
  int roomCounter = 1;
  
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
    // We'll add the first room in didChangeDependencies or first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rooms.isEmpty) {
        _addNewRoom();
      }
    });
  }

  void _addNewRoom() {
    // Default position in the center of the view
    var position = Offset(500, 400);
    
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
    
    // Generate walls
    newRoom.updateDimensions(newRoom.width, newRoom.height);
    
    setState(() {
      // Deselect all existing rooms
      for (var room in rooms) {
        room.selected = false;
      }
      
      // Add and select new room
      rooms.add(newRoom);
      selectedRoom = newRoom;
      selectedWall = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopToolbar(),
          Expanded(
            child: Row(
              children: [
                // Main Canvas
                Expanded(
                  child: _buildCanvas(),
                ),
                
                // Right Properties Panel (conditional)
                if (showRightPanel) 
                  SizedBox(
                    width: 300,
                    child: _buildRightPanel(),
                  ),
              ],
            ),
          ),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  // ==================== TOP TOOLBAR ====================
  
  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // App title
          Text(
            "Floor Plan Designer",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Project name
          InkWell(
            onTap: _renameProject,
            child: Row(
              children: [
                Text(
                  projectName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Tools
          _buildToolButton(EditorMode.select, Icons.pan_tool),
          _buildToolButton(EditorMode.room, Icons.dashboard),
          _buildToolButton(EditorMode.door, Icons.door_back_door),
          _buildToolButton(EditorMode.window, Icons.window),
          _buildToolButton(EditorMode.delete, Icons.delete),
          
          const SizedBox(width: 16),
          
          // Room tabs
          ..._buildRoomTabs(),
          
          const SizedBox(width: 8),
          
          // Add Room button
          ElevatedButton.icon(
            onPressed: _addNewRoom,
            icon: const Icon(Icons.add),
            label: const Text("Add Room"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Menu
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width, 
                  60, 
                  0, 
                  0
                ),
                items: [
                  const PopupMenuItem(
                    value: 'export_png',
                    child: Text('Export as PNG'),
                  ),
                  const PopupMenuItem(
                    value: 'export_pdf',
                    child: Text('Export as PDF'),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ],
              ).then((value) {
                if (value == 'settings') {
                  _openSettings();
                }
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolButton(EditorMode toolMode, IconData icon) {
    final isSelected = mode == toolMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(4),
        elevation: isSelected ? 2 : 1,
        child: InkWell(
          onTap: () => setState(() => mode = toolMode),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildRoomTabs() {
    if (rooms.isEmpty) {
      return [];
    }
    
    return rooms.map((room) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => _selectRoom(room),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: room.selected ? room.color : room.color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: room.selected ? Colors.black45 : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: room.selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _deleteRoom(room),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
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
                          child: Text(u.symbol),
                        ))
                    .toList(),
                onChanged: (MeasurementUnit? newUnit) {
                  if (newUnit != null) {
                    setState(() => unit = newUnit);
                  }
                },
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
  
  // ==================== RIGHT PANEL ====================
  
  Widget _buildRightPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedRoom != null
                      ? "Room Properties"
                      : selectedWall != null
                          ? "Wall Properties"
                          : selectedElement != null
                              ? "Element Properties"
                              : "Properties",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      showRightPanel = false;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Panel content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: selectedRoom != null
                    ? _buildRoomProperties(selectedRoom!)
                    : selectedWall != null
                        ? _buildWallProperties(selectedWall!)
                        : selectedElement != null
                            ? _buildElementProperties(selectedElement!)
                            : const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomProperties(Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room name
        const Text(
          "Room Name",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: room.name),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              room.name = value;
            });
          },
        ),
        
        const SizedBox(height: 24),
        
        // Dimensions
        const Text(
          "Dimensions",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Width
        Row(
          children: [
            const Text("Width:"),
            Expanded(
              child: Slider(
                value: room.width,
                min: 50,
                max: 500,
                divisions: 45,
                onChanged: (value) {
                  setState(() {
                    room.updateDimensions(value, room.height);
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                "${_formatLength(room.width * gridRealSize / gridSize)}",
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        
        // Height
        Row(
          children: [
            const Text("Height:"),
            Expanded(
              child: Slider(
                value: room.height,
                min: 50,
                max: 500,
                divisions: 45,
                onChanged: (value) {
                  setState(() {
                    room.updateDimensions(room.width, value);
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                "${_formatLength(room.height * gridRealSize / gridSize)}",
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Room color
        const Text(
          "Room Color",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roomColors.map((color) {
            final isSelected = room.color.value == color.value;
            return InkWell(
              onTap: () {
                setState(() {
                  room.color = color;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[400]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, color: Colors.black54)
                    : null,
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        // Room statistics
        const Text(
          "Room Statistics",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Walls: ${room.walls.length}"),
              Text("Elements: ${room.elements.length}"),
              Text("Area: ${_formatArea(room.width * room.height * math.pow(gridRealSize / gridSize, 2))}"),
              Text("Perimeter: ${_formatLength(2 * (room.width + room.height) * gridRealSize / gridSize)}"),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWallProperties(WallLine wall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Wall Thickness",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Slider(
          value: wall.thickness,
          min: 2.0,
          max: 12.0,
          divisions: 10,
          onChanged: (value) {
            setState(() {
              // Note: WallLine is immutable, so we replace it
              if (wall.room != null) {
                final room = wall.room!;
                final index = room.walls.indexOf(wall);
                if (index != -1) {
                  room.walls[index] = WallLine(
                    wall.start,
                    wall.end,
                    thickness: value,
                    room: wall.room,
                    isSelected: wall.isSelected,
                  );
                  
                  selectedWall = room.walls[index];
                }
              }
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Thin"),
            Text("${wall.thickness.toStringAsFixed(1)}px"),
            const Text("Thick"),
          ],
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          "Wall Measurements",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Length: ${_formatLength(wall.length * gridRealSize / gridSize)}"),
              const SizedBox(height: 8),
              Text("Start: (${(wall.start.dx * gridRealSize / gridSize).toStringAsFixed(2)}, ${(wall.start.dy * gridRealSize / gridSize).toStringAsFixed(2)})"),
              Text("End: (${(wall.end.dx * gridRealSize / gridSize).toStringAsFixed(2)}, ${(wall.end.dy * gridRealSize / gridSize).toStringAsFixed(2)})"),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        const Text(
          "Tip: You can drag the wall or its endpoints to reposition them.",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildElementProperties(ArchitecturalElement element) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Element type
        Text(
          element.type.label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        
        // Element name
        const Text(
          "Name",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: element.name ?? element.type.label),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              element.name = value;
            });
          },
        ),
        
        const SizedBox(height: 24),
        
        // Dimensions
        const Text(
          "Dimensions",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Width
        Row(
          children: [
            const Text("Width:"),
            Expanded(
              child: Slider(
                value: element.width,
                min: 10,
                max: 100,
                divisions: 18,
                onChanged: (value) {
                  setState(() {
                    element.width = value;
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                "${_formatLength(element.width * gridRealSize / gridSize)}",
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        
        // Depth
        Row(
          children: [
            const Text("Depth:"),
            Expanded(
              child: Slider(
                value: element.height,
                min: 4,
                max: 20,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    element.height = value;
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                "${_formatLength(element.height * gridRealSize / gridSize)}",
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Rotation
        const Text(
          "Rotation",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: Slider(
                value: element.rotation,
                min: 0,
                max: 2 * math.pi,
                divisions: 24,
                onChanged: (value) {
                  setState(() {
                    element.rotation = value;
                  });
                },
              ),
            ),
            Text("${(element.rotation * 180 / math.pi).round()}°"),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  element.rotation = (element.rotation + math.pi / 2) % (2 * math.pi);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Icon(Icons.rotate_90_degrees_cw, size: 20),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Position info
        const Text(
          "Position",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("X: ${_formatLength(element.position.dx * gridRealSize / gridSize)}"),
              Text("Y: ${_formatLength(element.position.dy * gridRealSize / gridSize)}"),
              if (element.room != null)
                Text("Room: ${element.room!.name}"),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        const Text(
          "Tip: You can drag the element to reposition it.",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  // ==================== BOTTOM TOOLBAR ====================
  
  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Grid size control
          Text(
            "Grid:",
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Slider(
              value: gridSize,
              min: 10,
              max: 50,
              divisions: 8,
              onChanged: (value) {
                setState(() {
                  gridSize = value;
                });
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Zoom controls
          Text(
            "Zoom:",
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _handleZoom(1.2),
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _handleZoom(0.8),
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _resetView,
            iconSize: 20,
          ),
          
          const SizedBox(width: 16),
          
          // Grid & measurements toggles
          IconButton(
            icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () {
              setState(() {
                showGrid = !showGrid;
              });
            },
            iconSize: 20,
            tooltip: showGrid ? 'Hide Grid' : 'Show Grid',
          ),
          IconButton(
            icon: Icon(showMeasurements ? Icons.straighten : Icons.space_bar),
            onPressed: () {
              setState(() {
                showMeasurements = !showMeasurements;
              });
            },
            iconSize: 20,
            tooltip: showMeasurements ? 'Hide Measurements' : 'Show Measurements',
          ),
          
          const Spacer(),
          
          // Editor status
          Text(
            "Editing: ${selectedRoom?.name ?? (selectedWall != null ? "Wall" : (selectedElement != null ? selectedElement!.type.label : "Nothing selected"))}",
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CANVAS ====================
  
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
              selectedWall: selectedWall,
              selectedElement: selectedElement,
              selectedRoom: selectedRoom,
              gridSize: gridSize,
              gridRealSize: gridRealSize,
              unit: unit,
              showGrid: showGrid,
              showMeasurements: showMeasurements,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== INTERACTION HANDLERS ====================
  
  void _selectRoom(Room room) {
    setState(() {
      // Deselect all rooms
      for (var r in rooms) {
        r.selected = false;
      }
      
      // Select the new room
      room.selected = true;
      selectedRoom = room;
      selectedWall = null;
      selectedElement = null;
      showRightPanel = true;
    });
  }
  
  void _handlePointerDown(PointerDownEvent event) {
    final point = _transformPoint(event.localPosition);
    
    if (mode == EditorMode.select) {
      // Try to find element under pointer
      ArchitecturalElement? element = _findElementAt(point);
      if (element != null) {
        setState(() {
          _isDragging = true;
          _dragStartPosition = point;
          element.isDragging = true;
          
          selectedElement = element;
          selectedWall = null;
          selectedRoom = null;
          showRightPanel = true;
        });
        return;
      }
      
      // Try to find wall or wall endpoint
      WallLine? wall = _findWallAt(point);
      if (wall != null) {
        bool isNearStart = wall.isPointNearStart(point, 10.0);
        bool isNearEnd = wall.isPointNearEnd(point, 10.0);
        
        setState(() {
          _isDragging = true;
          _dragStartPosition = point;
          wall.isDragging = true;
          
          if (isNearStart) {
            wall.isStartDragging = true;
          } else if (isNearEnd) {
            wall.isEndDragging = true;
          }
          
          selectedWall = wall;
          selectedElement = null;
          selectedRoom = null;
          showRightPanel = true;
        });
        return;
      }
      
      // Try to find room
      Room? room = _findRoomAt(point);
      if (room != null) {
        setState(() {
          _isDragging = true;
          _dragStartPosition = point;
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
        selectedWall = null;
        selectedElement = null;
        showRightPanel = false;
      });
    }
    else if (mode == EditorMode.door || mode == EditorMode.window) {
      // Try to find wall to add element
      WallLine? wall = _findWallAt(point);
      if (wall != null) {
        _addElementToWall(
          wall, 
          mode == EditorMode.door 
              ? ArchitecturalElementType.door 
              : ArchitecturalElementType.window
        );
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
  }
  
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDragging || _dragStartPosition == null) return;
    
    final point = _transformPoint(event.localPosition);
    final delta = point - _dragStartPosition!;
    
    // Skip if there's no movement
    if (delta == Offset.zero) return;
    
    setState(() {
      if (selectedElement != null && selectedElement!.isDragging) {
        // Move element
        selectedElement!.position += delta;
      }
      else if (selectedWall != null && selectedWall!.isDragging) {
        if (selectedWall!.isStartDragging) {
          // Move wall start point
          selectedWall!.start += delta;
        }
        else if (selectedWall!.isEndDragging) {
          // Move wall end point
          selectedWall!.end += delta;
        }
        else {
          // Move entire wall
          selectedWall!.start += delta;
          selectedWall!.end += delta;
        }
      }
      else if (selectedRoom != null && selectedRoom!.isDragging) {
        // Move room and all its elements
        selectedRoom!.move(delta);
      }
      
      _dragStartPosition = point;
    });
  }
  
  void _handlePointerUp(PointerUpEvent event) {
    // Snap positions on release
    if (_isDragging) {
      setState(() {
        if (selectedElement != null && selectedElement!.isDragging) {
          // Snap element position
          selectedElement!.position = _snapToGrid(selectedElement!.position);
          selectedElement!.isDragging = false;
        }
        else if (selectedWall != null && selectedWall!.isDragging) {
          if (selectedWall!.isStartDragging) {
            // Snap wall start point
            selectedWall!.start = _snapToGrid(selectedWall!.start);
            selectedWall!.isStartDragging = false;
          }
          else if (selectedWall!.isEndDragging) {
            // Snap wall end point
            selectedWall!.end = _snapToGrid(selectedWall!.end);
            selectedWall!.isEndDragging = false;
          }
          else {
            // Snap entire wall
            selectedWall!.start = _snapToGrid(selectedWall!.start);
            selectedWall!.end = _snapToGrid(selectedWall!.end);
          }
          selectedWall!.isDragging = false;
        }
        else if (selectedRoom != null && selectedRoom!.isDragging) {
          // Snap room position
          selectedRoom!.position = _snapToGrid(selectedRoom!.position);
          selectedRoom!.updateDimensions(selectedRoom!.width, selectedRoom!.height);
          selectedRoom!.isDragging = false;
        }
        
        _isDragging = false;
        _dragStartPosition = null;
      });
    }
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
  
  // Finds wall at given point
  WallLine? _findWallAt(Offset point) {
    for (var room in rooms) {
      for (var wall in room.walls) {
        if (wall.containsPoint(point, 10.0)) {
          return wall;
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
  
  // Adds new element to wall
  void _addElementToWall(WallLine wall, ArchitecturalElementType type) {
    // Create element at wall midpoint
    final element = ArchitecturalElement(
      type: type,
      position: wall.midPoint,
      room: wall.room,
    );
    
    // Snap to wall
    element.snapToWall(wall);
    
    setState(() {
      if (wall.room != null) {
        wall.room!.elements.add(element);
        
        // Select the new element
        selectedElement = element;
        selectedWall = null;
        selectedRoom = null;
        showRightPanel = true;
        
        // Switch to select mode
        mode = EditorMode.select;
      }
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

  // ==================== UTILITY METHODS ====================
  
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

  String _formatLength(double meters) {
    final converted = meters * unit.conversionFromMeters;
    return '${converted.toStringAsFixed(2)}${unit.symbol}';
  }
  
  String _formatArea(double squareMeters) {
    switch (unit) {
      case MeasurementUnit.meters:
        return '${squareMeters.toStringAsFixed(2)}m²';
      case MeasurementUnit.feet:
        final sqft = squareMeters * 10.7639;
        return '${sqft.toStringAsFixed(2)}ft²';
      case MeasurementUnit.inches:
        final sqin = squareMeters * 1550;
        return '${sqin.toStringAsFixed(2)}in²';
    }
  }
}

// ==================== PAINTER ====================

class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final WallLine? selectedWall;
  final ArchitecturalElement? selectedElement;
  final Room? selectedRoom;
  final double gridSize;
  final double gridRealSize;
  final MeasurementUnit unit;
  final bool showGrid;
  final bool showMeasurements;

  FloorPlanPainter({
    required this.rooms,
    this.selectedWall,
    this.selectedElement,
    this.selectedRoom,
    required this.gridSize,
    required this.gridRealSize,
    required this.unit,
    this.showGrid = true,
    this.showMeasurements = true,
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

    // Fixed: Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Fixed: Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),  // FIXED: This was the problem
        gridPaint,
      );
    }
  }
  
  void _drawRoomBackground(Canvas canvas, Room room) {
    // Only draw closed rooms (with 4+ walls)
    if (room.walls.length < 3) return;
    
    // Use a rectangle for the room background
    final rect = Rect.fromCenter(
      center: room.position,
      width: room.width,
      height: room.height,
    );
    
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
    for (var wall in room.walls) {
      // Determine wall style
      final paint = Paint()
        ..color = (wall == selectedWall) ? Colors.blue : Colors.black
        ..strokeWidth = wall.thickness
        ..strokeCap = StrokeCap.butt;
      
      // Draw wall
      canvas.drawLine(wall.start, wall.end, paint);
      
      // Draw wall endpoints if selected or dragging
      if (wall == selectedWall || wall.isDragging) {
        final handlePaint = Paint()
          ..color = Colors.red
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(wall.start, 6.0, handlePaint);
        canvas.drawCircle(wall.end, 6.0, handlePaint);
      }
      
      // Draw wall measurement if enabled
      if (showMeasurements) {
        _drawWallMeasurement(canvas, wall);
      }
    }
  }
  
  void _drawWallMeasurement(Canvas canvas, WallLine wall) {
    // Calculate length in real units
    final length = wall.length * gridRealSize / gridSize;
    final formattedLength = '${(length * unit.conversionFromMeters).toStringAsFixed(2)}${unit.symbol}';
    
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
    final midX = (wall.start.dx + wall.end.dx) / 2;
    final midY = (wall.start.dy + wall.end.dy) / 2;
    
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
      if (element.type == ArchitecturalElementType.door) {
        _drawDoor(canvas, element, paint);
      } else if (element.type == ArchitecturalElementType.window) {
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
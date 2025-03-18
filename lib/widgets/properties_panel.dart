import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/room.dart';
import '../models/element.dart';
import '../models/enums.dart';
import '../utils/measurement_utils.dart';

class PropertiesPanel extends StatefulWidget {
  final Room? selectedRoom;
  final ArchitecturalElement? selectedElement;
  final List<Color> roomColors;
  final Function(Room, double) onRoomWidthChanged;
  final Function(Room, double) onRoomHeightChanged;
  final Function(Room, Color) onRoomColorChanged;
  final Function(Room, String) onRoomNameChanged;
  final Function(ArchitecturalElement, String) onElementNameChanged;
  final Function(ArchitecturalElement, double) onElementWidthChanged;
  final Function(ArchitecturalElement, double) onElementHeightChanged;
  final Function(ArchitecturalElement, double) onElementRotationChanged;
  final VoidCallback onPanelClosed;
  final double gridSize;
  final double gridRealSize;
  final MeasurementUnit unit;

  const PropertiesPanel({
    super.key,
    required this.selectedRoom,
    required this.selectedElement,
    required this.roomColors,
    required this.onRoomWidthChanged,
    required this.onRoomHeightChanged,
    required this.onRoomColorChanged,
    required this.onRoomNameChanged,
    required this.onElementNameChanged,
    required this.onElementWidthChanged,
    required this.onElementHeightChanged,
    required this.onElementRotationChanged,
    required this.onPanelClosed,
    required this.gridSize,
    required this.gridRealSize,
    required this.unit,
  });

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  late TextEditingController _roomNameController;
  late TextEditingController _roomWidthController;
  late TextEditingController _roomHeightController;
  late List<TextEditingController> _wallHeightControllers;
  late List<TextEditingController> _wallBreadthControllers;
  late TextEditingController _elementNameController;
  late TextEditingController _elementWidthController;
  late TextEditingController _elementHeightController;
  late TextEditingController _elementRotationController;
  
  @override
  void initState() {
    super.initState();
    _initControllers();
  }
  
  @override
  void didUpdateWidget(PropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reinitialize controllers when selected objects change
    if (oldWidget.selectedRoom != widget.selectedRoom || 
        oldWidget.selectedElement != widget.selectedElement) {
      _disposeControllers();
      _initControllers();
    }
  }
  
  void _initControllers() {
    // Room controllers
    _roomNameController = TextEditingController(
      text: widget.selectedRoom?.name ?? ''
    );
    
    _roomWidthController = TextEditingController(
      text: _formatGridUnits(widget.selectedRoom?.width ?? 0)
    );
    
    _roomHeightController = TextEditingController(
      text: _formatGridUnits(widget.selectedRoom?.height ?? 0)
    );
    
    // Wall controllers
    _wallHeightControllers = List.generate(
      4, 
      (index) => TextEditingController(
        text: widget.selectedRoom != null 
            ? widget.selectedRoom!.walls[index].height.toStringAsFixed(2)
            : '2.40'
      )
    );
    
    _wallBreadthControllers = List.generate(
      4, 
      (index) => TextEditingController(
        text: widget.selectedRoom != null 
            ? widget.selectedRoom!.walls[index].breadth.toStringAsFixed(2)
            : '0.15'
      )
    );
    
    // Element controllers
    _elementNameController = TextEditingController(
      text: widget.selectedElement?.name ?? 
            widget.selectedElement?.type.label ?? ''
    );
    
    _elementWidthController = TextEditingController(
      text: _formatGridUnits(widget.selectedElement?.width ?? 0)
    );
    
    _elementHeightController = TextEditingController(
      text: _formatGridUnits(widget.selectedElement?.height ?? 0)
    );
    
    _elementRotationController = TextEditingController(
      text: widget.selectedElement != null
          ? (widget.selectedElement!.rotation * 180 / math.pi).toStringAsFixed(1)
          : '0'
    );
  }
  
  void _disposeControllers() {
    _roomNameController.dispose();
    _roomWidthController.dispose();
    _roomHeightController.dispose();
    for (var controller in _wallHeightControllers) {
      controller.dispose();
    }
    for (var controller in _wallBreadthControllers) {
      controller.dispose();
    }
    _elementNameController.dispose();
    _elementWidthController.dispose();
    _elementHeightController.dispose();
    _elementRotationController.dispose();
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  // Format grid units to real-world units
  String _formatGridUnits(double gridUnits) {
    final realUnits = gridUnits * widget.gridRealSize / widget.gridSize;
    return realUnits.toStringAsFixed(2);
  }
  
  // Convert real-world units back to grid units
  double _parseToGridUnits(String realUnitsStr) {
    final double realUnits = double.tryParse(realUnitsStr) ?? 0;
    return realUnits * widget.gridSize / widget.gridRealSize;
  }
  
  // Update wall property and refresh UI
  void _updateWallProperty(int wallIndex, String property, String value) {
    if (widget.selectedRoom == null) return;
    
    setState(() {
      double? doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        if (property == 'height') {
          widget.selectedRoom!.walls[wallIndex].height = doubleValue;
        } else if (property == 'breadth') {
          widget.selectedRoom!.walls[wallIndex].breadth = doubleValue;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  widget.selectedRoom != null
                      ? "Room Properties"
                      : widget.selectedElement != null
                          ? "Element Properties"
                          : "Properties",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onPanelClosed,
                ),
              ],
            ),
          ),
          
          // Panel content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.selectedRoom != null
                    ? _buildRoomProperties(widget.selectedRoom!)
                    : widget.selectedElement != null
                        ? _buildElementProperties(widget.selectedElement!)
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
          controller: _roomNameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) => widget.onRoomNameChanged(room, value),
        ),
        
        const SizedBox(height: 24),
        
        // Dimensions
        const Text(
          "Room Dimensions",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Width
        Row(
          children: [
            const SizedBox(width: 80, child: Text("Width:")),
            Expanded(
              child: TextField(
                controller: _roomWidthController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixText: widget.unit.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final double? parsed = double.tryParse(value);
                  if (parsed != null) {
                    final gridUnits = _parseToGridUnits(value);
                    widget.onRoomWidthChanged(room, gridUnits);
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Height
        Row(
          children: [
            const SizedBox(width: 80, child: Text("Height:")),
            Expanded(
              child: TextField(
                controller: _roomHeightController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixText: widget.unit.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final double? parsed = double.tryParse(value);
                  if (parsed != null) {
                    final gridUnits = _parseToGridUnits(value);
                    widget.onRoomHeightChanged(room, gridUnits);
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Wall properties
        const Text(
          "Wall Properties",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Wall properties list
        ...List.generate(4, (index) => _buildWallProperties(room, index)),
        
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
          children: widget.roomColors.map((color) {
            final isSelected = room.color.value == color.value;
            return InkWell(
              onTap: () => widget.onRoomColorChanged(room, color),
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
              Text("Elements: ${room.elements.length}"),
              Text("Floor Area: ${MeasurementUtils.formatArea(room.getArea(widget.gridSize, widget.gridRealSize), widget.unit)}"),
              Text("Perimeter: ${MeasurementUtils.formatLength(room.getPerimeter(widget.gridSize, widget.gridRealSize), widget.unit)}"),
              
              const SizedBox(height: 8),
              const Text("Wall Areas:", style: TextStyle(fontWeight: FontWeight.bold)),
              
              ...List.generate(4, (index) {
                final wallLengths = room.getWallRealLengths(widget.gridSize, widget.gridRealSize);
                final wallArea = room.getWallArea(index, widget.gridSize, widget.gridRealSize);
                
                return Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${room.getWallDescriptions()[index]}: "),
                      Text("${MeasurementUtils.formatArea(wallArea, widget.unit)} ")
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 8),
              // Show shared walls info
              if (room.sharedWalls.isNotEmpty) ...[
                const Text("Shared Walls:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...room.sharedWalls.map((connection) {
                  final otherRoom = connection.$1;
                  final thisWallIndex = connection.$2;
                  final thisWallName = room.getWallDescriptions()[thisWallIndex];
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text("$thisWallName shared with ${otherRoom.name}"),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWallProperties(Room room, int wallIndex) {
    final wallName = room.getWallDescriptions()[wallIndex];
    final wallLengths = room.getWallRealLengths(widget.gridSize, widget.gridRealSize);
    final wallLength = wallLengths[wallIndex];
    final wallArea = room.getWallArea(wallIndex, widget.gridSize, widget.gridRealSize);
    final isShared = room.isWallShared(wallIndex);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isShared ? Colors.purple.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isShared ? Colors.purple.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isShared)
                const Text(
                  "Shared",
                  style: TextStyle(
                    color: Colors.purple,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Wall length (not editable - derived from room dimensions)
          Row(
            children: [
              const SizedBox(width: 80, child: Text("Length:")),
              Expanded(
                child: Text(
                  "${wallLength.toStringAsFixed(2)} ${widget.unit.symbol}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Wall height
          Row(
            children: [
              const SizedBox(width: 80, child: Text("Height:")),
              Expanded(
                child: TextField(
                  controller: _wallHeightControllers[wallIndex],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixText: widget.unit.symbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) => _updateWallProperty(wallIndex, 'height', value),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Wall breadth (thickness)
          Row(
            children: [
              const SizedBox(width: 80, child: Text("Thickness:")),
              Expanded(
                child: TextField(
                  controller: _wallBreadthControllers[wallIndex],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixText: widget.unit.symbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) => _updateWallProperty(wallIndex, 'breadth', value),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Wall area
          Row(
            children: [
              const SizedBox(width: 90, child: Text("Area:")), 
              Expanded(
                child: Text(
                  "${MeasurementUtils.formatArea(wallArea, widget.unit)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500, 
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          controller: _elementNameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) => widget.onElementNameChanged(element, value),
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
            const SizedBox(width: 80, child: Text("Width:")),
            Expanded(
              child: TextField(
                controller: _elementWidthController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixText: widget.unit.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final double? parsed = double.tryParse(value);
                  if (parsed != null) {
                    final gridUnits = _parseToGridUnits(value);
                    widget.onElementWidthChanged(element, gridUnits);
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Depth/Height
        Row(
          children: [
            const SizedBox(width: 80, child: Text("Depth:")),
            Expanded(
              child: TextField(
                controller: _elementHeightController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixText: widget.unit.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final double? parsed = double.tryParse(value);
                  if (parsed != null) {
                    final gridUnits = _parseToGridUnits(value);
                    widget.onElementHeightChanged(element, gridUnits);
                  }
                },
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
            const SizedBox(width: 80, child: Text("Angle:")),
            Expanded(
              child: TextField(
                controller: _elementRotationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixText: "°",
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final double? parsed = double.tryParse(value);
                  if (parsed != null) {
                    // Convert degrees to radians
                    final radians = parsed * math.pi / 180;
                    widget.onElementRotationChanged(element, radians);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                // Rotate by 90 degrees
                final currentDegrees = double.tryParse(_elementRotationController.text) ?? 0;
                final newDegrees = (currentDegrees + 90) % 360;
                _elementRotationController.text = newDegrees.toStringAsFixed(1);
                
                // Convert to radians and update
                final radians = newDegrees * math.pi / 180;
                widget.onElementRotationChanged(element, radians);
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
              Text("X: ${MeasurementUtils.formatLength(element.position.dx * widget.gridRealSize / widget.gridSize, widget.unit)}"),
              Text("Y: ${MeasurementUtils.formatLength(element.position.dy * widget.gridRealSize / widget.gridSize, widget.unit)}"),
              
              if (element.room != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Room: ${element.room!.name}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
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
}
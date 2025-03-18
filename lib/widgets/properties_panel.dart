import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/room.dart';
import '../models/element.dart';
import '../models/enums.dart';
import '../utils/measurement_utils.dart';

class PropertiesPanel extends StatelessWidget {
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
                  selectedRoom != null
                      ? "Room Properties"
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
                  onPressed: onPanelClosed,
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
          onChanged: (value) => onRoomNameChanged(room, value),
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
                onChanged: (value) => onRoomWidthChanged(room, value),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                MeasurementUtils.formatLength(
                  room.width * gridRealSize / gridSize, 
                  unit
                ),
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
                onChanged: (value) => onRoomHeightChanged(room, value),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                MeasurementUtils.formatLength(
                  room.height * gridRealSize / gridSize, 
                  unit
                ),
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
              onTap: () => onRoomColorChanged(room, color),
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
              Text("Area: ${MeasurementUtils.formatArea(room.getArea(gridSize, gridRealSize), unit)}"),
              Text("Perimeter: ${MeasurementUtils.formatLength(room.getPerimeter(gridSize, gridRealSize), unit)}"),
            ],
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
          onChanged: (value) => onElementNameChanged(element, value),
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
                onChanged: (value) => onElementWidthChanged(element, value),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                MeasurementUtils.formatLength(
                  element.width * gridRealSize / gridSize,
                  unit
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        
        // Depth/Height
        Row(
          children: [
            const Text("Depth:"),
            Expanded(
              child: Slider(
                value: element.height,
                min: 4,
                max: 20,
                divisions: 8,
                onChanged: (value) => onElementHeightChanged(element, value),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                MeasurementUtils.formatLength(
                  element.height * gridRealSize / gridSize,
                  unit
                ),
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
                onChanged: (value) => onElementRotationChanged(element, value),
              ),
            ),
            Text("${(element.rotation * 180 / math.pi).round()}°"),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => onElementRotationChanged(
                element, 
                (element.rotation + math.pi / 2) % (2 * math.pi)
              ),
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
              Text("X: ${MeasurementUtils.formatLength(element.position.dx * gridRealSize / gridSize, unit)}"),
              Text("Y: ${MeasurementUtils.formatLength(element.position.dy * gridRealSize / gridSize, unit)}"),
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
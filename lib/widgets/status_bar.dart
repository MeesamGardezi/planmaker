import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/element.dart';

class StatusBar extends StatelessWidget {
  final double gridSize;
  final bool showGrid;
  final bool showMeasurements;
  final Room? selectedRoom;
  final ArchitecturalElement? selectedElement;
  final Function(double) onGridSizeChanged;
  final VoidCallback onGridToggled;
  final VoidCallback onMeasurementsToggled;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;

  const StatusBar({
    super.key,
    required this.gridSize,
    required this.showGrid,
    required this.showMeasurements,
    required this.selectedRoom,
    required this.selectedElement,
    required this.onGridSizeChanged,
    required this.onGridToggled,
    required this.onMeasurementsToggled,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
  });

  @override
  Widget build(BuildContext context) {
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
              onChanged: onGridSizeChanged,
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
            onPressed: onZoomIn,
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: onZoomOut,
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: onResetView,
            iconSize: 20,
          ),
          
          const SizedBox(width: 16),
          
          // Grid & measurements toggles
          IconButton(
            icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: onGridToggled,
            iconSize: 20,
            tooltip: showGrid ? 'Hide Grid' : 'Show Grid',
          ),
          IconButton(
            icon: Icon(showMeasurements ? Icons.straighten : Icons.space_bar),
            onPressed: onMeasurementsToggled,
            iconSize: 20,
            tooltip: showMeasurements ? 'Hide Measurements' : 'Show Measurements',
          ),
          
          const Spacer(),
          
          // Editor status
          Text(
            "Editing: ${selectedRoom?.name ?? (selectedElement != null ? selectedElement!.type.label : "Nothing selected")}",
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
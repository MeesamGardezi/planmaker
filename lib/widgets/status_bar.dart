import 'package:flutter/material.dart';
import '../models/measurements.dart';
import '../models/room.dart';
import '../models/element.dart';
import '../models/enums.dart';

class StatusBar extends StatelessWidget {
  final bool showGrid;
  final bool showMeasurements;
  final Room? selectedRoom;
  final ArchitecturalElement? selectedElement;
  final VoidCallback onGridToggled;
  final VoidCallback onMeasurementsToggled;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;
  final VoidCallback? onClearMeasurements;
  final SnapType snapType;
  final EditorMode currentMode;
  final List<Measurement> measurements;

  const StatusBar({
    super.key,
    required this.showGrid,
    required this.showMeasurements,
    required this.selectedRoom,
    required this.selectedElement,
    required this.onGridToggled,
    required this.onMeasurementsToggled,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    this.onClearMeasurements,
    this.snapType = SnapType.none,
    required this.currentMode,
    this.measurements = const [],
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
          
          // Clear measurements button (visible only in measure mode)
          if (currentMode == EditorMode.measure && measurements.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: onClearMeasurements,
              iconSize: 20,
              tooltip: 'Clear Measurements',
              color: Colors.red[700],
            ),
          
          const Spacer(),
          
          // Mode indicator
          _buildModeIndicator(),
          
          const SizedBox(width: 12),
          
          // Snap type indicator
          _buildSnapTypeIndicator(),
          
          const SizedBox(width: 16),
          
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
  
  // Build mode indicator widget
  Widget _buildModeIndicator() {
    Color modeColor;
    IconData modeIcon;
    
    switch (currentMode) {
      case EditorMode.select:
        return const SizedBox(); // Don't show for select mode
      case EditorMode.room:
        modeColor = Colors.teal;
        modeIcon = Icons.dashboard;
        break;
      case EditorMode.door:
        modeColor = Colors.orange;
        modeIcon = Icons.door_back_door;
        break;
      case EditorMode.window:
        modeColor = Colors.lightBlue;
        modeIcon = Icons.window;
        break;
      case EditorMode.delete:
        modeColor = Colors.red;
        modeIcon = Icons.delete;
        break;
      case EditorMode.line:
        modeColor = Colors.blue;
        modeIcon = Icons.timeline;
        break;
      case EditorMode.measure:
        modeColor = Colors.purple;
        modeIcon = Icons.straighten;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: modeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: modeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(modeIcon, size: 16, color: modeColor),
          const SizedBox(width: 4),
          Text(
            currentMode.label,
            style: TextStyle(
              color: modeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the snap type indicator
  Widget _buildSnapTypeIndicator() {
    if (snapType == SnapType.none) {
      return const SizedBox(); // Don't show anything when no snapping
    }
    
    Color indicatorColor;
    IconData indicatorIcon;
    String indicatorText;
    
    switch (snapType) {
      case SnapType.corner:
        indicatorColor = Colors.blue;
        indicatorIcon = Icons.fullscreen_exit;
        indicatorText = "Corner Snap";
        break;
      case SnapType.wall:
        indicatorColor = Colors.green;
        indicatorIcon = Icons.horizontal_rule;
        indicatorText = "Wall Snap";
        break;
      default:
        return const SizedBox();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: indicatorColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, color: indicatorColor, size: 16),
          const SizedBox(width: 4),
          Text(
            indicatorText,
            style: TextStyle(
              color: indicatorColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
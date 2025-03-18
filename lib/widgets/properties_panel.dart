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
        oldWidget.selectedElement != widget.selectedElement ||
        oldWidget.unit != widget.unit) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    // Room controllers
    _roomNameController =
        TextEditingController(text: widget.selectedRoom?.name ?? '');

    // Room width in current units (not pixels)
    _roomWidthController = TextEditingController(
        text: widget.selectedRoom != null
            ? _pixelsToCurrentUnit(widget.selectedRoom!.width)
                .toStringAsFixed(2)
            : '');

    // Room height in current units (not pixels)
    _roomHeightController = TextEditingController(
        text: widget.selectedRoom != null
            ? _pixelsToCurrentUnit(widget.selectedRoom!.height)
                .toStringAsFixed(2)
            : '');

    // Wall controllers
    _wallHeightControllers = List.generate(
        4,
        (index) => TextEditingController(
            text: widget.selectedRoom != null
                ? widget.selectedRoom!.walls[index].height.toStringAsFixed(2)
                : '8.00'));

    // Element controllers
    _elementNameController = TextEditingController(
        text: widget.selectedElement?.name ??
            widget.selectedElement?.type.label ??
            '');

    // Element width in current units (not pixels)
    _elementWidthController = TextEditingController(
        text: widget.selectedElement != null
            ? _pixelsToCurrentUnit(widget.selectedElement!.width)
                .toStringAsFixed(2)
            : '');

    // Element height in current units (not pixels)
    _elementHeightController = TextEditingController(
        text: widget.selectedElement != null
            ? _pixelsToCurrentUnit(widget.selectedElement!.height)
                .toStringAsFixed(2)
            : '');

    _elementRotationController = TextEditingController(
        text: widget.selectedElement != null
            ? (widget.selectedElement!.rotation * 180 / math.pi)
                .toStringAsFixed(1)
            : '0');
  }

  void _disposeControllers() {
    _roomNameController.dispose();
    _roomWidthController.dispose();
    _roomHeightController.dispose();
    for (var controller in _wallHeightControllers) {
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

  // Convert pixels to current unit system (e.g., feet)
  double _pixelsToCurrentUnit(double pixelValue) {
    return MeasurementUtils.gridToReal(
        pixelValue, widget.gridSize, widget.gridRealSize);
  }

  // Convert current unit (e.g., feet) to pixels
  double _currentUnitToPixels(double unitValue) {
    return MeasurementUtils.realToGrid(
        unitValue, widget.gridSize, widget.gridRealSize);
  }

  // Update wall property and refresh UI
  void _updateWallHeight(int wallIndex, String value) {
    if (widget.selectedRoom == null) return;

    setState(() {
      double? doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        widget.selectedRoom!.walls[wallIndex].height = doubleValue;
      }
    });
  }

  // Calculate wall area
  String _calculateWallArea(Room room, int wallIndex) {
    final wallLengths =
        room.getWallRealLengths(widget.gridSize, widget.gridRealSize);
    final wallLength = wallLengths[wallIndex];
    final wallHeight = room.walls[wallIndex].height;
    final area = wallLength * wallHeight;
    return "${area.toStringAsFixed(2)} ${widget.unit.symbol}²";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, // Reduced panel width
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onPanelClosed,
                ),
              ],
            ),
          ),

          // Panel content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: widget.selectedRoom != null
                  ? _buildRoomProperties(widget.selectedRoom!)
                  : widget.selectedElement != null
                      ? _buildElementProperties(widget.selectedElement!)
                      : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomProperties(Room room) {
    final roomArea =
        _pixelsToCurrentUnit(room.width) * _pixelsToCurrentUnit(room.height);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room name and basic info in one row
        Row(
          children: [
            // Room name takes 75% of space
            Expanded(
              flex: 3,
              child: TextField(
                controller: _roomNameController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: const OutlineInputBorder(),
                  labelText: "Room Name",
                  labelStyle: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (value) => widget.onRoomNameChanged(room, value),
              ),
            ),
            const SizedBox(width: 4),
            // Room area takes 25% of space
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Area",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700]),
                    ),
                    Text(
                      "${roomArea.toStringAsFixed(2)} ${widget.unit.symbol}²",
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Dimensions in one row
        Row(
          children: [
            // Width
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Width",
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _roomWidthController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      border: const OutlineInputBorder(),
                      suffixText: widget.unit.symbol,
                      suffixStyle:
                          TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final double? parsed = double.tryParse(value);
                      if (parsed != null) {
                        final gridUnits = _currentUnitToPixels(parsed);
                        widget.onRoomWidthChanged(room, gridUnits);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Height
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Height",
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _roomHeightController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      border: const OutlineInputBorder(),
                      suffixText: widget.unit.symbol,
                      suffixStyle:
                          TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final double? parsed = double.tryParse(value);
                      if (parsed != null) {
                        final gridUnits = _currentUnitToPixels(parsed);
                        widget.onRoomHeightChanged(room, gridUnits);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        // Room color section
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.color_lens, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              "Room Color",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Color grid in one row
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.roomColors.map((color) {
            final isSelected = room.color.value == color.value;
            return InkWell(
              onTap: () => widget.onRoomColorChanged(room, color),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[400]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.black54, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),

        // Wall properties section
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.straighten, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              "Wall Properties",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Wall properties
        ...List.generate(
            4, (index) => _buildCompactWallProperties(room, index)),

        // Elements in room
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.door_back_door, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              "Elements (${room.elements.length})",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // If there are elements, list them
        if (room.elements.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 4),
            itemCount: room.elements.length,
            itemBuilder: (context, index) {
              final element = room.elements[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      element.type == ElementType.door
                          ? Icons.door_back_door
                          : Icons.window,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        element.name ?? element.type.label,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${_pixelsToCurrentUnit(element.width).toStringAsFixed(1)} × ${_pixelsToCurrentUnit(element.height).toStringAsFixed(1)} ${widget.unit.symbol}",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "No elements in this room",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactWallProperties(Room room, int wallIndex) {
    final wallName = room.getShortWallDescriptions()[wallIndex];
    final wallLengths =
        room.getWallRealLengths(widget.gridSize, widget.gridRealSize);
    final wallLength = wallLengths[wallIndex];
    final wallArea = _calculateWallArea(room, wallIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wall name
          Text(
            wallName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // All measurements in one row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Height label and input
              Text(
                "H: ",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _wallHeightControllers[wallIndex],
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: InputBorder.none,
                      suffixText: widget.unit.symbol,
                      suffixStyle:
                          TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    style: const TextStyle(fontSize: 10),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) => _updateWallHeight(wallIndex, value),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Length label and display
              Text(
                "L: ",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 25,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${wallLength.toStringAsFixed(1)} ${widget.unit.symbol}",
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Area label and display
              Text(
                "A: ",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 25,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    wallArea,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
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
        // Element type and name in one row
        Row(
          children: [
            // Element type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    element.type == ElementType.door
                        ? Icons.door_back_door
                        : Icons.window,
                    size: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    element.type.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Show room name if element is in a room
            if (element.room != null)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, size: 10, color: Colors.grey[700]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          element.room!.name,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Element name
        TextField(
          controller: _elementNameController,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: const OutlineInputBorder(),
            labelText: "Element Name",
            labelStyle: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) => widget.onElementNameChanged(element, value),
        ),

        const SizedBox(height: 12),

        // Position in one row
        Row(
          children: [
            Icon(Icons.place, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              "Position: ",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "X: ${_pixelsToCurrentUnit(element.position.dx).toStringAsFixed(1)} ${widget.unit.symbol}, ",
              style: const TextStyle(fontSize: 10),
            ),
            Text(
              "Y: ${_pixelsToCurrentUnit(element.position.dy).toStringAsFixed(1)} ${widget.unit.symbol}",
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Dimensions in one row
        Row(
          children: [
            // Width
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Width",
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _elementWidthController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      border: const OutlineInputBorder(),
                      suffixText: widget.unit.symbol,
                      suffixStyle:
                          TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                    style: const TextStyle(fontSize: 11),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final double? parsed = double.tryParse(value);
                      if (parsed != null) {
                        final gridUnits = _currentUnitToPixels(parsed);
                        widget.onElementWidthChanged(element, gridUnits);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Depth/Height
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Depth",
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _elementHeightController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      border: const OutlineInputBorder(),
                      suffixText: widget.unit.symbol,
                      suffixStyle:
                          TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                    style: const TextStyle(fontSize: 11),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final double? parsed = double.tryParse(value);
                      if (parsed != null) {
                        final gridUnits = _currentUnitToPixels(parsed);
                        widget.onElementHeightChanged(element, gridUnits);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Rotation in one row
        Row(
          children: [
            Icon(Icons.rotate_right, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              "Rotation",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _elementRotationController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  border: OutlineInputBorder(),
                  suffixText: "°",
                  suffixStyle: TextStyle(fontSize: 10),
                  labelText: "Angle",
                  labelStyle: TextStyle(fontSize: 10),
                ),
                style: const TextStyle(fontSize: 11),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
            // Add 4 rotation buttons for +90, 180, 270, 360
            SizedBox(
              height: 30,
              child: Row(
                children: List.generate(4, (index) {
                  final angle = (index + 1) * 90;
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () {
                        _elementRotationController.text =
                            angle.toStringAsFixed(1);
                        final radians = angle * math.pi / 180;
                        widget.onElementRotationChanged(element, radians);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3)),
                        ),
                        child: Text(
                          "$angle°",
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Quick-adjust section - a grid of common element presets
        Row(
          children: [
            Icon(Icons.settings, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            const Text(
              "Quick Adjust",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Presets for door/window sizes
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (element.type == ElementType.door) ...[
              _buildPresetButton("Standard", 32, 6.5, element),
              _buildPresetButton("Double", 64, 6.5, element),
              _buildPresetButton("Narrow", 24, 6.5, element),
              _buildPresetButton("Pocket", 30, 4, element),
            ] else if (element.type == ElementType.window) ...[
              _buildPresetButton("Standard", 36, 6, element),
              _buildPresetButton("Small", 24, 6, element),
              _buildPresetButton("Large", 48, 6, element),
              _buildPresetButton("Picture", 72, 6, element),
            ]
          ],
        ),

        const SizedBox(height: 8),

        // Tip text
        Row(
          children: [
            Icon(Icons.info_outline, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "Drag the element to reposition it.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper to build preset size buttons
  Widget _buildPresetButton(
      String label, double width, double height, ArchitecturalElement element) {
    return InkWell(
      onTap: () {
        final widthInCurrentUnit =
            width; // Assuming the presets are already in current unit
        final heightInCurrentUnit = height;

        // Update controllers
        _elementWidthController.text = widthInCurrentUnit.toStringAsFixed(2);
        _elementHeightController.text = heightInCurrentUnit.toStringAsFixed(2);

        // Convert to pixels and update element
        final widthInPixels = _currentUnitToPixels(widthInCurrentUnit);
        final heightInPixels = _currentUnitToPixels(heightInCurrentUnit);

        widget.onElementWidthChanged(element, widthInPixels);
        widget.onElementHeightChanged(element, heightInPixels);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            Text(
              "$width × $height",
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

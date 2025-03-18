// lib/widgets/editor_toolbar.dart
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/enums.dart';

class EditorToolbar extends StatelessWidget {
  final String projectName;
  final EditorMode mode;
  final List<Room> rooms;
  final Room? selectedRoom;
  final Function(EditorMode) onModeChanged;
  final Function(Room) onRoomSelected;
  final Function(Room) onRoomDeleted;
  final VoidCallback onAddRoom;
  final VoidCallback onRenameProject;
  final VoidCallback onOpenSettings;

  const EditorToolbar({
    super.key,
    required this.projectName,
    required this.mode,
    required this.rooms,
    required this.selectedRoom,
    required this.onModeChanged,
    required this.onRoomSelected,
    required this.onRoomDeleted,
    required this.onAddRoom,
    required this.onRenameProject,
    required this.onOpenSettings,
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
            onTap: onRenameProject,
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
          _buildToolButton(context, EditorMode.select, Icons.pan_tool),
          _buildToolButton(context, EditorMode.room, Icons.dashboard),
          _buildToolButton(context, EditorMode.door, Icons.door_back_door),
          _buildToolButton(context, EditorMode.window, Icons.window),
          _buildToolButton(context, EditorMode.delete, Icons.delete),
          
          const SizedBox(width: 16),
          
          // Room tabs
          ..._buildRoomTabs(),
          
          const SizedBox(width: 8),
          
          // Add Room button
          ElevatedButton.icon(
            onPressed: onAddRoom,
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
                  onOpenSettings();
                }
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolButton(BuildContext context, EditorMode toolMode, IconData icon) {
    final isSelected = mode == toolMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(4),
        elevation: isSelected ? 2 : 1,
        child: InkWell(
          onTap: () => onModeChanged(toolMode),
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
          onTap: () => onRoomSelected(room),
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
                  onTap: () => onRoomDeleted(room),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
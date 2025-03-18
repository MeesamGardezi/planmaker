// lib/widgets/surface_area_dialog.dart

import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../utils/measurement_utils.dart';

class SurfaceAreaInfoDialog extends StatefulWidget {
  final Map<String, dynamic> stats;
  final MeasurementUnit unit;

  const SurfaceAreaInfoDialog({
    super.key,
    required this.stats,
    this.unit = MeasurementUnit.feet,
  });

  @override
  State<SurfaceAreaInfoDialog> createState() => _SurfaceAreaInfoDialogState();
}

class _SurfaceAreaInfoDialogState extends State<SurfaceAreaInfoDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Surface Area Information"),
      content: SizedBox(
        width: 450, // Reduced from 600
        height: 400, // Reduced from 500
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab navigation
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Summary"),
                Tab(text: "Room Details"),
              ],
              labelColor: Theme.of(context).primaryColor,
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildRoomDetailsTab(),
                ],
              ),
            ),
            
            const SizedBox(height: 8), // Reduced from 16
            const Text(
              "Note: Accounts for doors, windows, and shared walls.",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10), // Reduced from 12
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
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor area section
            _buildSectionTitle("Floor Surfaces", Icons.grid_on),
            const SizedBox(height: 4), // Reduced from 8
            Row(
              children: [
                Expanded(
                  child: _buildAreaCard(
                    title: "Floor Area",
                    value: widget.stats['floorArea'] ?? 0,
                    color: Colors.amber.shade100,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildAreaCard(
                    title: "Ceiling Area",
                    value: widget.stats['ceilingArea'] ?? 0,
                    color: Colors.teal.shade100,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8), // Reduced from 16
            _buildSectionTitle("Wall Surfaces", Icons.house),
            const SizedBox(height: 4), // Reduced from 8
            Row(
              children: [
                Expanded(
                  child: _buildAreaCard(
                    title: "Internal Walls",
                    value: widget.stats['internalWallArea'] ?? 0,
                    color: Colors.blue.shade100,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildAreaCard(
                    title: "External Walls",
                    value: widget.stats['externalWallArea'] ?? 0,
                    color: Colors.green.shade100,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8), // Reduced from 16
            _buildSectionTitle("Openings", Icons.door_back_door_outlined),
            const SizedBox(height: 4), // Reduced from 8
            Row(
              children: [
                Expanded(
                  child: _buildAreaCard(
                    title: "Door Area",
                    value: widget.stats['doorArea'] ?? 0,
                    color: Colors.brown.shade100,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildAreaCard(
                    title: "Window Area",
                    value: widget.stats['windowArea'] ?? 0,
                    color: Colors.lightBlue.shade100,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12), // Reduced from 24
            _buildTotalCard(
              title: "TOTAL SURFACE AREA",
              value: widget.stats['totalSurfaceArea'] ?? 0,
              color: Colors.purple.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDetailsTab() {
    final roomStats = widget.stats['roomStats'] as List<Map<String, dynamic>>? ?? [];
    
    if (roomStats.isEmpty) {
      return const Center(
        child: Text(
          "No rooms to display",
          style: TextStyle(
            fontSize: 16, // Reduced from 18
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: roomStats.length,
      itemBuilder: (context, index) {
        final roomData = roomStats[index];
        return _buildRoomCard(roomData);
      },
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> roomData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // More compact
      elevation: 1, // Reduced from 2
      child: ExpansionTile(
        title: Text(
          roomData['name'] ?? 'Unnamed Room',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Reduced from default
        ),
        subtitle: Text(
          'Floor: ${MeasurementUtils.formatArea(roomData['floorArea'] ?? 0, widget.unit)}',
          style: const TextStyle(fontSize: 12), // Reduced from default
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomStatRow("Floor Area", roomData['floorArea'] ?? 0),
                _buildRoomStatRow("Ceiling Area", roomData['ceilingArea'] ?? 0),
                _buildRoomStatRow("Internal Wall Area", roomData['internalWallArea'] ?? 0),
                _buildRoomStatRow("External Wall Area", roomData['externalWallArea'] ?? 0),
                _buildRoomStatRow("Door Area", roomData['doorArea'] ?? 0),
                _buildRoomStatRow("Window Area", roomData['windowArea'] ?? 0),
                const Divider(height: 12), // More compact
                _buildRoomStatRow(
                  "Total Wall Area", 
                  (roomData['internalWallArea'] ?? 0) + (roomData['externalWallArea'] ?? 0),
                  isBold: true
                ),
                _buildRoomStatRow(
                  "Total Surface Area", 
                  (roomData['floorArea'] ?? 0) + 
                  (roomData['ceilingArea'] ?? 0) + 
                  (roomData['internalWallArea'] ?? 0) + 
                  (roomData['externalWallArea'] ?? 0),
                  isBold: true
                ),
                const SizedBox(height: 4), // Reduced from 8
                Text(
                  "Elements: ${roomData['elements']} (Doors and Windows)",
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 10, // Reduced from 12
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStatRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Reduced from 4
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12, // Added smaller font
            ),
          ),
          Text(
            MeasurementUtils.formatArea(value, widget.unit),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12, // Added smaller font
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]), // Reduced from 20
        const SizedBox(width: 4), // Reduced from 8
        Text(
          title,
          style: TextStyle(
            fontSize: 14, // Reduced from 16
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildAreaCard({
    required String title,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 12
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6), // Reduced from 8
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1, // Reduced from 2
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12, // Reduced from 16
            ),
          ),
          Text(
            MeasurementUtils.formatArea(value, widget.unit),
            style: const TextStyle(
              fontSize: 14, // Reduced from 20
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard({
    required String title,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced from 16
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6), // Reduced from 8
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2, // Reduced from 3
            offset: const Offset(0, 1), // Reduced from (0, 2)
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14, // Reduced from 16
            ),
          ),
          Text(
            MeasurementUtils.formatArea(value, widget.unit),
            style: const TextStyle(
              fontSize: 16, // Reduced from 20
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
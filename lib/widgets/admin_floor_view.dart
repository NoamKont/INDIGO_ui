// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:indigo_test/services/admin/admin_service.dart';
// import 'package:indigo_test/widgets/floor_picker.dart';
// import 'dart:convert';
//
// import '../constants.dart';
// import '../models/Building.dart';
// import '../models/Room.dart';
// import '../services/general.dart';
//
// class AdminFloorView extends StatefulWidget {
//   final Building building;
//   final int selectedFloor;
//
//   const AdminFloorView({
//     super.key,
//     required this.building,
//     this.selectedFloor = 1, // Default floor
//   });
//
//   @override
//   State<AdminFloorView> createState() => _AdminFloorViewState();
// }
//
// class _AdminFloorViewState extends State<AdminFloorView> {
//   late int selectedFloor = 1;
//   String? svgData;
//   List<Room>? doors;
//   List<int> floorsList = [];
//   bool canContinue = false;
//   Room? selectedRoom;
//   bool isLoading = true;
//
//   final TransformationController _transformationController = TransformationController();
//   final TextEditingController _roomNameController = TextEditingController();
//   final GeneralService generalService = GeneralService();
//
//
//   @override
//   void initState() {
//     super.initState();
//     selectedFloor = widget.selectedFloor;
//     _loadData(); // Load both SVG and doors
//   }
//
//   @override
//   void dispose() {
//     _roomNameController.dispose();
//     super.dispose();
//   }
//
//   // Combined loading method
//   Future<void> _loadData() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       await Future.wait([
//         loadSvg(),
//         loadDoors(),
//         loadFloorsList(),
//       ]);
//     } catch (e) {
//       print('Error loading data: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> loadFloorsList() async {
//     try {
//       floorsList = await generalService.getFloors(buildingId: widget.building.buildingId);
//     } catch (e) {
//       print('Error loading Floor List: $e');
//     }
//   }
//
//   Future<void> loadSvg() async {
//     try {
//       final url = Uri.parse(Constants.getFloorSvg);
//       svgData = await generalService.sendSvgRequest(url: url,
//           method: "GET",
//           queryParams: {
//             'buildingId': widget.building.buildingId.toString(),
//             'floorId': selectedFloor.toString(),
//           });
//
//       // Reset the transformation to show the full SVG initially
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _transformationController.value = Matrix4.identity();
//       });
//     } catch (e) {
//       print('Error loading SVG: $e');
//     }
//   }
//
//   Future<void> loadDoors() async {
//     try {
//       final url = Uri.parse(Constants.getDoorsName);
//       final fetchedDoors = await generalService.fetchRoomsFromFloor(url: url,
//           queryParams: {
//             'buildingId': widget.building.buildingId.toString(),
//             'floorId': selectedFloor.toString(),
//           });
//
//       setState(() {
//         doors = fetchedDoors;
//         _updateProgress();
//       });
//
//       // Reset the transformation to show the full SVG initially
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _transformationController.value = Matrix4.identity();
//       });
//     } catch (e) {
//       print('Error loading doors: $e');
//     }
//   }
//
//   void _onDoorTap(Room room) {
//     print('Room ${room.id} selected');
//     setState(() {
//       selectedRoom = room;
//       _roomNameController.text = room.name ?? '';
//     });
//     _showRoomNamingDialog(room);
//   }
//
//   void _showRoomNamingDialog(Room room) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Name Room ${room.id}'),
//           content: TextField(
//             controller: _roomNameController,
//             decoration: const InputDecoration(
//               hintText: 'Enter room name',
//               border: OutlineInputBorder(),
//             ),
//             autofocus: true,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 _saveRoomName(room);
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _saveRoomName(Room room) {
//     setState(() {
//       room.name = _roomNameController.text.trim();
//       _updateProgress();
//     });
//     _roomNameController.clear();
//   }
//
//   void _updateProgress() {
//     if (doors == null) return;
//     final namedRooms = doors!.where((room) => room.name != null && room.name!.isNotEmpty).length;
//     final totalRooms = doors!.length;
//     canContinue = namedRooms == totalRooms;
//   }
//
//   Widget _buildFloorPicker() {
//     // Add null check for doors
//     if (doors == null) {
//       return Container(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             FloorPickerButton(
//               floorsList: floorsList,
//               selectedFloor: selectedFloor,
//               onFloorSelected: (value) {
//                 setState(() => selectedFloor = value);
//                 _loadData(); // Reload data for new floor
//               },
//             ),
//             const Spacer(),
//             const Text('Loading...'),
//           ],
//         ),
//       );
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         children: [
//           FloorPickerButton(
//             floorsList: floorsList,
//             selectedFloor: selectedFloor,
//             onFloorSelected: (value) {
//               setState(() => selectedFloor = value);
//               _loadData(); // Reload data for new floor
//             },
//           ),
//           const Spacer(),
//           Text('Progress: ${doors!.where((r) => r.name != null && r.name!.isNotEmpty).length}/${doors!.length}'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDoorMarker(Room room) {
//     final isNamed = room.name != null && room.name!.isNotEmpty;
//     return Positioned(
//       left: room.x - 15,
//       top: room.y - 15,
//       child: GestureDetector(
//         onTap: () {
//           print('Door ${room.id} tapped at (${room.x}, ${room.y})');
//           _onDoorTap(room);
//         },
//         child: Container(
//           width: 30,
//           height: 30,
//           decoration: BoxDecoration(
//             color: isNamed ? Colors.green.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8),
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 2),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.5),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Center(
//             child: Text(
//               room.id.toString(),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSvgWithOverlay() {
//     // Add null checks for both svgData and doors
//     if (svgData == null || doors == null) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return InteractiveViewer(
//           transformationController: _transformationController,
//           boundaryMargin: const EdgeInsets.all(20),
//           minScale: 0.3,
//           maxScale: 5.0,
//           constrained: false,
//           child: Container(
//             width: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
//             height: constraints.maxHeight > 800 ? constraints.maxHeight : 800,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 // SVG Background
//                 Center(
//                   child: SizedBox(
//                     width: 800,
//                     height: 800,
//                     child: SvgPicture.string(
//                       svgData!,
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ),
//                 // Door Overlays
//                 ...doors!.map((room) => _buildDoorMarker(room)).toList(),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.building.name),
//         centerTitle: true,
//         actions: [
//           if (canContinue)
//             IconButton(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('All rooms have been named!')),
//                 );
//               },
//               icon: const Icon(Icons.check_circle, color: Colors.green),
//             ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading floor data...'),
//           ],
//         ),
//       )
//           : Column(
//         children: [
//           _buildFloorPicker(),
//           Expanded(
//             child: _buildSvgWithOverlay(),
//           ),
//         ],
//       ),
//       floatingActionButton: canContinue
//           ? FloatingActionButton.extended(
//         onPressed: () async {
//           try {
//             await AdminService.updateRoomNames(
//               buildingId: widget.building.buildingId,
//               floorId: selectedFloor,
//               rooms: doors!,
//             );
//             Navigator.of(context).pop();
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Room names updated successfully!')),
//             );
//           } catch (e) {
//             Navigator.of(context).pop();
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Failed to update room names: $e')),
//             );
//           }
//         },
//
//         icon: const Icon(Icons.arrow_forward),
//         label: const Text('Continue'),
//         backgroundColor: Colors.green,
//       )
//           : null,
//     );
//   }
// }
//
//
//
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:indigo_test/services/admin/admin_service.dart';
import 'package:indigo_test/widgets/floor_picker.dart';
import 'dart:convert';

import '../constants.dart';
import '../models/Building.dart';
import '../models/Room.dart';
import '../services/general.dart';

class AdminFloorView extends StatefulWidget {
  final Building building;
  final int selectedFloor;

  const AdminFloorView({
    super.key,
    required this.building,
    this.selectedFloor = 1, // Default floor
  });

  @override
  State<AdminFloorView> createState() => _AdminFloorViewState();
}

class _AdminFloorViewState extends State<AdminFloorView> {
  late int selectedFloor = 1;
  String? svgData;
  List<Room>? doors;
  List<int> floorsList = [];
  bool canContinue = false;
  Room? selectedRoom;
  bool isLoading = true;

  final TransformationController _transformationController = TransformationController();
  final TextEditingController _roomNameController = TextEditingController();
  final GeneralService generalService = GeneralService();

  @override
  void initState() {
    super.initState();
    selectedFloor = widget.selectedFloor;
    _loadData(); // Load both SVG and doors
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  // Combined loading method
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load floors list first to determine the default floor
      await loadFloorsList();

      // Then load SVG and doors with the correct selected floor
      await Future.wait([
        loadSvg(),
        loadDoors(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadFloorsList() async {
    try {
      floorsList = await generalService.getFloors(buildingId: widget.building.buildingId);

      // Set the default floor to the first one in the list if not already set via widget parameter
      if (floorsList.isNotEmpty && selectedFloor == widget.selectedFloor && widget.selectedFloor == 1) {
        selectedFloor = floorsList.first; // Get first floor in the list
      }
    } catch (e) {
      print('Error loading Floor List: $e');
    }
  }

  Future<void> loadSvg() async {
    try {
      final url = Uri.parse(Constants.getFloorSvg);
      svgData = await generalService.sendSvgRequest(url: url,
          method: "GET",
          queryParams: {
            'buildingId': widget.building.buildingId.toString(),
            'floorId': selectedFloor.toString(),
          });

      // Reset the transformation to show the full SVG initially
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transformationController.value = Matrix4.identity();
      });
    } catch (e) {
      print('Error loading SVG: $e');
    }
  }

  Future<void> loadDoors() async {
    try {
      final url = Uri.parse(Constants.getDoorsName);
      final fetchedDoors = await generalService.fetchRoomsFromFloor(url: url,
          queryParams: {
            'buildingId': widget.building.buildingId.toString(),
            'floorId': selectedFloor.toString(),
          });

      setState(() {
        doors = fetchedDoors;
        _updateProgress();
      });

      // Reset the transformation to show the full SVG initially
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transformationController.value = Matrix4.identity();
      });
    } catch (e) {
      print('Error loading doors: $e');
    }
  }

  void _onDoorTap(Room room) {
    print('Room ${room.id} selected');
    setState(() {
      selectedRoom = room;
      _roomNameController.text = room.name ?? '';
    });
    _showRoomNamingDialog(room);
  }

  void _showRoomNamingDialog(Room room) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Name Room ${room.id}'),
          content: TextField(
            controller: _roomNameController,
            decoration: const InputDecoration(
              hintText: 'Enter room name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveRoomName(room);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveRoomName(Room room) {
    setState(() {
      room.name = _roomNameController.text.trim();
      _updateProgress();
    });
    _roomNameController.clear();
  }

  void _updateProgress() {
    if (doors == null) return;
    final namedRooms = doors!.where((room) => room.name != null && room.name!.isNotEmpty).length;
    final totalRooms = doors!.length;
    canContinue = namedRooms == totalRooms;
  }

  Widget _buildFloorPicker() {
    // Add null check for doors
    if (doors == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            FloorPickerButton(
              floorsList: floorsList,
              selectedFloor: selectedFloor,
              onFloorSelected: (value) {
                setState(() => selectedFloor = value);
                _loadData(); // Reload data for new floor
              },
            ),
            const Spacer(),
            const Text('Loading...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          FloorPickerButton(
            floorsList: floorsList,
            selectedFloor: selectedFloor,
            onFloorSelected: (value) {
              setState(() => selectedFloor = value);
              _loadData(); // Reload data for new floor
            },
          ),
          const Spacer(),
          Text('Progress: ${doors!.where((r) => r.name != null && r.name!.isNotEmpty).length}/${doors!.length}'),
        ],
      ),
    );
  }

  // Method to transform coordinates based on SVG rendering
  Offset _transformCoordinates(double x, double y) {
    // The SVG Y-axis needs scaling while X-axis is correct
    double scaleX = 1;    // X coordinates are correct
    double scaleY = 1; // Y coordinates need 1.55x scaling
    double offsetX = 0;   // No horizontal offset needed
    double offsetY = 0;   // No vertical offset needed

    return Offset(
        (x * scaleX) + offsetX,
        (y * scaleY) + offsetY
    );
  }

  Widget _buildDoorMarker(Room room) {
    final isNamed = room.name != null && room.name!.isNotEmpty;

    // Debug print to check coordinates
    print('Room ${room.id}: x=${room.x}, y=${room.y}');

    // Transform coordinates
    final transformedPos = _transformCoordinates(room.x.toDouble(), room.y.toDouble());

    return Positioned(
      left: transformedPos.dx - 15,
      top: transformedPos.dy - 15,
      child: GestureDetector(
        onTap: () {
          print('Door ${room.id} tapped at (${room.x}, ${room.y})');
          _onDoorTap(room);
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isNamed ? Colors.green.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              room.id.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSvgWithOverlay() {
    // Add null checks for both svgData and doors
    if (svgData == null || doors == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.3,
          maxScale: 5.0,
          constrained: false,
          child: Container(
            width: 800, // Fixed size to match SVG
            height: 800, // Fixed size to match SVG
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // SVG Background - Remove Center widget and use exact sizing
                SvgPicture.string(
                  svgData!,
                  width: 800,
                  height: 800,
                  fit: BoxFit.fill, // Use fill instead of contain to ensure exact sizing
                ),
                // Door Overlays
                ...doors!.map((room) => _buildDoorMarker(room)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building.name),
        centerTitle: true,
        actions: [
          if (canContinue)
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All rooms have been named!')),
                );
              },
              icon: const Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading floor data...'),
          ],
        ),
      )
          : Column(
        children: [
          _buildFloorPicker(),
          Expanded(
            child: _buildSvgWithOverlay(),
          ),
        ],
      ),
      floatingActionButton: canContinue
          ? FloatingActionButton.extended(
        onPressed: () async {
          try {
            await AdminService.updateRoomNames(
              buildingId: widget.building.buildingId,
              floorId: selectedFloor,
              rooms: doors!,
            );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room names updated successfully!')),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update room names: $e')),
            );
          }
        },
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Continue'),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }
}
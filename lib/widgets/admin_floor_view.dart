import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:indigo_test/widgets/floor_picker.dart';
import 'dart:convert';

import '../constants.dart';
import '../models/Building.dart';
import '../models/Room.dart';
import '../services/general.dart';

class AdminFloorView extends StatefulWidget {
  final Building building;

  const AdminFloorView({
    super.key,
    required this.building,
  });

  @override
  State<AdminFloorView> createState() => _AdminFloorViewState();
}

class _AdminFloorViewState extends State<AdminFloorView> {
  int selectedFloor = 1;
  String? svgData;
  //List<Room>? doors;
  final TransformationController _transformationController = TransformationController();
  bool canContinue = false;
  Room? selectedRoom;
  final TextEditingController _roomNameController = TextEditingController();

  List<Room> doors = [
    Room(id: 0, x: 218.77152536985713, y: 629.7557636416216),
    Room(id: 1, x: 243.20282977091225, y: 634.7775616928012),
    // Room(id: 2, x: 759.2291812259299, y: 200.13712073969901),
    // Room(id: 3, x: 765.0347440952701, y: 179.34495018862827),
    // Room(id: 4, x: 121.93992977755403, y: 538.1077647905388),
    // Room(id: 5, x: 532.2258094133374, y: 498.6612322459096),
    // Room(id: 6, x: 518.0688331159433, y: 458.5725874235343),
    // Room(id: 7, x: 615.0867761566642, y: 196.08394152737506),
    // Room(id: 8, x: 609.3550069833784, y: 284.5976174539574),
    // Room(id: 9, x: 650.2856419415792, y: 356.9482107134494),
    // Room(id: 10, x: 573.9055292449841, y: 411.5571568391223),
    // Room(id: 11, x: 627.1829200381752, y: 470.96601708517795),
    // Room(id: 12, x: 530.0202132325805, y: 568.7289930264437),
    // Room(id: 13, x: 523.2255685661689, y: 531.2582176944235),
    // Room(id: 14, x: 651.9534113051042, y: 548.5647847063306),
    // Room(id: 15, x: 639.9240093598405, y: 592.3963042085704),
    // Room(id: 16, x: 603.0447129297953, y: 645.2535150768815),
    // Room(id: 17, x: 553.4878159263365, y: 734.8992841155392),
    // Room(id: 18, x: 526.7462079508641, y: 742.4592978064987),
    // Room(id: 19, x: 599.9460487235493, y: 165.46750268823996),
    // Room(id: 20, x: 594.752498795767, y: 125.63372778414816),
    // Room(id: 21, x: 203.78390638135647, y: 314.44545928019096),
    // Room(id: 22, x: 248.66165953712556, y: 359.8230613143893),
    // Room(id: 23, x: 229.12775644448712, y: 429.03305682648084),
    // Room(id: 24, x: 118.48185749757005, y: 491.49664595637967),
    // Room(id: 25, x: 93.45869674319609, y: 581.1151443449133),
    // Room(id: 26, x: 186.03073733546717, y: 542.3078122775635),
    // Room(id: 27, x: 180.83668674654277, y: 563.7192295891953),
    // Room(id: 28, x: 137.4158759683949, y: 408.702841123061),
    // Room(id: 29, x: 128.14348523878175, y: 443.4094947124109),
    // Room(id: 30, x: 98.15053938691463, y: 564.3116758968195),
    // Room(id: 31, x: 773.3039625182096, y: 77.533389862971),
    // Room(id: 32, x: 600.8292338930617, y: 599.4362285831215),
    // Room(id: 33, x: 519.5997829030085, y: 606.7667034072514),
    // Room(id: 34, x: 393.36655999427603, y: 154.1009230516602),
    // Room(id: 35, x: 285.20110312934366, y: 85.50710693978107),
    // Room(id: 36, x: 594.3152218065092, y: 191.8143966235303),
    // Room(id: 37, x: 588.5497653660091, y: 359.10996743946225),
    // Room(id: 38, x: 613.7449644109768, y: 418.8935618827696),
    // Room(id: 39, x: 584.0078341171703, y: 466.39883955299035),
    // Room(id: 40, x: 634.4656341862327, y: 611.19589437508),
    // Room(id: 41, x: 514.2832753359211, y: 739.8975708639317),
    // Room(id: 42, x: 604.9222454652338, y: 147.64564221440742),
    // Room(id: 43, x: 418.2691490945765, y: 159.30773853281997),
    // Room(id: 44, x: 304.7303876253711, y: 108.01712814382842),
    // Room(id: 45, x: 257.40710854925993, y: 98.82835787755954),
    // Room(id: 46, x: 234.0598375215415, y: 131.3149776302841),
    // Room(id: 47, x: 200.31624934805086, y: 183.77978771904625),
    // Room(id: 48, x: 190.75265642857948, y: 218.32809615758376),
    // Room(id: 49, x: 180.9220531875522, y: 252.88886097179136),
    // Room(id: 50, x: 171.4518381300441, y: 287.55485222677936),
    // Room(id: 51, x: 152.06836700856675, y: 356.97524207578886),
    // Room(id: 52, x: 161.78379874464116, y: 322.1801811500062),
    // Room(id: 53, x: 245.1072332973956, y: 372.5529616556276),
    // Room(id: 54, x: 225.77115453265205, y: 441.80361949818),
    // Room(id: 55, x: 118.2776215315463, y: 477.99416130257606),
    // Room(id: 56, x: 298.17265999570577, y: 580.434089782238),
    // Room(id: 57, x: 392.7326883657322, y: 599.8706846748762),
    // Room(id: 58, x: 565.4444179925204, y: 289.03240198067397),
    // Room(id: 59, x: 264.6337547664107, y: 115.39273771328897),
    // Room(id: 60, x: 259.7777284478547, y: 135.61244120391666),
    // Room(id: 61, x: 503.7174590282663, y: 662.9302555373032),
    // Room(id: 62, x: 427.2405713834645, y: 722.0061446029257),
    // Room(id: 63, x: 417.8605925913901, y: 701.0988004418105),
    // Room(id: 64, x: 444.93870219298435, y: 669.1098358286856),
    // Room(id: 65, x: 531.9294802421683, y: 672.901927541483),
    // Room(id: 66, x: 420.84631062912587, y: 690.4056841637529),
    // Room(id: 67, x: 736.2900485925996, y: 108.97267329594698),
    // Room(id: 68, x: 308.1658911481748, y: 293.8034841356221),
  ];

  @override
  void initState() {
    super.initState();
    loadSvg();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> loadSvg() async {
    try {
      final url = Uri.parse(Constants.getBuildingSvg);
      svgData = await GeneralService.sendSvgRequest(url: url,
          method: "GET",
          queryParams: {
            //'buildingId': widget.buildingId.toString(),
            'buildingId': "15",
            'floor': selectedFloor.toString(),
          });
      setState(() {});

    // final Uint8List? bytes = await AdminService.loadAdminSvgWithCache(widget.buildingId); // <- adjust class name
    // if (bytes == null) return;
    //
    // final String svgString = utf8.decode(bytes);
    // setState(() {
    //   svgData = svgString;
    // });

      // Reset the transformation to show the full SVG initially
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transformationController.value = Matrix4.identity();
      });
    } catch (e) {
      print('Error loading SVG: $e');
    }
  }

  // Future<void> loadDoors() async {
  //   try {
  //     final url = Uri.parse(Constants.getBuildingSvg);
  //     doors = await GeneralService.getDoors(url: url,
  //         method: "GET",
  //         queryParams: {
  //           //'buildingId': widget.buildingId.toString(),
  //           'buildingId': "15",
  //           'floor': selectedFloor.toString(),
  //         });
  //     setState(() {});
  //
  //     // Reset the transformation to show the full SVG initially
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       _transformationController.value = Matrix4.identity();
  //     });
  //   } catch (e) {
  //     print('Error loading SVG: $e');
  //   }
  // }


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
      //room.isNamed = room.name!.isNotEmpty;
      _updateProgress();
    });
    _roomNameController.clear();
  }

  void _updateProgress() {
    final namedRooms = doors.where((room) => room.name != null && room.name!.isNotEmpty).length;
    final totalRooms = doors.length;
    canContinue = namedRooms == totalRooms;
  }

  Widget _buildFloorPicker() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          FloorPickerButton(numberOfFloors: 10,
            selectedFloor: selectedFloor,
            onFloorSelected: (value) {
              setState(() => selectedFloor = value);
              loadSvg();
            },
          ),
          const Spacer(),
          Text('Progress: ${doors.where((r) => r.name != null && r.name!.isNotEmpty).length}/${doors.length}'),
          //Text('Progress: ${doors.where((r) => r.isNamed).length}/${doors.length}'),
        ],
      ),
    );
  }

  Widget _buildDoorMarker(Room room) {
    final isNamed = room.name != null && room.name!.isNotEmpty;
    return Positioned(
      left: room.x - 15, // Increased hit area
      top: room.y - 15,
      child: GestureDetector(
        onTap: () {
          print('Door ${room.id} tapped at (${room.x}, ${room.y})');
          _onDoorTap(room);
        },
        child: Container(
          width: 30, // Increased size for better tapping
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.3,
          maxScale: 5.0,
          constrained: false,
          child: Container(
            width: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
            height: constraints.maxHeight > 800 ? constraints.maxHeight : 800,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // SVG Background - Center it in the container
                Center(
                  child: SizedBox(
                    width: 800,
                    height: 800,
                    child: SvgPicture.string(
                      svgData!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Door Overlays - Position them relative to the centered SVG
                ...doors.map((room) => _buildDoorMarker(room)).toList(),
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
      body: Column(
        children: [
          _buildFloorPicker(),
          Expanded(
            child: _buildSvgWithOverlay(),
          ),
        ],
      ),
      floatingActionButton: canContinue
          ? FloatingActionButton.extended(
        onPressed: () {

          // Handle continue action
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success!'),
              content: const Text('All rooms have been successfully named.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Continue'),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }
}
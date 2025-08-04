import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:indigo_test/constants.dart';
import 'package:indigo_test/services/admin/admin_service.dart';
import 'package:indigo_test/services/general.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'dart:convert';

import '../../models/Building.dart';
import '../../models/Room.dart';
import '../../services/user/home_screen_service.dart';
import '../../widgets/bottom_search_bar.dart';
import '../../widgets/navigation_bottom_sheet.dart';
import '../../widgets/user_svg_view.dart';
import '../../widgets/floor_picker.dart';


class UserFloorView extends StatefulWidget {
  final Building building;



  UserFloorView({
    super.key,
    required this.building,
  });

  @override
  State<UserFloorView> createState() => _UserFloorViewState();
}

class _UserFloorViewState extends State<UserFloorView> {
  int selectedFloor = 1;
  String? svgData;
  List<int> floorsList = [];
  final GeneralService generalService = GeneralService();
  List<String> places = [];

  @override
  void initState() {
    super.initState();
    loadSvg();
    loadRoomsName();
    loadFloorsList();
  }

  Future<void> loadFloorsList() async {
    try {
      final list = await generalService.getFloors(
        buildingId: widget.building.buildingId,
      );

      if (!mounted) return;
      setState(() {
        floorsList = list;
        // pick first floor as default, if there is one
        if (list.isNotEmpty) {
          selectedFloor = list.first;
        }
      });

      // now that we have a floor, load its SVG & rooms
      if (floorsList.isNotEmpty) {
        await loadSvg();
        await loadRoomsName();
      }
    } catch (e) {
      debugPrint('Error loading floor list: $e');
    }
  }

  Future<void> loadSvg() async {
      final url = Uri.parse(Constants.getFloorSvg);
      svgData = await generalService.sendSvgRequest(url: url,
          method: "GET",
          queryParams: {
            'buildingId': widget.building.buildingId.toString(),
            'floorId': selectedFloor.toString(),
          });
      setState(() {});

  }
  Future<void> loadRoomsName() async {
    try {
      final url = Uri.parse(Constants.getDoorsName);
      places = await generalService.fetchRoomsNameFromFloor(url: url,
          queryParams: {
            'buildingId': widget.building.buildingId.toString(),
            'floorId': selectedFloor.toString(),
          });
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }

  void onNavigationDataReceived(Map<String, dynamic> navigationData) async{
    String? destination = navigationData['destination'];
    String? currentLocation = navigationData['currentLocation'];
    print('=== Go Now Pressed ===');
    print('Destination: $destination');
    print('Current Location: $currentLocation');
    print('====================');

    // Apply the navigation data to update svgData
    if (destination != null && destination.isNotEmpty) {
      if (currentLocation != null && currentLocation.isNotEmpty) {

        final url = Uri.parse(Constants.getRoute);
        svgData = await generalService.sendSvgRequest(url: url,
            method: "GET",
            queryParams: {
              'buildingId': widget.building.buildingId.toString(),
              'floorId': selectedFloor.toString(),
              'start': destination,
              'goal': currentLocation,

            });
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building.name),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    FloorPickerButton(
                      floorsList: floorsList,
                      selectedFloor: selectedFloor,
                      onFloorSelected: (value) {
                        setState(() => selectedFloor = value);
                        loadSvg();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: svgData == null
                    ? const Center(child: CircularProgressIndicator())
                    : ZoomableSvgView(rawSvg: svgData!),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NavigationBottomSheet(
              onNavigationPressed: onNavigationDataReceived,
              places: places,
            ),
          ),
        ],
      ),
    );
  }

}



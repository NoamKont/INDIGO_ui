import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:indigo_test/services/admin/admin_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'dart:convert';

import '../../models/Room.dart';
import '../../services/user/home_screen_service.dart';
import '../../widgets/bottom_search_bar.dart';
import '../../widgets/navigation_bottom_sheet.dart';
import '../../widgets/user_svg_view.dart';
import '../../widgets/floor_picker.dart';


class UserFloorView extends StatefulWidget {
  final String buildingName;
  final int buildingId;

  final List<String> places = [
    'Museum',
    'Gas Station',
    'Supermarket',
    'Park',
    'Stadium',
    'Library',
    'Hospital',
    'Cafe',
  ];

  UserFloorView({
    super.key,
    required this.buildingName,
    required this.buildingId,
  });

  @override
  State<UserFloorView> createState() => _UserFloorViewState();
}

class _UserFloorViewState extends State<UserFloorView> {
  int selectedFloor = 1;

  String? svgData;

  @override
  void initState() {
    super.initState();
    loadSvg();
  }

  Future<void> loadSvg() async {
    svgData = await rootBundle.loadString('assets/userExample.svg');//TODO delete this line when you have the actual SVG file
    print('Floor confirmed: $selectedFloor');
    setState(() {});

    // final Uint8List? bytes = await HomeService.loadUserSvgWithCache(widget.buildingId, selectedFloor); // <- adjust class name
    // if (bytes == null) return;
    //
    // final String svgString = utf8.decode(bytes);
    // setState(() {
    //   svgData = svgString;
    // });
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
        svgData = await rootBundle.loadString('assets/userExample.svg');//TODO delete this line when you have the actual SVG file
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingName),
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
                      numberOfFloors: 10,
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
              places: widget.places,
            ),
          ),
        ],
      ),
    );
  }

}



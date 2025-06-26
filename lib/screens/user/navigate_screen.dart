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

  @override
  void initState() {
    super.initState();
    loadSvg();
  }

  Future<void> loadSvg() async {
      final url = Uri.parse(Constants.getBuildingSvg);
      svgData = await GeneralService.sendSvgRequest(url: url,
          method: "GET",
          queryParams: {
            'buildingId': widget.building.buildingId.toString(),
            'floor': selectedFloor.toString(),
          });
      setState(() {});

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
        svgData = await GeneralService.sendSvgRequest(url: url,
            method: "GET",
            queryParams: {
              //'buildingId': widget.buildingId.toString(),
              'buildingId': "15",
              'floor': selectedFloor.toString(),
              'start': destination,
              'goal': currentLocation,

            });
        //svgData = await rootBundle.loadString('assets/userExample.svg');//TODO delete this line when you have the actual SVG file
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
              places: places,
            ),
          ),
        ],
      ),
    );
  }

}



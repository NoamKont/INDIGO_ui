import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'dart:convert';

import '../../services/user/home_screen_service.dart';
import '../../widgets/bottom_search_bar.dart';
import '../../widgets/navigation_bottom_sheet.dart';
import '../../widgets/zommable_svg_view.dart';
import '../../widgets/floor_picker.dart';


class SvgZoomView extends StatefulWidget {
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

  SvgZoomView({
    super.key,
    required this.buildingName,
    required this.buildingId,
  });

  @override
  State<SvgZoomView> createState() => _SvgZoomViewState();
}

class _SvgZoomViewState extends State<SvgZoomView> {
  int selectedFloor = 1;

  String? svgData;

  @override
  void initState() {
    super.initState();
    loadSvg();
  }

  Future<void> loadSvg() async {
    svgData = await rootBundle.loadString('assets/watson.svg');//TODO delete this line when you have the actual SVG file
    print('Floor confirmed: $selectedFloor');
    setState(() {});

    // final Uint8List? bytes = await HomeService.fetchUserFloorSvgWithCache(widget.buildingId, selectedFloor); // <- adjust class name
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
      appBar: AppBar(title: Text(widget.buildingName)),
      body: Stack(
        children: [
          Column(
            children: [
              FloorPickerButton(
                numberOfFloors: 10,// TODO change to real number of floors ,Assuming 10 floors
                selectedFloor: selectedFloor,
                onFloorSelected: (value) {
                  setState(() => selectedFloor = value);
                  loadSvg();
                },
              ),
              Expanded(
                child: svgData == null
                    ? const Center(child: CircularProgressIndicator())
                    : ZoomableSvgView(rawSvg: svgData!),
              ),
            ],
          ),
          NavigationBottomSheet(onNavigationPressed: onNavigationDataReceived ,places: widget.places,),
        ],
      ),
    );
  }

}



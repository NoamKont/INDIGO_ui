import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:indigo_test/constants.dart';
import 'package:indigo_test/models/Building.dart';
import 'package:indigo_test/services/general.dart';
import 'package:indigo_test/services/admin/positioning_service.dart';
import 'package:indigo_test/services/dataCollection/data_collection.dart';
import 'package:indigo_test/services/dataCollection/wifi_positioning_service.dart';
import 'package:indigo_test/widgets/floor_picker.dart';
import 'package:indigo_test/widgets/navigation_bottom_sheet.dart';
import 'package:xml/xml.dart';

import '../../models/user_location.dart';
import '../../widgets/dialogs/error_dialog.dart';
import '../../widgets/dialogs/north_alignment_dialog.dart';
import '../../widgets/map/animated_location_dot.dart';
import '../../widgets/map/svg_map_with_location.dart';
import '../../utils/svg_parser.dart';



class UserFloorView extends StatefulWidget {
  final Building building;
  const UserFloorView({Key? key, required this.building}) : super(key: key);

  @override
  State<UserFloorView> createState() => _UserFloorViewState();
}

class _UserFloorViewState extends State<UserFloorView> {
  int selectedFloor = 1;
  String? svgData;
  List<int> floorsList = [];
  List<String> places = [];

  double svgWidth = 800;
  double svgHeight = 800;

  final GeneralService generalService = GeneralService();
  final WifiPositioningService wifiService = WifiPositioningService.instance;
  final PositioningService positioningService = PositioningService();

  UserLocation? userLocation;
  Timer? locationTimer;
  bool isLocationLoading = false;
  bool isRouteLoading = false;

  bool isTrackingEnabled = false;

  // PDR State - now integrated with location tracking
  bool isPdrRunning = false;
  double pdrNorthOffset = 0.0; // degrees to align SVG north with magnetic north
  double? headingDeg;
  int pdrSteps = 0;
  double stepLengthMeters = 0.70;
  final int minStepIntervalMs = 250;
  int _lastStepMs = 0;

  // PDR sensor subscriptions
  StreamSubscription? _accSub;
  StreamSubscription? _compassSub;
  double _emaMag = 0.0;
  final double _smoothAlpha = 0.2;
  final double _stepThreshold = 1.2;
  double _prevEmaMag = 0.0;

  // PDR coordinate conversion (meters to SVG pixels)
  double metersToPixelScale = 8.5; // 8.5 pixels per meter (adjustable)

  bool isNavigating = false;       // true when a route SVG is shown
  bool isLiveLocationOn = false;


  void initState(){
    super.initState();
    _loadFloorsAndData();
    if (isTrackingEnabled) _startLocationTracking();
  }

  Future<void> _initAsync() async {
    try {
      await wifiService.init(); // <-- use this if your init() has no parameters
    } catch (e) {
      debugPrint('Init error: $e');
      if (!mounted) return;
      // If you want to notify the user, schedule after frame:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          //SnackBar(content: Text('Initialization failed: $e')),
          SnackBar(content: Text('Initialization failed: can\'t use location tracking on your current network')),
        );
      });
    }
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    _stopPdr();
    super.dispose();
  }

  void _startLocationTracking() {
    _initAsync();
    fetchUserStartPosition();
    locationTimer?.cancel();

    locationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || !isTrackingEnabled) return;
      if (isNavigating && isPdrRunning) {
        await getEstimatedLocation();
      } else if (!isPdrRunning) {
        await fetchUserStartPosition();
      }
    });

  }

  void _startPdr() {
    if (isPdrRunning || !isTrackingEnabled) return;

    // Ensure we have a location before starting PDR
    if (userLocation == null) {
      fetchUserStartPosition().then((_) {
        if (userLocation != null) {
          _startPdrSensors();
        }
      });
    } else {
      _startPdrSensors();
    }
  }

  void _startPdrSensors() {
    isPdrRunning = true;

    // Start compass
    _compassSub = FlutterCompass.events?.listen((event) {
      setState(() {
        headingDeg = event.heading;
      });
    });

    // Start accelerometer
    _accSub = userAccelerometerEventStream().listen((e) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

      _emaMag = (1 - _smoothAlpha) * _emaMag + _smoothAlpha * mag;

      final bool rising = _prevEmaMag <= _stepThreshold && _emaMag > _stepThreshold;
      final bool spaced = (nowMs - _lastStepMs) > minStepIntervalMs;

      if (rising && spaced) {
        _lastStepMs = nowMs;
        pdrSteps += 1;

        if (userLocation != null) {
          // Convert current SVG coordinates back to meters for calculation
          final currentMeterX = (userLocation!.x - svgWidth / 2) / metersToPixelScale;
          final currentMeterY = (svgHeight / 2 - userLocation!.y) / metersToPixelScale;

          // Calculate movement with north offset compensation
          final double adjustedHeading = ((headingDeg ?? 0.0) + pdrNorthOffset) * pi / 180.0;
          final newMeterX = currentMeterX + stepLengthMeters * sin(adjustedHeading);
          final newMeterY = currentMeterY + stepLengthMeters * cos(adjustedHeading);

          // Convert back to SVG coordinates
          final svgX = (svgWidth / 2) + (newMeterX * metersToPixelScale);
          final svgY = (svgHeight / 2) - (newMeterY * metersToPixelScale); // SVG Y is inverted

          setState(() {
            userLocation = UserLocation(x: svgX, y: svgY);
          });
        }
      }

      _prevEmaMag = _emaMag;
    });

    setState(() {});
  }

  void _stopPdr() {
    isPdrRunning = false;
    _accSub?.cancel();
    _accSub = null;
    _compassSub?.cancel();
    _compassSub = null;
    setState(() {});
  }

  void _resetPdr() {
    pdrSteps = 0;
    _lastStepMs = 0;
    _emaMag = 0;
    _prevEmaMag = 0;

    // Fetch fresh location instead of using hardcoded values
    if (isTrackingEnabled) {
      fetchUserStartPosition();
    }
  }

  // Helper method to get current position in meters for display
  String _getCurrentPositionInMeters() {
    if (userLocation == null) return "0.0m, 0.0m";

    final meterX = (userLocation!.x - svgWidth / 2) / metersToPixelScale;
    final meterY = (svgHeight / 2 - userLocation!.y) / metersToPixelScale;

    return "${meterX.toStringAsFixed(1)}m, ${meterY.toStringAsFixed(1)}m";
  }

  Future<void> _showNorthAlignmentDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return NorthAlignmentDialog(
          initialOffset: pdrNorthOffset,
          onOffsetChanged: (newOffset) {
            setState(() {
              pdrNorthOffset = newOffset;
            });
          },
        );
      },
    );
  }

  void _toggleNavigationMode() {
    setState(() => isLiveLocationOn = !isLiveLocationOn);

    if (isLiveLocationOn) {
      // turn ON: enable tracking + start PDR
      if (!isTrackingEnabled) {
        setState(() => isTrackingEnabled = true);
      }
      _startLocationTracking();   // server correction loop
      _resetPdr();                // zero counters
      _startPdr();                // start sensors
      _showNorthAlignmentDialog();
    } else {
      // turn OFF: stop everything
      locationTimer?.cancel();
      _stopPdr();
      setState(() {
        isTrackingEnabled = false;
        isPdrRunning = false;
        userLocation = null; // or keep last point
      });
    }
  }

  Future<void> fetchUserStartPosition() async {
    if (isLocationLoading) return;

    setState(() => isLocationLoading = true);

    try {
      final featureVector = await wifiService.scanFeatureVector();
      //TODO delete the print
      // print(featureVector);
      final coords = await positioningService.getCurrentLocation(
        Constants.getUserLocation,
        widget.building.buildingId,
        selectedFloor,
        featureVector,
      );


      if (coords != null && mounted) {
        setState(() => userLocation = coords);
      }
    } catch (e) {
      debugPrint('Error fetching user location: $e');
    } finally {
      if (mounted) setState(() => isLocationLoading = false);
    }
  }

  Future<void> getEstimatedLocation() async {
    if (isLocationLoading || userLocation == null) return;

    try {
      final featureVector = await wifiService.scanFeatureVector();

      final coords = await positioningService.getEstimatedLocation(
        Constants.getEstimatedLocation,
        widget.building.buildingId,
        selectedFloor,
        featureVector,
        userLocation!,
      );

      if (coords != null && mounted) {
        setState(() => userLocation = coords);
      }
    } catch (e) {
      debugPrint('Error fetching estimated location: $e');
    } finally {
      if (mounted) setState(() => isLocationLoading = false);
    }
  }

  Future<void> _loadFloorsAndData() async {
    try {
      final list = await generalService.getFloors(
        buildingId: widget.building.buildingId,
      );
      if (!mounted) return;

      setState(() {
        floorsList = list;
        if (list.isNotEmpty) selectedFloor = list.first;
      });

      await _loadSvg();
      await _loadRoomNames();
      await _loadOneCmSvg();
    } catch (e) {
      debugPrint('Error loading floors: $e');
    }
  }

  Future<void> _loadSvg() async {
    final url = Uri.parse(Constants.getFloorSvg);
    svgData = await generalService.sendSvgRequest(
      url: url,
      method: "GET",
      queryParams: {
        'buildingId': widget.building.buildingId.toString(),
        'floorId': selectedFloor.toString(),
      },
    );

    if (svgData != null) {
      //_parseSvgDimensions(svgData!);
      final dims = SvgParser.parseDimensions(svgData!);
      svgWidth = dims.width;
      svgHeight = dims.height;
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadRoomNames() async {
    try {
      final url = Uri.parse(Constants.getDoorsName);
      places = await generalService.fetchRoomsNameFromFloor(
        url: url,
        queryParams: {
          'buildingId': widget.building.buildingId.toString(),
          'floorId': selectedFloor.toString(),
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading room names: $e');
    }
  }

  Future<void> _loadOneCmSvg() async {
    try {
      metersToPixelScale = await positioningService.fetchOneCmSvg(widget.building.buildingId, selectedFloor);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading cm per pixel: $e');
    }finally{
      print(metersToPixelScale);
    }
  }

  void getNavigationRoute(Map<String, dynamic> nav) async {
    final dest = nav['destination'] as String?;
    final curr = nav['currentLocation'] as String?;
    if (dest == null || curr == null || dest.isEmpty || curr.isEmpty) return;

    if (!mounted) return;
    setState(() {
      isNavigating = true;
      isRouteLoading = true;
      svgData = null;
    });

    String? newSvg;
    String? errorText;

    try {
      final url = Uri.parse(Constants.getRoute);
      newSvg = await generalService.sendSvgRequest(
        url: url,
        method: "GET",
        queryParams: {
          'buildingId': widget.building.buildingId.toString(),
          'floorId': selectedFloor.toString(),
          'start': dest,
          'goal': curr,
        },
      );
    } on TimeoutException {
      errorText = 'The routing request timed out. Please try again.';
    } catch (e) {
      errorText = 'Failed to fetch route: $e';
    }

    if (!mounted) return;

    if (errorText != null) {
      await ErrorDialog.show(context, errorText);
      await _loadSvg();
    } else {
      final dims = SvgParser.parseDimensions(newSvg!);
      svgWidth = dims.width;
      svgHeight = dims.height;
      setState(() {
        svgData = newSvg;
      });
    }

    if (mounted) {
      setState(() => isRouteLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building.name),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Single master toggle: Navigation (starts/stops tracking + PDR)
                IconButton(
                  icon: Icon(
                    isLiveLocationOn ? Icons.navigation : Icons.navigation_outlined,
                    color: isLiveLocationOn ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  tooltip: 'Navigation',
                  onPressed: _toggleNavigationMode,
                ),

                // Align North visible ONLY when nav mode is ON
                if (isLiveLocationOn)
                  IconButton(
                    icon: const Icon(Icons.compass_calibration, size: 20),
                    tooltip: 'Align North',
                    onPressed: _showNorthAlignmentDialog,
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    FloorPickerButton(
                      floorsList: floorsList,
                      selectedFloor: selectedFloor,
                      onFloorSelected: (floor) {
                        setState(() {
                          selectedFloor = floor;
                          userLocation = null;
                          isNavigating = false; // route cleared on floor change
                        });
                        _loadSvg();
                        _loadRoomNames();
                        _loadOneCmSvg();

                        if (isPdrRunning) {
                          _resetPdr();
                        } else if (isTrackingEnabled) {
                          fetchUserStartPosition();
                        }
                      },
                    ),

                    // PDR info (kept as-is; shows when PDR is running)
                    if (isPdrRunning) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'PDR: $pdrSteps steps | ${_getCurrentPositionInMeters()}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Reset PDR',
                        onPressed: _resetPdr,
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.15,
                  ),
                  child: svgData == null
                      ? const Center(child: CircularProgressIndicator())
                      : SvgMapWithLocation(
                    svgData: svgData!,
                    userLocation: userLocation,
                    svgWidth: svgWidth,
                    svgHeight: svgHeight,
                  ),
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: NavigationBottomSheet(
              onNavigationPressed: getNavigationRoute,
              places: places,
            ),
          ),
        ],
      ),
    );
  }

}
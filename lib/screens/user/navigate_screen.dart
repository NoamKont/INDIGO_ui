import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:indigo_test/constants.dart';
import 'package:indigo_test/models/Building.dart';
import 'package:indigo_test/services/general.dart';
import 'package:indigo_test/services/admin/positioning_service.dart'; // provides both PositioningService & MagneticPositioningService
import 'package:indigo_test/services/dataCollection/data_collection.dart';
import 'package:indigo_test/widgets/floor_picker.dart';
import 'package:indigo_test/widgets/navigation_bottom_sheet.dart';
import 'package:xml/xml.dart';

class UserFloorView extends StatefulWidget {
  final Building building;
  const UserFloorView({ Key? key, required this.building }) : super(key: key);

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
  final MagneticPositioningService magneticService = MagneticPositioningService();
  final PositioningService positioningService = PositioningService();

  UserLocation? userLocation;
  Timer? locationTimer;
  bool isLocationLoading = false;
  bool isTrackingEnabled = false;


  @override
  void initState() {
    super.initState();
    magneticService.initialize();           // start sensor streams
    _loadFloorsAndData();
    if (isTrackingEnabled) _startLocationTracking();
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    magneticService.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    fetchUserLocation(); // initial
    locationTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (mounted) fetchUserLocation();
      },
    );
  }


  Future<void> fetchUserLocation() async {
    if (isLocationLoading) return;

    setState(() => isLocationLoading = true);

    try {
      // 1) collect ~30 samples under the name "live"
      final success = await magneticService.scanAndCapture("live");
      if (!success) {
        debugPrint('Failed to capture magnetic fingerprint');
        return;
      }

      // 2) grab the map of all collected points
      final data = magneticService.collectedData;

      // 3) send them to your server
      final coords = await positioningService.sendData(
        Constants.getUserLocation,
        widget.building.buildingId,
        selectedFloor,
        data,
      );

      // 4) clear so next tick starts fresh
      magneticService.clearCollectedData();

      if (coords != null && mounted) {
        setState(() => userLocation = coords);
      }
    } catch (e) {
      debugPrint('Error fetching user location: $e');
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

    // Parse SVG dimensions
    if (svgData != null) {
      _parseSvgDimensions(svgData!);
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
  void _parseSvgDimensions(String svgString) {
    try {
      final document = XmlDocument.parse(svgString);
      final svgElement = document.findAllElements('svg').first;

      // Try to get width and height attributes
      final widthAttr = svgElement.getAttribute('width');
      final heightAttr = svgElement.getAttribute('height');

      if (widthAttr != null && heightAttr != null) {
        // Remove 'px' or other units if present
        final widthStr = widthAttr.replaceAll(RegExp(r'[^0-9.]'), '');
        final heightStr = heightAttr.replaceAll(RegExp(r'[^0-9.]'), '');

        svgWidth = double.tryParse(widthStr) ?? 800;
        svgHeight = double.tryParse(heightStr) ?? 800;
      } else {
        // Try to get viewBox if width/height not available
        final viewBox = svgElement.getAttribute('viewBox');
        if (viewBox != null) {
          final parts = viewBox.split(' ');
          if (parts.length == 4) {
            svgWidth = double.tryParse(parts[2]) ?? 800;
            svgHeight = double.tryParse(parts[3]) ?? 800;
          }
        }
      }

      print('Parsed SVG dimensions: ${svgWidth}x${svgHeight}');
    } catch (e) {
      print('Error parsing SVG dimensions: $e');
      // Fallback to default dimensions
      svgWidth = 800;
      svgHeight = 800;
    }
  }
  void onNavigationDataReceived(Map<String, dynamic> nav) async {
    final dest = nav['destination'] as String?;
    final curr = nav['currentLocation'] as String?;
    if (dest == null || curr == null || dest.isEmpty || curr.isEmpty) return;

    final url = Uri.parse(Constants.getRoute);
    svgData = await generalService.sendSvgRequest(
      url: url,
      method: "GET",
      queryParams: {
        'buildingId': widget.building.buildingId.toString(),
        'floorId': selectedFloor.toString(),
        'start': dest,
        'goal': curr,
      },
    );
    if (mounted) setState(() {});
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
                IconButton(
                  icon: Icon(
                    isTrackingEnabled ? Icons.location_on : Icons.location_off,
                    color: isTrackingEnabled ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      isTrackingEnabled = !isTrackingEnabled;
                    });
                    if (isTrackingEnabled) {
                      // resume polling
                      _startLocationTracking();
                    } else {
                      // stop polling and clear
                      locationTimer?.cancel();
                      setState(() => userLocation = null);
                    }
                  },
                ),
                //TODO for debug circular progress bar when HTTP sending
                // // only show spinner while loading *and* tracking is on
                // if (isTrackingEnabled && isLocationLoading)
                //   const Padding(
                //     padding: EdgeInsets.only(left: 4),
                //     child: SizedBox(
                //       width: 12,
                //       height: 12,
                //       child: CircularProgressIndicator(
                //         strokeWidth: 2,
                //         valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                //       ),
                //     ),
                //   ),
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
                        });
                        _loadSvg();
                        _loadRoomNames();
                        fetchUserLocation();
                      },
                    ),
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
              onNavigationPressed: onNavigationDataReceived,
              places: places,
            ),
          ),
        ],
      ),
    );
  }
}

class SvgMapWithLocation extends StatefulWidget {
  final String svgData;
  final double svgWidth;
  final double svgHeight;
  final UserLocation? userLocation;

  const SvgMapWithLocation({
    Key? key,
    required this.svgData,
    required this.svgWidth,
    required this.svgHeight,
    this.userLocation,
  }) : super(key: key);

  @override
  _SvgMapWithLocationState createState() => _SvgMapWithLocationState();
}

class _SvgMapWithLocationState extends State<SvgMapWithLocation> {
  final TransformationController _transformationController =
  TransformationController();

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.1,
      maxScale: 5.0,
      constrained: false,
      child: Container(
        width: widget.svgWidth,
        height: widget.svgHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1) SVG background
            SvgPicture.string(
              widget.svgData,
              width: widget.svgWidth,
              height: widget.svgHeight,
              fit: BoxFit.fill,
            ),

            // 2) the pulsing blue dot
            if (widget.userLocation != null)
              Positioned(
                left: widget.userLocation!.x - 12,
                top: widget.userLocation!.y - 12,
                child: const AnimatedLocationDot(),
              ),
          ],
        ),
      ),
    );
  }
}

class AnimatedLocationDot extends StatefulWidget {
  const AnimatedLocationDot({Key? key}) : super(key: key);

  @override
  _AnimatedLocationDotState createState() => _AnimatedLocationDotState();
}

class _AnimatedLocationDotState extends State<AnimatedLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(duration: const Duration(seconds: 2), vsync: this)
    ..repeat(reverse: true);
  late final Animation<double> _anim = Tween(begin: 1.0, end: 1.5).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24 * _anim.value,
            height: 24 * _anim.value,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
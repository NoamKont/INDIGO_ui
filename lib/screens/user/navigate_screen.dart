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
  bool isTrackingEnabled = false;
  bool isRouteLoading = false;

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

  void initState(){
    super.initState();
    _initAsync();
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
          SnackBar(content: Text('Initialization failed: $e')),
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
    fetchUserLocation();
    locationTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (mounted && !isPdrRunning) fetchUserLocation();
      },
    );
  }

  void _startPdr() {
    if (isPdrRunning || !isTrackingEnabled) return;

    // Ensure we have a location before starting PDR
    if (userLocation == null) {
      fetchUserLocation().then((_) {
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
      fetchUserLocation();
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
    double tempOffset = pdrNorthOffset;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Align North Direction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rotate the adjustment to align the arrow with the north direction on your floor map.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Compass visualization
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // North arrow
                        Transform.rotate(
                          angle: tempOffset * pi / 180.0,
                          child: const Icon(
                            Icons.navigation,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                        // N, E, S, W labels
                        const Positioned(top: 8, child: Text('N', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Positioned(right: 8, child: Text('E', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Positioned(bottom: 8, child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Positioned(left: 8, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Slider for adjustment
                  Text('Adjustment: ${tempOffset.toStringAsFixed(0)}°'),
                  Slider(
                    value: tempOffset,
                    min: -180,
                    max: 180,
                    divisions: 72, // 5-degree increments
                    label: '${tempOffset.toStringAsFixed(0)}°',
                    onChanged: (value) {
                      setDialogState(() {
                        tempOffset = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      pdrNorthOffset = tempOffset;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _togglePdrMode() {
    if (!isTrackingEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location tracking first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (isPdrRunning) {
      // stopping
      _stopPdr();
      return;
    }

    // starting
    fetchUserLocation().then((_) {
      _resetPdr();        // zero counters, keep current dot as anchor
      _startPdr();        // this will set isPdrRunning = true inside _startPdrSensors()
      _showNorthAlignmentDialog();
    });
  }

  Future<void> fetchUserLocation() async {
    if (isLocationLoading) return;

    setState(() => isLocationLoading = true);

    try {
      final featureVector = await wifiService.scanFeatureVector();
      //TODO delete
      print(featureVector);
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

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Route Error'),
            ],
          ),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

  void _parseSvgDimensions(String svgString) {
    try {
      final document = XmlDocument.parse(svgString);
      final svgElement = document.findAllElements('svg').first;

      final widthAttr = svgElement.getAttribute('width');
      final heightAttr = svgElement.getAttribute('height');

      if (widthAttr != null && heightAttr != null) {
        final widthStr = widthAttr.replaceAll(RegExp(r'[^0-9.]'), '');
        final heightStr = heightAttr.replaceAll(RegExp(r'[^0-9.]'), '');

        svgWidth = double.tryParse(widthStr) ?? 800;
        svgHeight = double.tryParse(heightStr) ?? 800;
      } else {
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
      svgWidth = 800;
      svgHeight = 800;
    }
  }

  void onNavigationDataReceived(Map<String, dynamic> nav) async {
    final dest = nav['destination'] as String?;
    final curr = nav['currentLocation'] as String?;
    if (dest == null || curr == null || dest.isEmpty || curr.isEmpty) return;

    if (!mounted) return;
    setState(() {
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
      await _showErrorDialog(errorText);
      await _loadSvg();
    } else {
      _parseSvgDimensions(newSvg!);
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
                // PDR Mode Button
                IconButton(
                  icon: Icon(
                    isPdrRunning ? Icons.directions_walk : Icons.directions_walk_outlined,
                    color: isPdrRunning ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  tooltip: 'PDR Mode',
                  onPressed: _togglePdrMode,
                ),

                // North alignment button (only visible in PDR mode)
                if (isPdrRunning)
                  IconButton(
                    icon: const Icon(Icons.compass_calibration, size: 20),
                    tooltip: 'Align North',
                    onPressed: _showNorthAlignmentDialog,
                  ),

                // Location tracking toggle
                IconButton(
                  icon: Icon(
                    isTrackingEnabled ? Icons.location_on : Icons.location_off,
                    color: isTrackingEnabled ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  tooltip: 'Location Tracking',
                  onPressed: () {
                    setState(() {
                      isTrackingEnabled = !isTrackingEnabled;
                    });

                    if (isTrackingEnabled) {
                      _startLocationTracking();
                    } else {
                      locationTimer?.cancel();
                      _stopPdr();
                      setState(() {
                        isPdrRunning = false;
                        userLocation = null;
                      });
                    }
                  },
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
                        });
                        _loadSvg();
                        _loadRoomNames();
                        _loadOneCmSvg();

                        if (isPdrRunning) {
                          _resetPdr();
                        } else if (isTrackingEnabled) {
                          fetchUserLocation();
                        }
                      },
                    ),

                    // PDR info when active
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
                            'PDR: ${pdrSteps} steps | ${_getCurrentPositionInMeters()}',
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
            SvgPicture.string(
              widget.svgData,
              width: widget.svgWidth,
              height: widget.svgHeight,
              fit: BoxFit.fill,
            ),
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
            width: 17 * _anim.value,
            height: 17 * _anim.value,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 8.5,
            height: 8.5,
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
// screens/user_floor_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Building.dart';
import '../models/navigation_data.dart';
import '../services/general.dart';
import '../services/location/location_tracking_service.dart';
import '../services/location/pdr_service.dart';
import '../services/navigation/navigation_service.dart';
import '../services/admin/positioning_service.dart';
import '../widgets/floor_picker.dart';
import '../widgets/navigation_bottom_sheet.dart';
import '../widgets/map/svg_map_with_location.dart';
import '../widgets/dialogs/error_dialog.dart';
import '../widgets/dialogs/north_alignment_dialog.dart';
import '../utils/svg_parser.dart';
import '../constants.dart';

class UserFloorView extends StatefulWidget {
  final Building building;

  const UserFloorView({Key? key, required this.building}) : super(key: key);

  @override
  State<UserFloorView> createState() => _UserFloorViewState();
}

class _UserFloorViewState extends State<UserFloorView> {
  // UI State
  int selectedFloor = 1;
  String? svgData;
  List<int> floorsList = [];
  List<String> places = [];
  double svgWidth = 800;
  double svgHeight = 800;

  // Services
  final GeneralService _generalService = GeneralService();
  final PositioningService _positioningService = PositioningService();
  late final LocationTrackingService _locationService;
  late final PdrService _pdrService;
  late final NavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadFloorsAndData();
  }

  void _initializeServices() {
    _locationService = LocationTrackingService();
    _pdrService = PdrService();
    _navigationService = NavigationService();

    // Set initial context for location service
    _locationService.setContext(
      buildingId: widget.building.buildingId,
      floor: selectedFloor,
    );

    // Set up listeners to update local state
    _locationService.addListener(_onLocationServiceChanged);
    _pdrService.addListener(_onPdrServiceChanged);
    _navigationService.addListener(_onNavigationServiceChanged);

    // Initialize services
    _locationService.initialize().catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization failed: $e')),
        );
      }
    });
  }

  // Missing listener methods
  void _onLocationServiceChanged() {
    if (mounted) {
      setState(() {
        // This will trigger UI updates when location service changes
      });
    }
  }

  void _onPdrServiceChanged() {
    if (mounted) {
      setState(() {
        // This will trigger UI updates when PDR service changes
      });
    }
  }

  void _onNavigationServiceChanged() {
    if (mounted) {
      setState(() {
        // This will trigger UI updates when navigation service changes
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _locationService.removeListener(_onLocationServiceChanged);
    _pdrService.removeListener(_onPdrServiceChanged);
    _navigationService.removeListener(_onNavigationServiceChanged);

    _locationService.dispose();
    _pdrService.dispose();
    _navigationService.dispose();
    super.dispose();
  }

  Future<void> _loadFloorsAndData() async {
    try {
      final list = await _generalService.getFloors(
        buildingId: widget.building.buildingId,
      );
      if (!mounted) return;

      setState(() {
        floorsList = list;
        if (list.isNotEmpty) selectedFloor = list.first;
      });

      await _loadSvg();
      await _loadRoomNames();
      await _loadMetersToPixelScale();
    } catch (e) {
      debugPrint('Error loading floors: $e');
    }
  }

  Future<void> _loadSvg() async {
    final url = Uri.parse(Constants.getFloorSvg);
    svgData = await _generalService.sendSvgRequest(
      url: url,
      method: "GET",
      queryParams: {
        'buildingId': widget.building.buildingId.toString(),
        'floorId': selectedFloor.toString(),
      },
    );

    if (svgData != null) {
      final dimensions = SvgParser.parseDimensions(svgData!);
      setState(() {
        svgWidth = dimensions.width;
        svgHeight = dimensions.height;
      });

      // Update PDR service with new dimensions
      _pdrService.setSvgDimensions(svgWidth, svgHeight);
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadRoomNames() async {
    try {
      final url = Uri.parse(Constants.getDoorsName);
      places = await _generalService.fetchRoomsNameFromFloor(
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

  Future<void> _loadMetersToPixelScale() async {
    try {
      final scale = await _positioningService.fetchOneCmSvg(
        widget.building.buildingId,
        selectedFloor,
      );
      _pdrService.setMetersToPixelScale(scale);
      debugPrint('Meters to pixel scale: $scale');
    } catch (e) {
      debugPrint('Error loading meters to pixel scale: $e');
    }
  }

  void _onFloorChanged(int floor) {
    setState(() {
      selectedFloor = floor;
    });

    // Update location service context
    _locationService.updateFloor(floor);
    _locationService.setContext(
      buildingId: widget.building.buildingId,
      floor: floor,
    );

    // Stop PDR when changing floors
    _pdrService.stopPdr();

    // Reload floor data
    _loadSvg();
    _loadRoomNames();
    _loadMetersToPixelScale();

    // Fetch new location if tracking is enabled
    if (_locationService.isTrackingEnabled) {
      _locationService.fetchUserLocationManual(
        buildingId: widget.building.buildingId,
        selectedFloor: selectedFloor,
      );
    }
  }

  void _toggleLocationTracking() {
    if (_locationService.isTrackingEnabled) {
      _locationService.stopTracking();
      _pdrService.stopPdr();
    } else {
      _locationService.startTracking(
        buildingId: widget.building.buildingId,
        floor: selectedFloor,
      );
    }
  }

  void _togglePdrMode() {
    if (!_locationService.isTrackingEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location tracking first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_pdrService.isPdrRunning) {
      _pdrService.stopPdr();
      return;
    }

    // Start PDR mode
    if (_locationService.userLocation != null) {
      _pdrService.setInitialLocation(_locationService.userLocation!);
      _pdrService.resetPdr();
      _pdrService.startPdr();
      _showNorthAlignmentDialog();
    } else {
      // Fetch location first, then start PDR
      _locationService.fetchUserLocationManual(
        buildingId: widget.building.buildingId,
        selectedFloor: selectedFloor,
      ).then((_) {
        if (_locationService.userLocation != null) {
          _pdrService.setInitialLocation(_locationService.userLocation!);
          _pdrService.resetPdr();
          _pdrService.startPdr();
          _showNorthAlignmentDialog();
        }
      });
    }
  }

  void _showNorthAlignmentDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NorthAlignmentDialog(
        initialOffset: _pdrService.pdrNorthOffset,
        onOffsetChanged: (offset) => _pdrService.setNorthOffset(offset),
      ),
    );
  }

  void _resetPdr() {
    _pdrService.resetPdr();
    // Fetch fresh location
    if (_locationService.isTrackingEnabled) {
      _locationService.fetchUserLocationManual(
        buildingId: widget.building.buildingId,
        selectedFloor: selectedFloor,
      ).then((_) {
        if (_locationService.userLocation != null) {
          _pdrService.setInitialLocation(_locationService.userLocation!);
        }
      });
    }
  }

  Future<void> _handleNavigation(Map<String, dynamic> navData) async {
    final navigationData = NavigationData.fromJson(navData);
    final dest = navigationData.destination;
    final curr = navigationData.currentLocation;

    if (dest == null || curr == null || dest.isEmpty || curr.isEmpty) return;

    try {
      final routeSvg = await _navigationService.fetchRoute(
        buildingId: widget.building.buildingId,
        floorId: selectedFloor,
        start: dest,
        goal: curr,
      );

      if (routeSvg != null && mounted) {
        final dimensions = SvgParser.parseDimensions(routeSvg);
        setState(() {
          svgData = routeSvg;
          svgWidth = dimensions.width;
          svgHeight = dimensions.height;
        });

        _pdrService.setSvgDimensions(svgWidth, svgHeight);
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(context, e.toString());
        // Reload original SVG on error
        await _loadSvg();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _locationService),
        ChangeNotifierProvider.value(value: _pdrService),
        ChangeNotifierProvider.value(value: _navigationService),
      ],
      child: Scaffold(
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
                  Consumer<PdrService>(
                    builder: (context, pdrService, child) => IconButton(
                      icon: Icon(
                        pdrService.isPdrRunning
                            ? Icons.directions_walk
                            : Icons.directions_walk_outlined,
                        color: pdrService.isPdrRunning
                            ? Colors.green
                            : Colors.grey,
                        size: 20,
                      ),
                      tooltip: 'PDR Mode',
                      onPressed: _togglePdrMode,
                    ),
                  ),

                  // North alignment button (only visible in PDR mode)
                  Consumer<PdrService>(
                    builder: (context, pdrService, child) => pdrService.isPdrRunning
                        ? IconButton(
                      icon: const Icon(Icons.compass_calibration, size: 20),
                      tooltip: 'Align North',
                      onPressed: _showNorthAlignmentDialog,
                    )
                        : const SizedBox.shrink(),
                  ),

                  // Location tracking toggle
                  Consumer<LocationTrackingService>(
                    builder: (context, locationService, child) => IconButton(
                      icon: Icon(
                        locationService.isTrackingEnabled
                            ? Icons.location_on
                            : Icons.location_off,
                        color: locationService.isTrackingEnabled
                            ? Colors.blue
                            : Colors.grey,
                        size: 20,
                      ),
                      tooltip: 'Location Tracking',
                      onPressed: _toggleLocationTracking,
                    ),
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
                        onFloorSelected: _onFloorChanged,
                      ),

                      // PDR info when active
                      Consumer<PdrService>(
                        builder: (context, pdrService, child) => pdrService.isPdrRunning
                            ? Expanded(
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    'PDR: ${pdrService.pdrSteps} steps | ${pdrService.getCurrentPositionInMeters()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                tooltip: 'Reset PDR',
                                onPressed: _resetPdr,
                              ),
                            ],
                          ),
                        )
                            : const SizedBox.shrink(),
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
                        : Consumer2<LocationTrackingService, PdrService>(
                      builder: (context, locationService, pdrService, child) {
                        // Use PDR location if PDR is running, otherwise use location service
                        final userLocation = pdrService.isPdrRunning
                            ? pdrService.currentLocation
                            : locationService.userLocation;

                        return SvgMapWithLocation(
                          svgData: svgData!,
                          userLocation: userLocation,
                          svgWidth: svgWidth,
                          svgHeight: svgHeight,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: NavigationBottomSheet(
                onNavigationPressed: _handleNavigation,
                places: places,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
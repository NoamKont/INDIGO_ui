import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class SensorDataCollector {
  // Sensor streams
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Current sensor values
  MagnetometerEvent? _currentMagnetic;
  AccelerometerEvent? _currentAccelerometer;
  GyroscopeEvent? _currentGyroscope;
  List<WiFiAccessPoint> _currentWiFiList = [];

  // Configuration
  final String serverUrl;
  final String buildingId;

  SensorDataCollector({
    required this.serverUrl,
    required this.buildingId,
  });

  /// Initialize sensors and permissions
  Future<bool> initialize() async {
    try {
      // Request permissions
      await _requestPermissions();

      // Start sensor listeners
      _startSensorListeners();

      return true;
    } catch (e) {
      print('Error initializing sensors: $e');
      return false;
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    // WiFi scanning permissions
    if (Platform.isAndroid) {
      await Permission.location.request();
      await Permission.nearbyWifiDevices.request();
    } else if (Platform.isIOS) {
      await Permission.location.request();
    }
  }

  /// Start listening to sensor streams
  void _startSensorListeners() {
    // Magnetometer
    _magnetometerSubscription = magnetometerEventStream().listen(
          (MagnetometerEvent event) {
        _currentMagnetic = event;
      },
    );

    // Accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen(
          (AccelerometerEvent event) {
        _currentAccelerometer = event;
      },
    );

    // Gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen(
          (GyroscopeEvent event) {
        _currentGyroscope = event;
      },
    );
  }

  /// Scan WiFi networks
  Future<void> _scanWiFi() async {
    try {
      // Check if WiFi scan is supported
      final can = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );

      if (can != CanGetScannedResults.yes) {
        print('Cannot get WiFi scan results');
        return;
      }

      // Start WiFi scan
      final result = await WiFiScan.instance.startScan();
      if (result) {
        // Wait a bit for scan to complete
        await Future.delayed(const Duration(seconds: 2));

        // Get scan results
        _currentWiFiList = await WiFiScan.instance.getScannedResults();
      }
    } catch (e) {
      print('Error scanning WiFi: $e');
    }
  }

  /// Collect fingerprint data for mapping
  Future<Map<String, dynamic>> collectFingerprintData({
    required double x,
    required double y,
    required int floor,
    required String pointName,
  }) async {
    // Scan WiFi first
    await _scanWiFi();

    // Wait a moment for sensors to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    final data = {
      'location': {
        'x': x,
        'y': y,
        'floor': floor,
        'building_id': buildingId,
        'point_name': pointName,
      },
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': {
        'model': _getDeviceModel(),
        'os': Platform.isAndroid ? 'Android' : 'iOS',
        'app_version': '1.0.0',
      },
      'sensor_data': {
        'wifi': _currentWiFiList.map((ap) => {
          'bssid': ap.bssid,
          'ssid': ap.ssid,
          'rssi': ap.level,
        }).toList(),
        'magnetic': _currentMagnetic != null ? {
          'x': _currentMagnetic!.x,
          'y': _currentMagnetic!.y,
          'z': _currentMagnetic!.z,
          'magnitude': _calculateMagneticMagnitude(_currentMagnetic!),
        } : null,
        'accelerometer': _currentAccelerometer != null ? {
          'x': _currentAccelerometer!.x,
          'y': _currentAccelerometer!.y,
          'z': _currentAccelerometer!.z,
        } : null,
        'gyroscope': _currentGyroscope != null ? {
          'x': _currentGyroscope!.x,
          'y': _currentGyroscope!.y,
          'z': _currentGyroscope!.z,
        } : null,
      },
    };

    return data;
  }

  /// Collect positioning data for regular users
  Future<Map<String, dynamic>> collectPositioningData({
    required String userId,
  }) async {
    // Scan WiFi first
    await _scanWiFi();

    // Wait a moment for sensors to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': {
        'model': _getDeviceModel(),
        'os': Platform.isAndroid ? 'Android' : 'iOS',
      },
      'sensor_data': {
        'wifi': _currentWiFiList.map((ap) => {
          'bssid': ap.bssid,
          'ssid': ap.ssid,
          'rssi': ap.level,
        }).toList(),
        'magnetic': _currentMagnetic != null ? {
          'x': _currentMagnetic!.x,
          'y': _currentMagnetic!.y,
          'z': _currentMagnetic!.z,
          'magnitude': _calculateMagneticMagnitude(_currentMagnetic!),
        } : null,
      },
      'building_id': buildingId,
      'user_id': userId,
    };

    return data;
  }

  /// Send fingerprint data to server
  Future<bool> sendFingerprintToServer(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/fingerprints'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending fingerprint: $e');
      return false;
    }
  }

  /// Send positioning request to server
  Future<Map<String, dynamic>?> requestPosition(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/position'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error requesting position: $e');
      return null;
    }
  }

  /// Calculate magnetic field magnitude
  double _calculateMagneticMagnitude(MagnetometerEvent event) {
    return math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
  }

  /// Get device model (simplified)
  String _getDeviceModel() {
    // You might want to use device_info_plus package for more detailed info
    return Platform.isAndroid ? 'Android Device' : 'iOS Device';
  }

  /// Stop sensor listeners
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }
}
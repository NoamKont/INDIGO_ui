import 'package:flutter/material.dart';
import '../services/sensor_data_collector.dart';

class FingerprintCollectionScreen extends StatefulWidget {
  @override
  _FingerprintCollectionScreenState createState() => _FingerprintCollectionScreenState();
}

class _FingerprintCollectionScreenState extends State<FingerprintCollectionScreen> {
  final SensorDataCollector _collector = SensorDataCollector(
    serverUrl: 'https://your-server.com',
    buildingId: 'building_123',
  );

  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _pointNameController = TextEditingController();

  bool _isCollecting = false;
  bool _isInitialized = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeSensors();
  }

  Future<void> _initializeSensors() async {
    final success = await _collector.initialize();
    setState(() {
      _isInitialized = success;
      _status = success ? 'Ready to collect fingerprints' : 'Failed to initialize sensors';
    });
  }

  // Future<void> _collectFingerprint() async {
  //   if (!_isInitialized) return;
  //
  //   setState(() {
  //     _isCollecting = true;
  //     _status = 'Collecting sensor data...';
  //   });
  //
  //   try {
  //     // Validate inputs
  //     final x = double.tryParse(_xController.text);
  //     final y = double.tryParse(_yController.text);
  //     final floor = int.tryParse(_floorController.text);
  //     final pointName = _pointNameController.text.trim();
  //
  //     if (x == null || y == null || floor == null || pointName.isEmpty) {
  //       setState(() {
  //         _status = 'Please fill all fields correctly';
  //         _isCollecting = false;
  //       });
  //       return;
  //     }
  //
  //     // Collect data
  //     final data = await _collector.collectFingerprintData(
  //       x: x,
  //       y: y,
  //       floor: floor,
  //       pointName: pointName,
  //     );
  //
  //     setState(() {
  //       _status = 'Sending to server...';
  //     });
  //
  //     // Send to server
  //     final success = await _collector.sendFingerprintToServer(data);
  //
  //     setState(() {
  //       _status = success
  //           ? 'Fingerprint collected successfully!'
  //           : 'Failed to send fingerprint to server';
  //       _isCollecting = false;
  //     });
  //
  //     if (success) {
  //       // Clear form for next collection
  //       _pointNameController.clear();
  //     }
  //
  //   } catch (e) {
  //     setState(() {
  //       _status = 'Error: $e';
  //       _isCollecting = false;
  //     });
  //   }
  // }
  Future<void> _collectFingerprint() async {
    if (!_isInitialized) {
      print('[DEBUG] Sensors not initialized, aborting fingerprint collection.');
      return;
    }

    setState(() {
      _isCollecting = true;
      _status = 'Collecting sensor data...';
    });

    try {
      // Validate inputs
      final x = double.tryParse(_xController.text);
      final y = double.tryParse(_yController.text);
      final floor = int.tryParse(_floorController.text);
      final pointName = _pointNameController.text.trim();

      print('[DEBUG] Input values: x=$x, y=$y, floor=$floor, pointName="$pointName"');

      if (x == null || y == null || floor == null || pointName.isEmpty) {
        print('[DEBUG] Invalid inputs, one or more values are null or empty.');
        setState(() {
          _status = 'Please fill all fields correctly';
          _isCollecting = false;
        });
        return;
      }

      print('[DEBUG] Starting fingerprint data collection...');
      final data = await _collector.collectFingerprintData(
        x: x,
        y: y,
        floor: floor,
        pointName: pointName,
      );

      print('[DEBUG] Fingerprint data collected:\n$data');

      setState(() {
        _status = 'Sending to server...';
      });

      print('[DEBUG] Sending fingerprint data to server...');
      final success = await _collector.sendFingerprintToServer(data);

      print('[DEBUG] Server response: success=$success');

      setState(() {
        _status = success
            ? 'Fingerprint collected successfully!'
            : 'Failed to send fingerprint to server';
        _isCollecting = false;
      });

      if (success) {
        print('[DEBUG] Clearing point name input field.');
        _pointNameController.clear();
      }

    } catch (e, stack) {
      print('[ERROR] Exception during fingerprint collection: $e');
      print('[ERROR] Stack trace: $stack');
      setState(() {
        _status = 'Error: $e';
        _isCollecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fingerprint Collection'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isInitialized ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _isInitialized ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),

            // Input fields
            TextField(
              controller: _xController,
              decoration: InputDecoration(
                labelText: 'X Coordinate',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12),

            TextField(
              controller: _yController,
              decoration: InputDecoration(
                labelText: 'Y Coordinate',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12),

            TextField(
              controller: _floorController,
              decoration: InputDecoration(
                labelText: 'Floor Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),

            TextField(
              controller: _pointNameController,
              decoration: InputDecoration(
                labelText: 'Point Name/Description',
                border: OutlineInputBorder(),
                hintText: 'e.g., hallway_entrance_A',
              ),
            ),
            SizedBox(height: 24),

            // Collect button
            ElevatedButton(
              onPressed: _isInitialized && !_isCollecting ? _collectFingerprint : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCollecting
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Collecting...', style: TextStyle(color: Colors.white)),
                ],
              )
                  : Text(
                'Collect Fingerprint',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            SizedBox(height: 16),

            // Instructions
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Stand at the exact location you want to map'),
                    Text('2. Enter the precise coordinates (X, Y)'),
                    Text('3. Enter the floor number'),
                    Text('4. Give the point a descriptive name'),
                    Text('5. Hold phone steady and tap "Collect Fingerprint"'),
                    Text('6. Wait for data collection to complete'),
                    SizedBox(height: 12),
                    Text(
                      'Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Collect points every 2-3 meters'),
                    Text('• Keep phone orientation consistent'),
                    Text('• Avoid collecting near moving metal objects'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _collector.dispose();
    _xController.dispose();
    _yController.dispose();
    _floorController.dispose();
    _pointNameController.dispose();
    super.dispose();
  }
}

//use case
// import 'package:flutter/material.dart';
// import 'screens/fingerprint_collection_screen.dart'; // adjust path if needed
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Fingerprint Test',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: FingerprintCollectionScreen(),
//     );
//   }
// }
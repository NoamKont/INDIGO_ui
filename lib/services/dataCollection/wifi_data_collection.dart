// lib/services/data_collection.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiAp {
  final String bssid;
  final int rssi;
  WifiAp(this.bssid, this.rssi);
}

class WifiDataCollectionService {
  final String targetSsid;
  final Duration scanInterval;
  StreamSubscription<List<WiFiAccessPoint>>? _scanSub;
  List<WifiAp> _latest = [];
  File? _csvFile;

  WifiDataCollectionService({
    required this.targetSsid,
    this.scanInterval = const Duration(seconds: 2),
  });

  /// Exposes the latest filtered AP list (target SSID only)
  List<WifiAp> get latest => List.unmodifiable(_latest);

  /// Call once on app start
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _csvFile = File('${dir.path}/wifi_data.csv');
  }

  /// Request needed permissions for Wi‑Fi scanning (Android 10+)
  Future<bool> ensurePermissions() async {
    final perms = <Permission>[
      Permission.locationWhenInUse, // WiFi scan requires location
      Permission.location,          // some devices need this too
      Permission.nearbyWifiDevices, // Android 13+
    ];

    final results = await perms.request();
    final granted = results.values.every((s) => s.isGranted);
    return granted;
  }

  /// Start continuous scanning every [scanInterval]
  Future<void> startScanning() async {
    await stopScanning();
    // Periodic pull using onScannedResultsAvailable + timer fallback
    _scanSub = WiFiScan.instance.onScannedResultsAvailable.listen((aps) {
      _updateFromResults(aps);
    });

    // Trigger scans periodically
    Timer.periodic(scanInterval, (_) async {
      await WiFiScan.instance.startScan();
      final aps = await WiFiScan.instance.getScannedResults();
      _updateFromResults(aps);
    });
  }

  Future<void> stopScanning() async {
    await _scanSub?.cancel();
    _scanSub = null;
  }

  void _updateFromResults(List<WiFiAccessPoint> aps) {
    final filtered = aps.where((ap) => (ap.ssid ?? '') == targetSsid).toList();
    _latest = filtered
        .map((ap) => WifiAp(ap.bssid ?? '', ap.level ?? -100))
        .where((x) => x.bssid.isNotEmpty)
        .toList();
  }

  /// Build a map {BSSID: RSSI} from current scan
  Map<String, String> currentBssidMap() {
    final m = <String, String>{};
    for (final ap in _latest) {
      m[ap.bssid] = ap.rssi.toString();
    }
    return m;
  }

  /// Append/merge a row into wifi_data.csv with dynamic BSSID headers (like your Kotlin code)
  Future<File> recordVertex(String vertex) async {
    if (_csvFile == null) await init();
    final file = _csvFile!;
    final currentMap = currentBssidMap();

    final existingRows = <Map<String, String>>[];
    final allBssids = <String>{};
    List<String> header = ['Vertex'];

    if (await file.exists()) {
      final lines = await file.readAsLines();
      if (lines.isNotEmpty) {
        header = lines.first.split(',');
        allBssids.addAll(header.skip(1));
        for (int i = 1; i < lines.length; i++) {
          final parts = _safeSplit(lines[i], header.length);
          existingRows.add(Map<String, String>.fromIterables(header, parts));
        }
      }
    }

    allBssids.addAll(currentMap.keys);
    final sortedBssids = allBssids.toList()..sort();
    final newHeader = ['Vertex', ...sortedBssids];

    // Create new row
    final newRow = <String, String>{'Vertex': vertex};
    for (final b in sortedBssids) {
      newRow[b] = currentMap[b] ?? '-100';
    }

    // Rewrite CSV (temp → replace)
    final temp = File('${file.parent.path}/temp_wifi_data.csv');
    final sink = temp.openWrite();
    sink.writeln(newHeader.join(','));

    for (final row in existingRows) {
      final fullRow = newHeader.map((k) => row[k] ?? (k == 'Vertex' ? '' : '-100'));
      sink.writeln(fullRow.join(','));
    }

    final newLine = newHeader.map((k) => newRow[k] ?? (k == 'Vertex' ? '' : '-100'));
    sink.writeln(newLine.join(','));
    await sink.flush();
    await sink.close();

    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
    return file;
  }

  /// Upload the CSV to your chosen endpoint (you'll set the URL later)
  Future<http.StreamedResponse> uploadCsv(
      Uri endpoint, {
        Map<String, String>? extraFields,
        String fieldName = 'file',
        String filename = 'wifi_data.csv',
      }) async {
    if (_csvFile == null) await init();
    final file = _csvFile!;
    if (!await file.exists()) {
      throw StateError('CSV file not found. Record at least one vertex first.');
    }

    final req = http.MultipartRequest('POST', endpoint);
    if (extraFields != null) req.fields.addAll(extraFields);
    req.files.add(await http.MultipartFile.fromPath(fieldName, file.path, filename: filename));
    return req.send();
  }

  String? get csvPath => _csvFile?.path;

  // Safer split that pads missing cells, so old lines don't crash when headers expand
  List<String> _safeSplit(String line, int expectedLen) {
    final parts = const LineSplitter()
        .convert(line.replaceAll('\r', ''))
        .expand((s) => s.split(','))
        .toList();
    if (parts.length >= expectedLen) return parts.sublist(0, expectedLen);
    return List<String>.from(parts)..addAll(List.filled(expectedLen - parts.length, ''));
  }
}

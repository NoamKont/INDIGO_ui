import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:indigo_test/models/Building.dart';
import 'package:http_parser/http_parser.dart';

import '../../models/Room.dart'; // For MediaType


class AdminService {

  /// This methods get the building list that the admin owns.
  Future<List<Building>> getUserBuildings() async {
    List<Building> buildings = [];

    buildings.addAll([
      Building(buildingId: 1, name: 'Building A', address: 'Location A'),
      Building(buildingId: 2, name: 'Building B', address: 'Location B'),
      Building(buildingId: 3, name: 'Building C', address: 'Location C')
    ]);
    return buildings;
  }

  Future<void> uploadDxfAndYaml({required String fileName, required Uint8List fileBytes, required String yaml,}) async
  {
    final uri = Uri.parse("http://172.20.10.14:8574/building/add");

    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'dwg',
        fileBytes,
        filename: fileName,
        contentType: MediaType('application', 'octet-stream'),
      ))
      ..files.add(http.MultipartFile.fromString(
        'yaml',
        yaml,
        filename: 'config.yaml',
        contentType: MediaType('text', 'plain'),
      ))
      ..fields['buildingId'] = '4';

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = await response.stream.bytesToString();
    return _parseUploadResponse(responseBody);
  }

  void _parseUploadResponse(String body) {
    final json = jsonDecode(body);
    final doorsJson = json['doors'] as List;

    final doors = doorsJson.map((d) {
      return Room(
        id: d['id'],
        x: (d['x'] as num).toDouble(),
        y: (d['y'] as num).toDouble(),
      );
    }).toList();
    if (doors.isEmpty) {
      throw Exception('No doors found in the response');
    }
    if (json['buildingId'] == null) {
      throw Exception('Building ID not found in the response');
    }
  }


  /// Fetches the SVG file **THAT THE ADMIN GETS** and can manage the labels and add nodes.
  static Future<Uint8List?> fetchAdminFloorSvgWithCache(int buildingId) async {
    final svgUrl = "https://your-api.com/buildings/$buildingId" ;
    try {
      final file = await DefaultCacheManager().getSingleFile(svgUrl);
      return await file.readAsBytes();
    } catch (e) {
      print('Error caching SVG: $e');
      return null;
    }
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:indigo_test/constants.dart';
import '../../models/Building.dart';

class HomeService {

  /// This methods get ALL the building List that the in the DATABASE.
  // Future<List<Building>> getALLBuildings() async {
  //   List<Building> buildings = [];
  //
  //
  //
  //
  //   buildings.addAll([
  //     Building(buildingId: 1, name: 'Watson', address: 'Tel-Aviv'),
  //     Building(buildingId: 2, name: 'Psychology', address: 'Tel-Aviv'),
  //     Building(buildingId: 3, name: 'Engineering', address: 'Tel-Aviv'),
  //     Building(buildingId: 4, name: 'Finance', address: 'Tel-Aviv'),
  //     Building(buildingId: 5, name: 'Communication', address: 'Tel-Aviv'),
  //   ]);
  //   return buildings;
  // }

  Future<List<Building>> getAllBuildings() async {
    final url = Uri.parse(Constants.getAllBuildingsNames); // Replace with your actual endpoint

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> ids = jsonDecode(response.body);

        // Create dummy metadata for each ID (in real case, fetch details or map by ID)
        final buildings = ids.map<Building>((idStr) {
          final id = int.parse(idStr.toString());
          return Building(
            buildingId: id,
            name: 'Building $id',
            address: 'Tel-Aviv',
          );
        }).toList();

        return buildings;
      } else {
        throw Exception('Failed to load buildings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllBuildings: $e');
      rethrow;
    }
  }

  /// Fetches the SVG file **THAT THE CLIENT GETS** from a URL and caches it using DefaultCacheManager.
  static Future<Uint8List?> loadUserSvgWithCache(int buildingId, int floor) async {
    final svgUrl = "https://your-api.com/buildings/$buildingId?floor=$floor"; // Replace with your actual URL;
    try {
      final file = await DefaultCacheManager().getSingleFile(svgUrl);
      return await file.readAsBytes();
    } catch (e) {
      print('Error caching SVG: $e');
      return null;
    }
  }
}
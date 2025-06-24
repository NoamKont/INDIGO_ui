import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../models/Building.dart';

class HomeService {

  /// This methods get ALL the building List that the in the DATABASE.
  Future<List<Building>> getALLBuildings() async {
    List<Building> buildings = [];

    buildings.addAll([
      Building(buildingId: 1, name: 'Watson', address: 'Tel-Aviv'),
      Building(buildingId: 2, name: 'Psychology', address: 'Tel-Aviv'),
      Building(buildingId: 3, name: 'Engineering', address: 'Tel-Aviv'),
      Building(buildingId: 4, name: 'Finance', address: 'Tel-Aviv'),
      Building(buildingId: 5, name: 'Communication', address: 'Tel-Aviv'),
    ]);
    return buildings;
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
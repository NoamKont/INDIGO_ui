import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:indigo_test/models/Building.dart';
import '../../constants.dart';

class PositioningService {

  Future<void> sendAll(int buildingId, int floorId, Map<String, Map<String, double>> data) async {
    final url = Uri.parse(Constants.train);
    // Build point list
    final points = data.entries.map((e) => {
      'name': e.key,
      ...e.value,
    }).toList();

    // Final payload structure
    final payload = {
      'buildingId': buildingId,
      'floorId': floorId,
      'featureVector': points,
    };

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print('Server response: ${response.statusCode} ${response.body}');
  }
}
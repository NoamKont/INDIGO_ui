import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../dataCollection/data_collection.dart';

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


  Future<UserLocation?> sendData(String uri, int buildingId, int floorId, Map<String, Map<String, double>> data) async {
    try {
      final url = Uri.parse(uri);

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
      if(response.statusCode == 200 || response.statusCode == 201){
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200) {
          // Check if response contains coordinates
          if (responseData.containsKey('x') && responseData.containsKey('y')) {
            return UserLocation.fromJson(responseData);
          } else {
            print('Server response does not contain location coordinates');
            return null;
          }
        } else {
          //return UserLocation(x: 213.038, y: 319.85); // Auditorium for now. Indicating no location found
          return UserLocation(x: 213.038, y: 350.85); // Auditorium for now. Indicating no location found
        }
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network error in sendAll: $e');
      return null;
    }
  }
}
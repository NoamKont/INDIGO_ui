import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Building.dart';


class BuildingService {

  Future<PlatformFile?> pickDwgFile() async {
    final result = await FilePicker.platform.pickFiles(
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first;
    }
    return null;
  }

  // Replace with your actual API base URL
  static const String _baseUrl = 'https://your-api-endpoint.com/api';

  // HTTP client instance
  final http.Client _client = http.Client();

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authentication headers if needed
    // 'Authorization': 'Bearer $token',
  };

  /// Creates a new building
  ///
  /// Sends a POST request to create a building with the provided name and address
  /// Returns the created Building object with the assigned buildingId
  Future<Building> createBuilding({
    required String name,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/buildings');

      final requestBody = {
        'name': name,
        'address': address,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Assuming the API returns the building data in this format:
        // {
        //   "id": 123,
        //   "name": "Building Name",
        //   "address": "Street, City"
        // }

        return Building(
          buildingId: responseData['id'] ?? responseData['buildingId'],
          name: responseData['name'],
          address: responseData['address'],
        );
      } else {
        throw BuildingServiceException(
          'Failed to create building: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on http.ClientException catch (e) {
      throw BuildingServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw BuildingServiceException('Invalid response format: ${e.message}');
    } catch (e) {
      throw BuildingServiceException('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetches all buildings
  ///
  /// Returns a list of all buildings from the server
  Future<List<Building>> getAllBuildings() async {
    try {
      final url = Uri.parse('$_baseUrl/buildings');

      final response = await _client.get(
        url,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        return responseData.map((buildingJson) => Building(
          buildingId: buildingJson['id'] ?? buildingJson['buildingId'],
          name: buildingJson['name'],
          address: buildingJson['address'],
        )).toList();
      } else {
        throw BuildingServiceException(
          'Failed to fetch buildings: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on http.ClientException catch (e) {
      throw BuildingServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw BuildingServiceException('Invalid response format: ${e.message}');
    } catch (e) {
      throw BuildingServiceException('Unexpected error: ${e.toString()}');
    }
  }

  /// Updates an existing building
  ///
  /// Sends a PUT request to update building information
  Future<Building> updateBuilding({
    required int buildingId,
    required String name,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/buildings/$buildingId');

      final requestBody = {
        'name': name,
        'address': address,
      };

      final response = await _client.put(
        url,
        headers: _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        return Building(
          buildingId: responseData['id'] ?? responseData['buildingId'],
          name: responseData['name'],
          address: responseData['address'],
        );
      } else {
        throw BuildingServiceException(
          'Failed to update building: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on http.ClientException catch (e) {
      throw BuildingServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw BuildingServiceException('Invalid response format: ${e.message}');
    } catch (e) {
      throw BuildingServiceException('Unexpected error: ${e.toString()}');
    }
  }

  /// Deletes a building
  ///
  /// Sends a DELETE request to remove a building
  Future<void> deleteBuilding(int buildingId) async {
    try {
      final url = Uri.parse('$_baseUrl/buildings/$buildingId');

      final response = await _client.delete(
        url,
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw BuildingServiceException(
          'Failed to delete building: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on http.ClientException catch (e) {
      throw BuildingServiceException('Network error: ${e.message}');
    } catch (e) {
      throw BuildingServiceException('Unexpected error: ${e.toString()}');
    }
  }

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Custom exception class for BuildingService errors
class BuildingServiceException implements Exception {
  final String message;

  const BuildingServiceException(this.message);

  @override
  String toString() => 'BuildingServiceException: $message';
}
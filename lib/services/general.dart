import 'dart:convert';
import 'package:http/http.dart' as http;


class GeneralService {


  static Future<String> sendSvgRequest({
    required Uri url,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final finalUrl = queryParams != null
          ? url.replace(queryParameters: queryParams)
          : url;

      http.Response response;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http
              .post(url, headers: headers, body: json.encode(body))
              .timeout(timeout);
          break;
        case 'GET':
          response = await http
              .get(finalUrl, headers: headers)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(url, headers: headers, body: json.encode(body))
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: headers)
              .timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('image/svg+xml') || contentType.contains('text/xml')) {
          return response.body;
        }

        try {
          final jsonData = json.decode(response.body);
          if (jsonData is Map<String, dynamic>) {
            if (jsonData.containsKey('svg_data')) return jsonData['svg_data'] as String;
            if (jsonData.containsKey('data')) return jsonData['data'] as String;
          }
        } catch (_) {
          // Not JSON - return raw
        }

        throw Exception('SVG data not found in response');
      } else {
        throw Exception('Request failed: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in sendSvgRequest: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Network error: Please check your internet connection');
      }
      rethrow;
    }
  }

}
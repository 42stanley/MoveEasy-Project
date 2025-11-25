import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DriverService {
  // Helper to get base URL based on platform
  String get baseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:5001'
      : 'http://192.168.1.102:5001'; // CHANGE TO YOUR PC IP IF NEEDED

  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/driver/stats/$driverId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      // Fallback data if backend is down
      return {
        "earnings": "KES 0",
        "trips": 0,
        "hours": 0.0
      };
    }
  }

  Future<List<dynamic>> getDriverTrips(String driverId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/driver/trips/$driverId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDriverReviews(String driverId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/driver/reviews/$driverId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      return {
        "rating": 0.0,
        "count": 0,
        "reviews": []
      };
    }
  }
}

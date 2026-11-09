import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class OpenStreetMapService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Reverse geocode (Latitude, Longitude -> Formatted Address)
  /// Uses OpenStreetMap's Nominatim API (Free, no Google API key required)
  static Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=jsonv2&lat=$latitude&lon=$longitude&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'RestoMartApp/1.0 (info@restomart.pk)',
          'Accept': 'application/json',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        // Build readable structured address
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final parts = <String>[];
          
          final road = address['road'] ?? address['pedestrian'] ?? address['street'];
          final neighbourhood = address['neighbourhood'] ?? address['suburb'] ?? address['residential'];
          final cityDistrict = address['city_district'] ?? address['borough'];
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'];
          
          if (road != null && road.toString().trim().isNotEmpty) {
            parts.add(road.toString().trim());
          }
          if (neighbourhood != null && neighbourhood.toString().trim().isNotEmpty) {
            parts.add(neighbourhood.toString().trim());
          }
          if (cityDistrict != null && cityDistrict.toString().trim().isNotEmpty && cityDistrict != neighbourhood) {
            parts.add(cityDistrict.toString().trim());
          }
          if (city != null && city.toString().trim().isNotEmpty) {
            parts.add(city.toString().trim());
          }

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        // Fallback to display_name
        if (data['display_name'] != null) {
          final String displayName = data['display_name'];
          // Remove country if redundant or shorten long addresses
          return displayName;
        }
      }
    } catch (e) {
      log('OpenStreetMap Reverse Geocode Exception: $e');
    }
    return null;
  }

  /// Search address / autocomplete suggestions via OpenStreetMap Nominatim
  static Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/search?format=jsonv2&q=${Uri.encodeComponent(query)}&addressdetails=1&limit=5&countrycodes=pk',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'RestoMartApp/1.0 (info@restomart.pk)',
          'Accept': 'application/json',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) {
          return {
            'display_name': item['display_name'] ?? '',
            'lat': double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
            'lon': double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
          };
        }).toList();
      }
    } catch (e) {
      log('OpenStreetMap Search Exception: $e');
    }
    return [];
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;
import 'open_street_map_service.dart';

class GoogleAddressDetails {
  final String formattedAddress;
  final String houseNumber;
  final String street;
  final String area;
  final String landmark;
  final String city;
  final double latitude;
  final double longitude;

  GoogleAddressDetails({
    required this.formattedAddress,
    this.houseNumber = '',
    this.street = '',
    this.area = '',
    this.landmark = '',
    this.city = '',
    required this.latitude,
    required this.longitude,
  });

  /// Builds a clean, descriptive summary suitable for delivery
  String toDeliveryString() {
    final parts = <String>[];
    if (houseNumber.isNotEmpty) parts.add(houseNumber);
    if (street.isNotEmpty) parts.add(street);
    if (landmark.isNotEmpty) parts.add(landmark);
    if (area.isNotEmpty && area != landmark) parts.add(area);
    if (city.isNotEmpty && !area.toLowerCase().contains(city.toLowerCase())) {
      parts.add(city);
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return formattedAddress;
  }
}

class GoogleMapsService {
  static const String apiKey = 'AIzaSyD6YeHZtndlaifZ5y59glHqNciEbB-bhSQ';

  /// Reverse geocodes coordinates to a fully detailed address using Google Maps Geocoding API.
  /// Falls back to platform Geocoding & OpenStreetMap if network or API fails.
  static Future<GoogleAddressDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey&language=en',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;

        if (status == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final formatted = (result['formatted_address'] as String?) ?? '';
          
          String house = '';
          String street = '';
          String area = '';
          String landmark = '';
          String city = '';

          final components = result['address_components'] as List? ?? [];
          for (var comp in components) {
            final types = List<String>.from(comp['types'] ?? []);
            final longName = (comp['long_name'] as String?) ?? '';

            if (types.contains('street_number') || types.contains('premise') || types.contains('subpremise')) {
              house = house.isEmpty ? longName : '$house, $longName';
            } else if (types.contains('point_of_interest') || types.contains('establishment') || types.contains('landmark')) {
              landmark = landmark.isEmpty ? longName : '$landmark, $longName';
            } else if (types.contains('route')) {
              street = longName;
            } else if (types.contains('sublocality_level_1') || types.contains('sublocality') || types.contains('neighborhood')) {
              area = area.isEmpty ? longName : '$area, $longName';
            } else if (types.contains('sublocality_level_2')) {
              area = area.isEmpty ? longName : '$longName, $area';
            } else if (types.contains('locality')) {
              city = longName;
            } else if (types.contains('administrative_area_level_2') && city.isEmpty) {
              city = longName;
            }
          }

          // Clean up Plus Codes (e.g. "G9C5+5F5, ") from formatted address for clean display
          String cleanFormatted = formatted;
          final plusCodeRegex = RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,4},\s*');
          cleanFormatted = cleanFormatted.replaceFirst(plusCodeRegex, '').trim();

          return GoogleAddressDetails(
            formattedAddress: cleanFormatted.isNotEmpty ? cleanFormatted : formatted,
            houseNumber: house,
            street: street,
            area: area,
            landmark: landmark,
            city: city,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
    } catch (e) {
      debugPrint('Google Geocoding API reverseGeocode error: $e');
    }

    // --- Fallback 1: Platform native geocoder ---
    try {
      final placemarks = await geo.Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final parts = [p.name, p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .toSet()
            .toList();

        return GoogleAddressDetails(
          formattedAddress: parts.join(', '),
          houseNumber: p.name ?? '',
          street: p.street ?? '',
          area: p.subLocality ?? '',
          city: p.locality ?? '',
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (e) {
      debugPrint('Native geocoder fallback error: $e');
    }

    // --- Fallback 2: OpenStreetMap Nominatim ---
    try {
      final osm = await OpenStreetMapService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      if (osm != null && osm.isNotEmpty) {
        return GoogleAddressDetails(
          formattedAddress: osm,
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (_) {}

    return null;
  }

  /// Searches for places/addresses matching [query] using Google Maps Geocoding API.
  /// Biased to Pakistan with country:pk.
  /// Falls back to OpenStreetMap autocomplete if needed.
  static Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedQuery&components=country:pk&key=$apiKey&language=en',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;

        if (status == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          final List<Map<String, dynamic>> items = [];

          for (var r in results.take(6)) {
            final loc = r['geometry']?['location'];
            final lat = (loc?['lat'] as num?)?.toDouble() ?? 0.0;
            final lng = (loc?['lng'] as num?)?.toDouble() ?? 0.0;
            String addr = (r['formatted_address'] as String?) ?? '';

            // Strip leading plus code if present
            final plusCodeRegex = RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,4},\s*');
            addr = addr.replaceFirst(plusCodeRegex, '').trim();

            if (lat != 0.0 && lng != 0.0 && addr.isNotEmpty) {
              final split = addr.split(',');
              final mainText = split.first.trim();
              final secText = split.skip(1).join(',').trim();

              items.add({
                'display_name': addr,
                'main_text': mainText,
                'secondary_text': secText,
                'lat': lat,
                'lon': lng,
              });
            }
          }

          if (items.isNotEmpty) {
            return items;
          }
        }
      }
    } catch (e) {
      debugPrint('Google Geocoding searchAddress error: $e');
    }

    // Fallback: OpenStreetMap search
    return await OpenStreetMapService.searchAddress(query);
  }
}


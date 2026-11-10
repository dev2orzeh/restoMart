import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../../../core/services/google_maps_service.dart';
import 'package:flutter/material.dart';

class AddressController extends GetxController {
  final savedAddresses = <Map<String, String>>[].obs;
  final selectedAddressIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAddressesForCurrentUser();

    // Reload when auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      loadAddressesForCurrentUser();
    });
  }

  String _getStorageKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return 'saved_addresses_$uid';
    }
    return 'saved_addresses_guest';
  }

  Future<void> loadAddressesForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey();
    final String? addressesJson = prefs.getString(key);
    
    if (addressesJson != null && addressesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(addressesJson);
        final loaded = decoded.map((e) => Map<String, String>.from(e)).toList();
        
        // Remove legacy hardcoded dummy addresses from previous versions
        loaded.removeWhere((addr) => 
          (addr['label']?.contains('Karachi Kitchen') ?? false) || 
          (addr['address']?.contains('DHA Phase 6') ?? false)
        );

        // Deduplicate addresses based on normalized address string
        final uniqueLoaded = <Map<String, String>>[];
        for (final addr in loaded) {
          final normAddr = (addr['address'] ?? '').trim().toLowerCase();
          if (normAddr.isNotEmpty && !uniqueLoaded.any((u) => (u['address'] ?? '').trim().toLowerCase() == normAddr)) {
            uniqueLoaded.add(addr);
          }
        }

        savedAddresses.value = uniqueLoaded;
      } catch (e) {
        savedAddresses.clear();
      }
    } else {
      savedAddresses.clear();
    }

    // Auto-populate default address from Firestore user profile if savedAddresses is empty
    if (savedAddresses.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final String restaurantAddr = (data['restaurantAddress'] as String?) ?? (data['address'] as String?) ?? '';
            final String restaurantName = (data['restaurantName'] as String?) ?? (data['businessName'] as String?) ?? (data['name'] as String?) ?? 'My Restaurant';
            
            if (restaurantAddr.isNotEmpty) {
              final normAddr = restaurantAddr.trim().toLowerCase();
              if (!savedAddresses.any((a) => (a['address'] ?? '').trim().toLowerCase() == normAddr)) {
                savedAddresses.add({
                  'label': restaurantName,
                  'address': restaurantAddr,
                });
                _saveToStorage();
              }
            }
          }
        } catch (e) {
          // Ignore firestore load error if offline
        }
      }
    }

    // Always default selected address index to 0 (Default Address)
    if (savedAddresses.isNotEmpty) {
      if (selectedAddressIndex.value < 0 || selectedAddressIndex.value >= savedAddresses.length) {
        selectedAddressIndex.value = 0;
      }
    } else {
      selectedAddressIndex.value = 0;
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey();
    await prefs.setString(key, jsonEncode(savedAddresses));
  }

  void addAddress(String label, String address, {double? lat, double? lng}) {
    final norm = address.trim().toLowerCase();
    final existingIdx = savedAddresses.indexWhere((a) => (a['address'] ?? '').trim().toLowerCase() == norm);
    if (existingIdx >= 0) {
      if (lat != null && lng != null) {
        savedAddresses[existingIdx]['lat'] = lat.toString();
        savedAddresses[existingIdx]['lng'] = lng.toString();
        _saveToStorage();
      }
      selectedAddressIndex.value = existingIdx;
      return;
    }
    final item = <String, String>{
      'label': label,
      'address': address,
    };
    if (lat != null && lng != null) {
      item['lat'] = lat.toString();
      item['lng'] = lng.toString();
    }
    savedAddresses.add(item);
    selectedAddressIndex.value = savedAddresses.length - 1;
    _saveToStorage();
  }

  void setDefaultAddress(int index) {
    if (index > 0 && index < savedAddresses.length) {
      final chosen = savedAddresses.removeAt(index);
      savedAddresses.insert(0, chosen);
      selectedAddressIndex.value = 0;
      savedAddresses.refresh();
      _saveToStorage();
    } else if (index == 0) {
      selectedAddressIndex.value = 0;
      savedAddresses.refresh();
      _saveToStorage();
    }
  }

  void selectAddress(int index) {
    if (index >= 0 && index < savedAddresses.length) {
      selectedAddressIndex.value = index;
    }
  }

  void deleteAddress(int index) {
    if (index >= 0 && index < savedAddresses.length) {
      savedAddresses.removeAt(index);
      if (selectedAddressIndex.value >= savedAddresses.length) {
        selectedAddressIndex.value = savedAddresses.isEmpty ? 0 : savedAddresses.length - 1;
      }
      _saveToStorage();
    }
  }

  void clearAll() {
    savedAddresses.clear();
    selectedAddressIndex.value = 0;
  }

  Map<String, String>? get selectedAddress {
    if (savedAddresses.isEmpty) return null;
    final idx = selectedAddressIndex.value;
    if (idx >= 0 && idx < savedAddresses.length) {
      return savedAddresses[idx];
    }
    return savedAddresses.first;
  }

  bool _hasCheckedLocationPrompt = false;

  /// Checks if user is physically distant from their selected default delivery address.
  /// If distant (> 2.5 km), politely prompts whether they want to deliver to their current location instead.
  Future<void> checkLocationMismatchAndPrompt() async {
    if (_hasCheckedLocationPrompt) return;
    if (savedAddresses.isEmpty) return;

    final defaultAddr = selectedAddress;
    if (defaultAddr == null) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      double? targetLat = double.tryParse(defaultAddr['lat'] ?? '');
      double? targetLng = double.tryParse(defaultAddr['lng'] ?? '');

      if (targetLat == null || targetLng == null) {
        // Fallback: If address does not have lat/lng saved yet, try to geocode default address
        try {
          final results = await GoogleMapsService.searchAddress(defaultAddr['address'] ?? '');
          if (results.isNotEmpty) {
            targetLat = results[0]['lat'] as double?;
            targetLng = results[0]['lon'] as double?;
          }
        } catch (_) {}
      }

      if (targetLat == null || targetLng == null) return;

      // Distance in meters
      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      // If more than 2.5 km away from default address, prompt the user
      if (distanceInMeters > 2500) {
        _hasCheckedLocationPrompt = true;

        // Reverse geocode user's current GPS location
        String detectedArea = 'Your current location';
        try {
          final details = await GoogleMapsService.reverseGeocode(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          if (details != null && details.formattedAddress.isNotEmpty) {
            detectedArea = details.formattedAddress;
          }
        } catch (_) {}

        if (Get.context != null) {
          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25258F).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Color(0xFF25258F), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Different Location Detected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF25258F),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'You appear to be away from your default address.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text('Default Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22, top: 2),
                          child: Text(
                            defaultAddr['address'] ?? defaultAddr['label'] ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.navigation_rounded, size: 16, color: Color(0xFF25258F)),
                            const SizedBox(width: 6),
                            const Text('Current Location:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF25258F))),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22, top: 2),
                          child: Text(
                            detectedArea,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1B1B3A), fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Keep Default', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            addAddress('Current Location', detectedArea, lat: position.latitude, lng: position.longitude);
                            Get.snackbar(
                              'Delivery Location Updated',
                              'Delivering to: $detectedArea',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.green.shade50,
                              colorText: Colors.green.shade800,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25258F),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Deliver Here', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isScrollControlled: true,
          );
        }
      }
    } catch (_) {}
  }
}


import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
      _saveToStorage();
    } else if (index == 0) {
      selectedAddressIndex.value = 0;
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
}


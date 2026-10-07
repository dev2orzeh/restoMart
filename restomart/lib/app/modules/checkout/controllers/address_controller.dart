import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

        savedAddresses.value = loaded;
        if (selectedAddressIndex.value >= loaded.length) {
          selectedAddressIndex.value = 0;
        }
      } catch (e) {
        savedAddresses.clear();
      }
    } else {
      savedAddresses.clear();
      selectedAddressIndex.value = 0;
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey();
    await prefs.setString(key, jsonEncode(savedAddresses));
  }

  void addAddress(String label, String address) {
    savedAddresses.add({'label': label, 'address': address});
    selectedAddressIndex.value = savedAddresses.length - 1;
    _saveToStorage();
  }

  void selectAddress(int index) {
    if (index >= 0 && index < savedAddresses.length) {
      selectedAddressIndex.value = index;
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


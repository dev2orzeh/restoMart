import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddressController extends GetxController {
  final savedAddresses = <Map<String, String>>[].obs;
  final selectedAddressIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? addressesJson = prefs.getString('saved_addresses');
    
    if (addressesJson != null) {
      final List<dynamic> decoded = jsonDecode(addressesJson);
      savedAddresses.value = decoded.map((e) => Map<String, String>.from(e)).toList();
    } else {
      // Default mock data
      savedAddresses.value = [
        {'label': 'Karachi Kitchen - Main', 'address': 'DHA Phase 6, Main Boulevard, Lahore'},
        {'label': 'Karachi Kitchen - Branch', 'address': 'Gulberg III, Near Hafeez Center, Lahore'},
      ];
      _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_addresses', jsonEncode(savedAddresses));
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

  Map<String, String>? get selectedAddress {
    if (savedAddresses.isEmpty) return null;
    return savedAddresses[selectedAddressIndex.value];
  }
}

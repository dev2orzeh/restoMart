import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationPickerView extends StatefulWidget {
  const LocationPickerView({Key? key}) : super(key: key);

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  final Completer<GoogleMapController> _controller = Completer();

  // Default to Lahore, Pakistan
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(31.5204, 74.3587),
    zoom: 14.4746,
  );

  LatLng _centerPosition = const LatLng(31.5204, 74.3587);
  String _currentAddress = 'Lahore, Pakistan';
  bool _isMoving = false;

  String _addressType = 'HOME';
  bool _saveAddress = true;
  
  final TextEditingController _manualAddressController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  @override
  void dispose() {
    _manualAddressController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _manualAddressController.text = _currentAddress;
    _determinePosition();
  }

  // Get current location
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Geolocator error: $e');
    }
  }

  // Convert Coordinates to Address Text safely
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<geo.Placemark> placemarks = await geo.Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        final parts = [place.street, place.subLocality, place.locality]
            .where((p) => p != null && p.isNotEmpty)
            .join(', ');
        
        if (parts.isNotEmpty) {
          setState(() {
            _currentAddress = parts;
            if (_manualAddressController.text.isEmpty || _manualAddressController.text == 'Lahore, Pakistan') {
              _manualAddressController.text = parts;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error (likely no API key): $e');
    }
  }

  void _confirmAndReturnAddress() {
    final manualAddr = _manualAddressController.text.trim();
    final house = _houseController.text.trim();
    final street = _streetController.text.trim();
    final area = _areaController.text.trim();

    List<String> parts = [];
    if (house.isNotEmpty) parts.add('House/Office #$house');
    if (street.isNotEmpty) parts.add(street);
    if (area.isNotEmpty) parts.add(area);
    if (manualAddr.isNotEmpty && manualAddr != 'Searching address...') {
      parts.add(manualAddr);
    }

    if (parts.isEmpty) {
      Get.snackbar(
        'Address Required',
        'Please enter your delivery address in the text box below.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final fullAddress = parts.join(', ');

    Get.back(
      result: {
        'address': fullAddress,
        'lat': _centerPosition.latitude,
        'lng': _centerPosition.longitude,
        'label': _addressType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Delivery Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Google Map with fallback if unavailable
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _centerPosition = position.target;
                _isMoving = true;
              });
            },
            onCameraIdle: () {
              setState(() {
                _isMoving = false;
              });
              _getAddressFromLatLng(_centerPosition);
            },
          ),

          // Center Marker (The Pin)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _isMoving ? -15 : 0, 0),
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Color(0xFF25258F),
                ),
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // Bottom Address Card
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Delivery Address Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25258F),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Manual Address Input Field (Primary Address Box)
                    TextField(
                      controller: _manualAddressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Complete Address / Area / Street *',
                        hintText: 'e.g. DHA Phase 6, Main Boulevard, Lahore',
                        prefixIcon: const Icon(Icons.edit_location_alt, color: Color(0xFF25258F)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF25258F), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address Type Selectors: HOME / OFFICE / OTHER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['HOME', 'OFFICE', 'OTHER'].map((type) {
                        final isSelected = _addressType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _addressType = type),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? const Color(0xFF25258F) : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(type, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Optional details fields
                    _buildTextField(_houseController, 'House / Flat / Office Number (Optional)'),
                    const SizedBox(height: 10),
                    _buildTextField(_streetController, 'Building / Street / Floor Name (Optional)'),
                    const SizedBox(height: 10),
                    _buildTextField(_areaController, 'Nearest Landmark (Optional)'),
                    const SizedBox(height: 20),

                    // Confirm Location Button (ALWAYS ENABLED)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25258F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _confirmAndReturnAddress,
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF25258F)),
        ),
      ),
    );
  }
}

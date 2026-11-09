import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/utils/error_handler.dart';

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
  String _currentAddress = 'Detecting location...';
  bool _isMoving = false;

  String _addressType = 'HOME';
  
  final TextEditingController _manualAddressController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isSheetExpanded = false;

  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _manualAddressController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (_sheetController.isAttached) {
      if (_sheetController.size > 0.3) {
        _sheetController.animateTo(
          0.15,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _sheetController.animateTo(
          0.72,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await GoogleMapsService.searchAddress(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> item) async {
    final lat = item['lat'] as double?;
    final lon = item['lon'] as double?;
    final name = (item['display_name'] as String?) ?? '';

    if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
      final newPos = LatLng(lat, lon);
      setState(() {
        _centerPosition = newPos;
        _currentAddress = name;
        _manualAddressController.text = name;
        _searchResults = [];
        _searchController.clear();
      });

      FocusScope.of(context).unfocus();

      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPos, zoom: 16.0),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _manualAddressController.text = _currentAddress;
    _determinePosition();
    _sheetController.addListener(() {
      if (_sheetController.isAttached) {
        final expanded = _sheetController.size > 0.35;
        if (expanded != _isSheetExpanded) {
          setState(() {
            _isSheetExpanded = expanded;
          });
        }
      }
    });
  }

  // Get current location and reverse geocode via OpenStreetMap
  Future<void> _determinePosition() async {
    try {
      setState(() {
        _manualAddressController.text = 'Detecting current location...';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _manualAddressController.text = _currentAddress;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _manualAddressController.text = _currentAddress;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _manualAddressController.text = _currentAddress;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _centerPosition = currentLatLng;
      });

      // Reverse geocode immediately with OpenStreetMap
      await _getAddressFromLatLng(currentLatLng);

      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLatLng,
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Geolocator error: $e');
      if (mounted) {
        setState(() {
          _manualAddressController.text = _currentAddress;
        });
      }
    }
  }

  // Convert Coordinates to Accurate Address using Google Maps Geocoding API (with fallbacks)
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      // 1. Google Maps Geocoding API with valid API Key
      final details = await GoogleMapsService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (details != null && details.formattedAddress.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _currentAddress = details.formattedAddress;
          _manualAddressController.text = details.formattedAddress;
          
          if (details.houseNumber.isNotEmpty && _houseController.text.isEmpty) {
            _houseController.text = details.houseNumber;
          }
          if (details.street.isNotEmpty && _streetController.text.isEmpty) {
            _streetController.text = details.street;
          }
          // Only populate landmark if real landmark data exists from reverse geocoding
          if (details.landmark.isNotEmpty && _landmarkController.text.isEmpty) {
            _landmarkController.text = details.landmark;
          }
        });
        return;
      }

      // 2. Fallback to standard platform geocoding
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
          if (!mounted) return;
          setState(() {
            _currentAddress = parts;
            if (_manualAddressController.text.isEmpty || _manualAddressController.text == 'Lahore, Pakistan') {
              _manualAddressController.text = parts;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  void _confirmAndReturnAddress() {
    final manualAddr = _manualAddressController.text.trim();
    final house = _houseController.text.trim();
    final street = _streetController.text.trim();
    final landmark = _landmarkController.text.trim();

    List<String> parts = [];
    if (house.isNotEmpty) parts.add('House/Office #$house');
    if (street.isNotEmpty) parts.add(street);
    if (landmark.isNotEmpty) parts.add('Near $landmark');
    if (manualAddr.isNotEmpty && manualAddr != 'Searching address...') {
      parts.add(manualAddr);
    }

    if (parts.isEmpty) {
      AppErrorHandler.showWarning(
        'Address Required',
        'Please enter your delivery address in the text box below.',
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
          // Google Map with bottom padding so center is clear of bottom sheet
          GoogleMap(
            padding: const EdgeInsets.only(bottom: 110),
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

          // Center Marker (The Pin) - Elevated and never blocked by bottom sheet
          Positioned(
            top: 0,
            bottom: 110,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 35.0),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Ground pin shadow
                      Positioned(
                        bottom: -4,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isMoving ? 10 : 16,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(_isMoving ? 0.15 : 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Floating Pin Icon with delivery badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.translationValues(0, _isMoving ? -15 : 0, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25258F),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Deliver Here',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.location_on,
                              size: 42,
                              color: Color(0xFF25258F),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top Search Bar & Suggestions
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search area, street, landmark...',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF25258F)),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25258F)),
                              ),
                            )
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final displayName = item['display_name'] ?? '';
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, color: Color(0xFF25258F), size: 18),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Current Location Button (positioned neatly below search bar)
          Positioned(
            right: 16,
            top: 76,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Color(0xFF25258F)),
            ),
          ),

          // Draggable Bottom Sheet (Swipe down to view map freely, swipe up for details)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.14,
            maxChildSize: 0.75,
            snap: true,
            snapSizes: const [0.14, 0.28, 0.75],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Drag Handle Bar (Swipe down / up)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleSheet,
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(top: 4, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    // Header with title and expand/collapse arrow
                    GestureDetector(
                      onTap: _toggleSheet,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Address Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25258F),
                            ),
                          ),
                          Icon(
                            _isSheetExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: const Color(0xFF25258F),
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

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
                    const SizedBox(height: 14),

                    // Quick Confirm Button (Visible in Collapsed Mode)
                    if (!_isSheetExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

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
                    const SizedBox(height: 14),

                    // Optional details fields
                    _buildTextField(_houseController, 'House / Flat / Office Number (Optional)'),
                    const SizedBox(height: 10),
                    _buildTextField(_streetController, 'Building / Street / Floor Name (Optional)'),
                    const SizedBox(height: 10),
                    _buildTextField(_landmarkController, 'Nearest Landmark (Optional)'),
                    const SizedBox(height: 20),

                    // Confirm Location Button (Full View)
                    if (_isSheetExpanded)
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
              );
            },
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

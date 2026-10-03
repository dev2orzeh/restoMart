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
  String _currentAddress = 'Searching address...';
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Get current location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
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
  }

  // Convert Coordinates to Address Text
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<geo.Placemark> placemarks = await geo.Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Address not found. Please move the pin.';
      });
    }
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
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
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
            bottom: 180,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // Bottom Address Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF25258F),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isMoving ? 'Moving...' : _currentAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25258F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isMoving
                          ? null
                          : () {
                              Get.back(
                                result: {
                                  'address': _currentAddress,
                                  'lat': _centerPosition.latitude,
                                  'lng': _centerPosition.longitude,
                                },
                              );
                            },
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
        ],
      ),
    );
  }
}

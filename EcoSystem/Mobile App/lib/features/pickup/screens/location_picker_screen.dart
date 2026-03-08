import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(30.0347, 31.4295); // Default New Cairo
  bool _isLoading = true;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted && position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 16),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _selectedLocation = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 50,
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          // Confirm Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedLocation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

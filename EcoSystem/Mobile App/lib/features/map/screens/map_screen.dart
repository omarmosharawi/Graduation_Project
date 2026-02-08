// =============================================================================
// MAP SCREEN - Kiosk Locator
// =============================================================================
// Interactive map displaying nearby REward recycling kiosks.
//
// Features:
// - Google Maps integration
// - Current location display
// - Real-time kiosk status from Firestore
// - Kiosk info bottom sheet
// - Distance calculation
// =============================================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/kiosk_service.dart';
import '../../../core/services/location_service.dart';

/// MapScreen displays nearby kiosk locations with real-time status
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map controller
  GoogleMapController? _mapController;
  
  // Selected kiosk for bottom sheet
  Kiosk? _selectedKiosk;
  
  // Services
  final KioskService _kioskService = KioskService();
  final LocationService _locationService = LocationService();
  
  // User's current position
  Position? _userPosition;

  // Initial position (New Cairo - CIC College area)
  static const LatLng _initialPosition = LatLng(30.0347, 31.4295);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (mounted && position != null) {
      setState(() => _userPosition = position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find RVM'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToMyLocation,
          ),
        ],
      ),
      body: StreamBuilder<List<Kiosk>>(
        stream: _kioskService.getKiosksStream(),
        builder: (context, snapshot) {
          // Default to empty list while loading
          final kiosks = snapshot.data ?? [];
          
          // Build markers from kiosks
          final markers = _buildMarkers(kiosks);

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _initialPosition,
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              
              // Loading indicator
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),

              // Kiosk List Panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildKioskListPanel(kiosks),
              ),
              
              // Selected Kiosk Bottom Sheet
              if (_selectedKiosk != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 180,
                  child: _buildKioskInfoCard(_selectedKiosk!),
                ),
            ],
          );
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(List<Kiosk> kiosks) {
    return kiosks.map((kiosk) {
      return Marker(
        markerId: MarkerId(kiosk.id),
        position: LatLng(kiosk.latitude, kiosk.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          kiosk.isOperational 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueOrange,
        ),
        onTap: () {
          setState(() => _selectedKiosk = kiosk);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(kiosk.latitude, kiosk.longitude)),
          );
        },
      );
    }).toSet();
  }

  Widget _buildKioskListPanel(List<Kiosk> kiosks) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Nearby RVMs (${kiosks.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Horizontal list
          Expanded(
            child: kiosks.isEmpty
                ? const Center(child: Text('No kiosks found'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: kiosks.length,
                    itemBuilder: (context, index) {
                      final kiosk = kiosks[index];
                      return _buildKioskListItem(kiosk);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskListItem(Kiosk kiosk) {
    final bool isSelected = _selectedKiosk?.id == kiosk.id;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedKiosk = kiosk);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(kiosk.latitude, kiosk.longitude),
            15,
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kiosk.isOperational ? AppColors.success : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  kiosk.statusDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    color: kiosk.isOperational ? AppColors.success : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              kiosk.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKioskInfoCard(Kiosk kiosk) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kiosk.isOperational ? AppColors.success : AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kiosk.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: kiosk.isOperational ? AppColors.success : AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedKiosk = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            kiosk.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Address
          Text(
            kiosk.address,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _buildInfoChip(Icons.schedule, kiosk.openingHours),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.recycling, '${kiosk.plasticCount + kiosk.metalCount} recycled'),
            ],
          ),
          const SizedBox(height: 12),
          // Navigate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: kiosk.isOperational ? () {
                // Would open maps app for navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening navigation...')),
                );
              } : null,
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _goToMyLocation() {
    // In a real app, would use geolocator to get current location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_initialPosition, 14),
    );
  }
}

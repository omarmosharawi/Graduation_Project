// =============================================================================
// MAP SCREEN - Kiosk Locator
// =============================================================================
// Interactive map displaying nearby REward recycling kiosks.
//
// Features:
// - Google Maps integration
// - Current location display
// - Real-time kiosk status from Firestore (available, full, maintenance, offline, out_of_service)
// - Color-coded markers with status legend
// - Kiosk info bottom sheet with capacity progress bar
// - Distance calculation
// =============================================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
      
      // Auto-center map on user
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
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
                onTap: (_) {
                  setState(() => _selectedKiosk = null);
                },
              ),
              
              // Loading indicator
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),

              // Status Legend
              Positioned(
                top: 12,
                left: 12,
                child: _buildStatusLegend(),
              ),

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

  // ---------------------------------------------------------------------------
  // Status Legend
  // ---------------------------------------------------------------------------
  Widget _buildStatusLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendDot(const Color(0xFF4CAF50), 'Online'),
          const SizedBox(width: 10),
          _legendDot(const Color(0xFFFFC107), 'Full'),
          const SizedBox(width: 10),
          _legendDot(const Color(0xFFFF9800), 'Maintenance'),
          const SizedBox(width: 10),
          _legendDot(const Color(0xFFF44336), 'Offline'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Map Markers
  // ---------------------------------------------------------------------------
  Set<Marker> _buildMarkers(List<Kiosk> kiosks) {
    return kiosks.map((kiosk) {
      return Marker(
        markerId: MarkerId(kiosk.id),
        position: LatLng(kiosk.latitude, kiosk.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(kiosk.status),
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

  double _getMarkerHue(String status) {
    switch (status) {
      case 'available':
        return BitmapDescriptor.hueGreen;
      case 'full':
        return BitmapDescriptor.hueYellow;
      case 'maintenance':
        return BitmapDescriptor.hueOrange;
      case 'offline':
      case 'out_of_service':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  // ---------------------------------------------------------------------------
  // Kiosk List Panel
  // ---------------------------------------------------------------------------
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
        width: 150,
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
                    color: kiosk.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kiosk.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      color: kiosk.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              kiosk.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Mini capacity bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: kiosk.capacityPercent,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  kiosk.capacityPercent > 0.9
                      ? const Color(0xFFF44336)
                      : kiosk.capacityPercent > 0.7
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(kiosk.capacityPercent * 100).toInt()}% full',
              style: TextStyle(fontSize: 9, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kiosk Info Card
  // ---------------------------------------------------------------------------
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
          // Header: status + close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kiosk.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kiosk.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: kiosk.statusColor,
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
          // Capacity progress bar
          Row(
            children: [
              const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: kiosk.capacityPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      kiosk.capacityPercent > 0.9
                          ? const Color(0xFFF44336)
                          : kiosk.capacityPercent > 0.7
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${kiosk.currentCapacity}/${kiosk.maxCapacity}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
              onPressed: kiosk.isOperational ? () => _openNavigation(kiosk) : null,
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

  Future<void> _openNavigation(Kiosk kiosk) async {
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${kiosk.latitude},${kiosk.longitude}';
    final String appleMapsUrl = 'https://maps.apple.com/?daddr=${kiosk.latitude},${kiosk.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
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
    if (_userPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          14,
        ),
      );
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 14),
      );
    }
  }
}

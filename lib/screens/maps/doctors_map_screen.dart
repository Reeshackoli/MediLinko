import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_provider.dart';
import '../../widgets/map/doctor_info_card.dart';
import '../../widgets/map/map_search_bar.dart';
import '../../widgets/map/specialty_filter_chips.dart';

class DoctorsMapScreen extends ConsumerStatefulWidget {
  const DoctorsMapScreen({super.key});

  @override
  ConsumerState<DoctorsMapScreen> createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends ConsumerState<DoctorsMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Load all doctors first (so they all show on map)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapProvider.notifier).fetchAllDoctors();
      // Load location without auto-fetching nearby (to avoid filtering)
      ref.read(mapProvider.notifier).loadCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    final currentLocation = ref.read(currentLocationProvider);
    if (currentLocation != null) {
      _mapController.move(
        LatLng(currentLocation.latitude, currentLocation.longitude),
        14.0,
      );
    }
  }

  List<Marker> _buildMarkers() {
    final doctors = ref.watch(filteredDoctorsProvider);
    final selectedDoctor = ref.watch(selectedDoctorProvider);

    return doctors.map((doctor) {
      final isSelected = selectedDoctor?.id == doctor.id;
      
      return Marker(
        point: LatLng(doctor.latitude, doctor.longitude),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () {
            ref.read(mapProvider.notifier).selectDoctor(doctor);
            
            // Animate map to center on selected doctor
            _mapController.move(
              LatLng(doctor.latitude, doctor.longitude),
              15.0,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
                // Marker shadow
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: isSelected ? 25 : 20,
                    width: isSelected ? 25 : 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Marker icon
                Icon(
                  Icons.location_on,
                  color: isSelected
                      ? const Color(0xFF4C9AFF)
                      : const Color(0xFF5FD4C4),
                  size: isSelected ? 50 : 40,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Marker? _buildCurrentLocationMarker() {
    final currentLocation = ref.watch(currentLocationProvider);
    
    if (currentLocation == null) return null;

    return Marker(
      point: LatLng(currentLocation.latitude, currentLocation.longitude),
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4C9AFF).withOpacity(0.3),
          border: Border.all(
            color: const Color(0xFF4C9AFF),
            width: 3,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.my_location,
            color: Color(0xFF4C9AFF),
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final currentLocation = mapState.currentLocation;
    
    // Default center (Belgaum, Karnataka - where our sample doctors are)
    // Coordinates: 15.8497, 74.4977
    final initialCenter = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : const LatLng(15.8497, 74.4977); // Belgaum center

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors Near You'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          if (mapState.filteredDoctors.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C9AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4C9AFF).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 16,
                      color: Color(0xFF4C9AFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${mapState.filteredDoctors.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4C9AFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: (_, __) {
                // Clear selection when tapping map
                ref.read(mapProvider.notifier).clearSelection();
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medilinko.app',
                tileProvider: NetworkTileProvider(),
              ),
              
              // Doctor markers
              MarkerLayer(
                markers: [
                  ..._buildMarkers(),
                  if (_buildCurrentLocationMarker() != null)
                    _buildCurrentLocationMarker()!,
                ],
              ),
            ],
          ),

          // Search bar at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: MapSearchBar(),
          ),

          // Filter chips below search
          Positioned(
            top: 76,
            left: 0,
            right: 0,
            child: SpecialtyFilterChips(),
          ),

          // Loading indicator
          if (mapState.isLoading || mapState.isLoadingLocation)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C9AFF)),
                ),
              ),
            ),

          // Error message
          if (mapState.errorMessage != null && !mapState.isLoading)
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mapState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Doctor info card at bottom
          if (mapState.selectedDoctor != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DoctorInfoCard(doctor: mapState.selectedDoctor!),
            ),

          // Recenter button
          Positioned(
            bottom: mapState.selectedDoctor != null ? 220 : 100,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.15),
              child: FloatingActionButton(
                heroTag: 'recenterMapFab',
                onPressed: _recenterMap,
                backgroundColor: Colors.white,
                elevation: 0,
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF4C9AFF),
                  size: 26,
                ),
              ),
            ),
          ),

          // Refresh doctors button
          Positioned(
            bottom: mapState.selectedDoctor != null ? 220 : 32,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.15),
              child: FloatingActionButton(
                heroTag: 'refreshDoctorsFab',
                onPressed: () async {
                  await ref.read(mapProvider.notifier).fetchAllDoctors();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Found ${mapState.filteredDoctors.length} doctors'),
                        backgroundColor: const Color(0xFF4C9AFF),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                backgroundColor: const Color(0xFF4C9AFF),
                elevation: 0,
                child: mapState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

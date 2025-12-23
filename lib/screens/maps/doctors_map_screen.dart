import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_provider.dart';
import '../../widgets/map/doctor_info_card.dart';
import '../../widgets/map/map_search_bar.dart';
import '../../widgets/map/specialty_filter_chips.dart';
import '../../core/theme/app_theme.dart';
import 'doctors_list_view.dart';

class DoctorsMapScreen extends ConsumerStatefulWidget {
  const DoctorsMapScreen({super.key});

  @override
  ConsumerState<DoctorsMapScreen> createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends ConsumerState<DoctorsMapScreen> {
  late final MapController _mapController;
  bool _isListView = false; // Toggle between map and list view

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
    
    // Default center (Belgaum, Karnataka)
    final initialCenter = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : const LatLng(15.8497, 74.4977);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isListView ? 'Doctors List' : 'Find Doctors'),
        backgroundColor: const Color(0xFF4C9AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // View toggle button - Prominent
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _isListView = !_isListView;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isListView ? Icons.map_outlined : Icons.list_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isListView ? 'Map' : 'List',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (mapState.filteredDoctors.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medical_services, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${mapState.filteredDoctors.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isListView ? _buildListView() : _buildMapView(context, mapState, currentLocation, initialCenter),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: MapSearchBar(),
        ),
        // Specialty filters
        SpecialtyFilterChips(),
        // List view
        const Expanded(
          child: DoctorsListView(),
        ),
      ],
    );
  }

  Widget _buildMapView(BuildContext context, dynamic mapState, dynamic currentLocation, LatLng initialCenter) {
    return Stack(
      children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: (_, __) => ref.read(mapProvider.notifier).clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medilinko.app',
              ),
              MarkerLayer(
                markers: [
                  ..._buildMarkers(),
                  if (_buildCurrentLocationMarker() != null)
                    _buildCurrentLocationMarker()!,
                ],
              ),
            ],
          ),

          // Simple search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: MapSearchBar(),
          ),

          // Specialty filters
          Positioned(
            top: 68,
            left: 0,
            right: 0,
            child: SpecialtyFilterChips(),
          ),

          // Loading
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
              top: 130,
              left: 12,
              right: 12,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mapState.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Doctor info card
          if (mapState.selectedDoctor != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DoctorInfoCard(doctor: mapState.selectedDoctor!),
            ),

          // Floating action buttons - simplified
          Positioned(
            bottom: mapState.selectedDoctor != null ? 200 : 24,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter button
                FloatingActionButton(
                  heroTag: 'recenterMap',
                  onPressed: _recenterMap,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Color(0xFF4C9AFF)),
                ),
                const SizedBox(height: 12),
                // Refresh button
                FloatingActionButton(
                  heroTag: 'refreshDoctors',
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
                  child: mapState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      );
    }
}

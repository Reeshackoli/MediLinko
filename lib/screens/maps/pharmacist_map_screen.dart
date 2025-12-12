import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:medilinko/providers/pharmacist_map_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmaciesMapScreen extends ConsumerStatefulWidget {
  const PharmaciesMapScreen({super.key});

  @override
  ConsumerState<PharmaciesMapScreen> createState() => _PharmaciesMapScreenState();
}

class _PharmaciesMapScreenState extends ConsumerState<PharmaciesMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    print('🗺️ Pharmacy Map Screen Initialized');
    
    // Load all pharmacies first (so they all show on map)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('📍 Loading pharmacies...');
      await ref.read(pharmacyMapProvider.notifier).fetchAllPharmacies();
      
      print('📍 Loading user location...');
      await ref.read(pharmacyMapProvider.notifier).loadCurrentLocation();
      
      // Print state after loading
      final state = ref.read(pharmacyMapProvider);
      print('✅ Pharmacies loaded: ${state.allPharmacies.length}');
      print('✅ Filtered pharmacies: ${state.filteredPharmacies.length}');
      print('✅ Current location: ${state.currentLocation}');
      print('✅ Error: ${state.errorMessage}');
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    final currentLocation = ref.read(currentPharmacyLocationProvider);
    if (currentLocation != null) {
      _mapController.move(
        LatLng(currentLocation.latitude, currentLocation.longitude),
        14.0,
      );
    } else {
      print('⚠️ No current location available');
    }
  }

  List<Marker> _buildMarkers() {
    final pharmacies = ref.watch(filteredPharmaciesProvider);
    final selectedPharmacy = ref.watch(selectedPharmacyProvider);

    print('🎯 Building ${pharmacies.length} pharmacy markers');

    return pharmacies.map((pharmacy) {
      print('📍 Marker for ${pharmacy.storeName}: ${pharmacy.latitude}, ${pharmacy.longitude}');
      
      final isSelected = selectedPharmacy?.id == pharmacy.id;
      
      return Marker(
        point: LatLng(pharmacy.latitude, pharmacy.longitude),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () {
            print('🎯 Pharmacy tapped: ${pharmacy.storeName}');
            ref.read(pharmacyMapProvider.notifier).selectPharmacy(pharmacy);
            
            // Animate map to center on selected pharmacy
            _mapController.move(
              LatLng(pharmacy.latitude, pharmacy.longitude),
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
                // Marker icon - using pharmacy icon
                Icon(
                  Icons.local_pharmacy,
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
    final currentLocation = ref.watch(currentPharmacyLocationProvider);
    
    if (currentLocation == null) {
      print('⚠️ No current location for marker');
      return null;
    }

    print('📍 Current location marker: ${currentLocation.latitude}, ${currentLocation.longitude}');

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
    final mapState = ref.watch(pharmacyMapProvider);
    final currentLocation = mapState.currentLocation;
    
    print('🗺️ Building map - Pharmacies: ${mapState.filteredPharmacies.length}, Loading: ${mapState.isLoading}');
    
    // Default center (Belgaum, Karnataka)
    final initialCenter = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : const LatLng(15.8497, 74.4977); // Belgaum center

    print('🗺️ Map center: ${initialCenter.latitude}, ${initialCenter.longitude}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Pharmacies Near You'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          if (mapState.filteredPharmacies.isNotEmpty)
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
                      Icons.local_pharmacy,
                      size: 16,
                      color: Color(0xFF4C9AFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${mapState.filteredPharmacies.length}',
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
                ref.read(pharmacyMapProvider.notifier).clearSelection();
              },
              onMapReady: () {
                print('🗺️ Map is ready!');
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medilinko.app',
                tileProvider: NetworkTileProvider(),
              ),
              
              // Pharmacy markers
              MarkerLayer(
                markers: [
                  ..._buildMarkers(),
                  if (_buildCurrentLocationMarker() != null)
                    _buildCurrentLocationMarker()!,
                ],
              ),
            ],
          ),

          // Search bar at top (pharmacy name search only)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by pharmacy name...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4C9AFF)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => ref.read(pharmacyMapProvider.notifier).updateSearchQuery(value),
              ),
            ),
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
              top: 76,
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
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          // Clear error - you might need to add this method to provider
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Pharmacy info card at bottom (simple inline fallback)
          if (mapState.selectedPharmacy != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mapState.selectedPharmacy!.storeName.isNotEmpty
                          ? mapState.selectedPharmacy!.storeName
                          : 'Shop name not provided',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (mapState.selectedPharmacy!.address != null)
                      Text(mapState.selectedPharmacy!.address!),
                    const SizedBox(height: 12),
                    if (mapState.selectedPharmacy!.phone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(mapState.selectedPharmacy!.phone!),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final lat = mapState.selectedPharmacy!.latitude;
                              final lng = mapState.selectedPharmacy!.longitude;
                              final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                              await launchUrl(uri);
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (mapState.selectedPharmacy!.phone != null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final phone = mapState.selectedPharmacy!.phone!;
                              final uri = Uri(scheme: 'tel', path: phone);
                              try {
                                await launchUrl(uri);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open dialer')));
                              }
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Recenter button
          Positioned(
            bottom: mapState.selectedPharmacy != null ? 220 : 100,
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

          // Refresh pharmacies button
          Positioned(
            bottom: mapState.selectedPharmacy != null ? 150 : 32,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.15),
              child: FloatingActionButton(
                heroTag: 'refreshPharmaciesFab',
                onPressed: () async {
                  print('🔄 Refreshing pharmacies...');
                  await ref.read(pharmacyMapProvider.notifier).fetchAllPharmacies();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Found ${mapState.filteredPharmacies.length} pharmacies'),
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

          // Debug info (Remove after debugging)
          if (mapState.filteredPharmacies.isEmpty && !mapState.isLoading)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'No pharmacies found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${mapState.errorMessage ?? "No error"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All: ${mapState.allPharmacies.length}, Filtered: ${mapState.filteredPharmacies.length}',
                        style: const TextStyle(fontSize: 12),
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
}
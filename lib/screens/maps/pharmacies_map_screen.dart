import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/pharmacy_map_provider.dart';
import '../../widgets/map/pharmacy_info_card.dart';
import 'pharmacies_list_view.dart';

class PharmaciesMapScreen extends ConsumerStatefulWidget {
  const PharmaciesMapScreen({super.key});

  @override
  ConsumerState<PharmaciesMapScreen> createState() => _PharmaciesMapScreenState();
}

class _PharmaciesMapScreenState extends ConsumerState<PharmaciesMapScreen> {
  late final MapController _mapController;
  bool _isListView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Load all pharmacies first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pharmacyMapProvider.notifier).fetchAllPharmacies();
      ref.read(pharmacyMapProvider.notifier).loadCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    final currentLocation = ref.read(pharmacyCurrentLocationProvider);
    if (currentLocation != null) {
      _mapController.move(
        LatLng(currentLocation.latitude, currentLocation.longitude),
        14.0,
      );
    }
  }

  List<Marker> _buildMarkers() {
    final pharmacies = ref.watch(filteredPharmaciesProvider);
    final selectedPharmacy = ref.watch(selectedPharmacyProvider);

    return pharmacies.map((pharmacy) {
      final isSelected = selectedPharmacy?.id == pharmacy.id;
      
      return Marker(
        point: LatLng(pharmacy.latitude, pharmacy.longitude),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () {
            ref.read(pharmacyMapProvider.notifier).selectPharmacy(pharmacy);
            
            _mapController.move(
              LatLng(pharmacy.latitude, pharmacy.longitude),
              15.0,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
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
                Icon(
                  Icons.local_pharmacy,
                  color: isSelected
                      ? const Color(0xFF10B981)
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
    final currentLocation = ref.watch(pharmacyCurrentLocationProvider);
    
    if (currentLocation == null) return null;

    return Marker(
      point: LatLng(currentLocation.latitude, currentLocation.longitude),
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981).withOpacity(0.3),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 3,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.my_location,
            color: Color(0xFF10B981),
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
    
    final initialCenter = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : const LatLng(15.8497, 74.4977);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF10B981).withOpacity(0.05),
              const Color(0xFF5FD4C4).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF5FD4C4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (mapState.filteredPharmacies.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_pharmacy, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${mapState.filteredPharmacies.length} Pharmacies',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isListView = !_isListView;
                          });
                        },
                        icon: Icon(
                          _isListView ? Icons.map_outlined : Icons.list_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isListView ? 'Pharmacies List' : 'Find Pharmacies',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find nearby pharmacies and medical stores',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isListView ? _buildListView() : _buildMapView(context, mapState, initialCenter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildSearchBar(),
        ),
        const Expanded(
          child: PharmaciesListView(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(pharmacyMapProvider.notifier).searchPharmacies(value);
        },
        decoration: InputDecoration(
          hintText: 'Search pharmacies...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(pharmacyMapProvider.notifier).searchPharmacies('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMapView(BuildContext context, dynamic mapState, LatLng initialCenter) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 13.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            onTap: (_, __) => ref.read(pharmacyMapProvider.notifier).clearSelection(),
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

        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _buildSearchBar(),
        ),

        if (mapState.isLoading || mapState.isLoadingLocation)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
          ),

        if (mapState.errorMessage != null && !mapState.isLoading)
          Positioned(
            top: 80,
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

        if (mapState.selectedPharmacy != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PharmacyInfoCard(pharmacy: mapState.selectedPharmacy!),
          ),

        Positioned(
          bottom: mapState.selectedPharmacy != null ? 200 : 24,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'recenterMap',
                onPressed: _recenterMap,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'refreshPharmacies',
                onPressed: () async {
                  await ref.read(pharmacyMapProvider.notifier).fetchAllPharmacies();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Found ${mapState.filteredPharmacies.length} pharmacies'),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                backgroundColor: const Color(0xFF10B981),
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

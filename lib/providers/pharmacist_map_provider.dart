import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacist_location_model.dart';
import '../services/location_service.dart';
import 'package:medilinko/core/network/api_service.dart';

/// Pharmacy Map state class
class PharmacyMapState {
  final Position? currentLocation;
  final List<PharmacyLocationModel> allPharmacies;
  final List<PharmacyLocationModel> filteredPharmacies;
  final PharmacyLocationModel? selectedPharmacy;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingLocation;
  final String? errorMessage;
  final double searchRadius; // in meters

  PharmacyMapState({
    this.currentLocation,
    this.allPharmacies = const [],
    this.filteredPharmacies = const [],
    this.selectedPharmacy,
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingLocation = false,
    this.errorMessage,
    this.searchRadius = 5000, // Default 5km
  });

  PharmacyMapState copyWith({
    Position? currentLocation,
    List<PharmacyLocationModel>? allPharmacies,
    List<PharmacyLocationModel>? filteredPharmacies,
    PharmacyLocationModel? selectedPharmacy,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingLocation,
    String? errorMessage,
    double? searchRadius,
    bool clearSelectedPharmacy = false,
    bool clearError = false,
  }) {
    return PharmacyMapState(
      currentLocation: currentLocation ?? this.currentLocation,
      allPharmacies: allPharmacies ?? this.allPharmacies,
      filteredPharmacies: filteredPharmacies ?? this.filteredPharmacies,
      selectedPharmacy: clearSelectedPharmacy ? null : (selectedPharmacy ?? this.selectedPharmacy),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchRadius: searchRadius ?? this.searchRadius,
    );
  }
}

/// Pharmacy Map notifier for state management
class PharmacyMapNotifier extends StateNotifier<PharmacyMapState> {
  PharmacyMapNotifier() : super(PharmacyMapState());

  /// Load current location
  Future<void> loadCurrentLocation() async {
    state = state.copyWith(isLoadingLocation: true, clearError: true);

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        state = state.copyWith(
          currentLocation: position,
          isLoadingLocation: false,
        );
        
        // Don't automatically fetch nearby - let the caller decide
        // This allows showing all pharmacies on map by default
      } else {
        state = state.copyWith(
          isLoadingLocation: false,
          errorMessage: 'Unable to get your location. Please enable location services.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingLocation: false,
        errorMessage: 'Error getting location: ${e.toString()}',
      );
    }
  }

  /// Fetch nearby pharmacies based on current location
  Future<void> fetchNearbyPharmacies({double? radius}) async {
    // If current location is available, delegate to coordinate-based fetch
    if (state.currentLocation != null) {
      await fetchNearbyPharmaciesAt(
        state.currentLocation!.latitude,
        state.currentLocation!.longitude,
        radius: radius,
      );
      return;
    }

    // Otherwise fetch all
    await fetchAllPharmacies();
  }

  /// Fetch nearby pharmacies for explicit coordinates (manual input)
  Future<void> fetchNearbyPharmaciesAt(double lat, double lng, {double? radius}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      searchRadius: radius ?? state.searchRadius,
    );

    try {
      final res = await ApiService.get('/users/pharmacies/nearby', queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': (radius ?? state.searchRadius).toString(),
      });

      if (res['success'] == true) {
        final pharmaciesData = res['data'] as List<dynamic>? ?? [];
        final pharmacies = pharmaciesData.map((j) => PharmacyLocationModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(
          allPharmacies: pharmacies,
          filteredPharmacies: pharmacies,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res['message'] ?? 'Failed to fetch nearby pharmacies',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching nearby pharmacies: ${e.toString()}',
      );
    }
    _applyFilters();
  }

  /// Fetch all pharmacies (when location not available)
  Future<void> fetchAllPharmacies() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.get('/users/pharmacies');
      if (res['success'] == true) {
        final pharmaciesData = res['data'] as List<dynamic>? ?? [];
        final pharmacies = pharmaciesData.map((j) => PharmacyLocationModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(
          allPharmacies: pharmacies,
          filteredPharmacies: pharmacies,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res['message'] ?? 'Failed to fetch pharmacies',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching pharmacies: ${e.toString()}',
      );
    }
    _applyFilters();
  }

  /// Select a pharmacy
  void selectPharmacy(PharmacyLocationModel pharmacy) {
    state = state.copyWith(selectedPharmacy: pharmacy);
  }

  /// Clear selected pharmacy
  void clearSelection() {
    state = state.copyWith(clearSelectedPharmacy: true);
  }

  /// Update search query and filter
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      filteredPharmacies: state.allPharmacies,
    );
  }

  /// Apply filters to pharmacy list (search by name only)
  void _applyFilters() {
    List<PharmacyLocationModel> filtered = List.from(state.allPharmacies);

    // Apply search query (pharmacy name only)
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((pharmacy) {
        return pharmacy.storeName.toLowerCase().contains(query);
      }).toList();
    }

    state = state.copyWith(filteredPharmacies: filtered);
  }

  /// Update search radius and refetch
  Future<void> updateSearchRadius(double radius) async {
    await fetchNearbyPharmacies(radius: radius);
  }
}

/// Pharmacy Map provider
final pharmacyMapProvider = StateNotifierProvider<PharmacyMapNotifier, PharmacyMapState>((ref) {
  return PharmacyMapNotifier();
});

/// Helper providers
final selectedPharmacyProvider = Provider<PharmacyLocationModel?>((ref) {
  return ref.watch(pharmacyMapProvider).selectedPharmacy;
});

final filteredPharmaciesProvider = Provider<List<PharmacyLocationModel>>((ref) {
  return ref.watch(pharmacyMapProvider).filteredPharmacies;
});

final isLoadingPharmacyProvider = Provider<bool>((ref) {
  return ref.watch(pharmacyMapProvider).isLoading;
});

final currentPharmacyLocationProvider = Provider<Position?>((ref) {
  return ref.watch(pharmacyMapProvider).currentLocation;
});

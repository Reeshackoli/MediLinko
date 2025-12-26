import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacy_location_model.dart';
import '../services/location_service.dart';
import '../services/pharmacy_map_service.dart';

class PharmacyMapState {
  final Position? currentLocation;
  final List<PharmacyLocationModel> allPharmacies;
  final List<PharmacyLocationModel> filteredPharmacies;
  final PharmacyLocationModel? selectedPharmacy;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingLocation;
  final String? errorMessage;
  final double searchRadius;

  PharmacyMapState({
    this.currentLocation,
    this.allPharmacies = const [],
    this.filteredPharmacies = const [],
    this.selectedPharmacy,
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingLocation = false,
    this.errorMessage,
    this.searchRadius = 5000,
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

class PharmacyMapNotifier extends StateNotifier<PharmacyMapState> {
  PharmacyMapNotifier() : super(PharmacyMapState());

  Future<void> loadCurrentLocation() async {
    state = state.copyWith(isLoadingLocation: true, clearError: true);

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        state = state.copyWith(
          currentLocation: position,
          isLoadingLocation: false,
        );
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

  Future<void> fetchAllPharmacies() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final pharmacies = await PharmacyMapService.fetchAllPharmacies();
      
      state = state.copyWith(
        allPharmacies: pharmacies,
        filteredPharmacies: pharmacies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchNearbyPharmacies({double? radius}) async {
    if (state.currentLocation == null) {
      await fetchAllPharmacies();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final searchRadius = radius ?? state.searchRadius;
      final pharmacies = await PharmacyMapService.fetchNearbyPharmacies(
        latitude: state.currentLocation!.latitude,
        longitude: state.currentLocation!.longitude,
        radius: searchRadius,
      );

      state = state.copyWith(
        allPharmacies: pharmacies,
        filteredPharmacies: _applyFilters(pharmacies),
        isLoading: false,
        searchRadius: searchRadius,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void searchPharmacies(String query) {
    state = state.copyWith(searchQuery: query);
    state = state.copyWith(filteredPharmacies: _applyFilters(state.allPharmacies));
  }

  List<PharmacyLocationModel> _applyFilters(List<PharmacyLocationModel> pharmacies) {
    var filtered = pharmacies;

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((pharmacy) {
        return pharmacy.storeName.toLowerCase().contains(query) ||
               (pharmacy.services?.any((s) => s.toLowerCase().contains(query)) ?? false);
      }).toList();
    }

    return filtered;
  }

  void selectPharmacy(PharmacyLocationModel pharmacy) {
    state = state.copyWith(selectedPharmacy: pharmacy);
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedPharmacy: true);
  }
}

final pharmacyMapProvider = StateNotifierProvider<PharmacyMapNotifier, PharmacyMapState>((ref) {
  return PharmacyMapNotifier();
});

final pharmacyCurrentLocationProvider = Provider<Position?>((ref) {
  return ref.watch(pharmacyMapProvider).currentLocation;
});

final filteredPharmaciesProvider = Provider<List<PharmacyLocationModel>>((ref) {
  return ref.watch(pharmacyMapProvider).filteredPharmacies;
});

final selectedPharmacyProvider = Provider<PharmacyLocationModel?>((ref) {
  return ref.watch(pharmacyMapProvider).selectedPharmacy;
});

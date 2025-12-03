import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/doctor_location_model.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';

/// Map state class
class MapState {
  final Position? currentLocation;
  final List<DoctorLocationModel> allDoctors;
  final List<DoctorLocationModel> filteredDoctors;
  final DoctorLocationModel? selectedDoctor;
  final List<String> activeFilters; // Specialization filters
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingLocation;
  final String? errorMessage;
  final double searchRadius; // in meters

  MapState({
    this.currentLocation,
    this.allDoctors = const [],
    this.filteredDoctors = const [],
    this.selectedDoctor,
    this.activeFilters = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingLocation = false,
    this.errorMessage,
    this.searchRadius = 5000, // Default 5km
  });

  MapState copyWith({
    Position? currentLocation,
    List<DoctorLocationModel>? allDoctors,
    List<DoctorLocationModel>? filteredDoctors,
    DoctorLocationModel? selectedDoctor,
    List<String>? activeFilters,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingLocation,
    String? errorMessage,
    double? searchRadius,
    bool clearSelectedDoctor = false,
    bool clearError = false,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      allDoctors: allDoctors ?? this.allDoctors,
      filteredDoctors: filteredDoctors ?? this.filteredDoctors,
      selectedDoctor: clearSelectedDoctor ? null : (selectedDoctor ?? this.selectedDoctor),
      activeFilters: activeFilters ?? this.activeFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchRadius: searchRadius ?? this.searchRadius,
    );
  }
}

/// Map notifier for state management
class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(MapState());

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
        // This allows showing all doctors on map by default
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

  /// Fetch nearby doctors based on current location
  Future<void> fetchNearbyDoctors({double? radius}) async {
    if (state.currentLocation == null) {
      // If no location, fetch all doctors
      await fetchAllDoctors();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      searchRadius: radius,
    );

    try {
      final result = await MapService.getNearbyDoctors(
        latitude: state.currentLocation!.latitude,
        longitude: state.currentLocation!.longitude,
        radius: radius ?? state.searchRadius,
      );

      if (result['success']) {
        final doctors = result['doctors'] as List<DoctorLocationModel>;
        state = state.copyWith(
          allDoctors: doctors,
          filteredDoctors: doctors,
          isLoading: false,
        );
        
        // Apply existing filters
        _applyFilters();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to fetch doctors',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching doctors: ${e.toString()}',
      );
    }
  }

  /// Fetch all doctors (when location not available)
  Future<void> fetchAllDoctors() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await MapService.getAllDoctors();

      if (result['success']) {
        final doctors = result['doctors'] as List<DoctorLocationModel>;
        state = state.copyWith(
          allDoctors: doctors,
          filteredDoctors: doctors,
          isLoading: false,
        );
        
        _applyFilters();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to fetch doctors',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching doctors: ${e.toString()}',
      );
    }
  }

  /// Select a doctor
  void selectDoctor(DoctorLocationModel doctor) {
    state = state.copyWith(selectedDoctor: doctor);
  }

  /// Clear selected doctor
  void clearSelection() {
    state = state.copyWith(clearSelectedDoctor: true);
  }

  /// Update search query and filter
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Toggle specialization filter
  void toggleFilter(String specialization) {
    final currentFilters = List<String>.from(state.activeFilters);
    
    if (currentFilters.contains(specialization)) {
      currentFilters.remove(specialization);
    } else {
      currentFilters.add(specialization);
    }

    state = state.copyWith(activeFilters: currentFilters);
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      activeFilters: [],
      searchQuery: '',
      filteredDoctors: state.allDoctors,
    );
  }

  /// Apply filters to doctor list
  void _applyFilters() {
    List<DoctorLocationModel> filtered = List.from(state.allDoctors);

    // Apply specialization filters
    if (state.activeFilters.isNotEmpty) {
      filtered = filtered.where((doctor) {
        return state.activeFilters.any((filter) =>
            doctor.specialization?.toLowerCase().contains(filter.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((doctor) {
        return doctor.fullName.toLowerCase().contains(query) ||
            (doctor.clinicName?.toLowerCase().contains(query) ?? false) ||
            (doctor.specialization?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(filteredDoctors: filtered);
  }

  /// Update search radius and refetch
  Future<void> updateSearchRadius(double radius) async {
    await fetchNearbyDoctors(radius: radius);
  }

  /// Get available specializations from current doctors
  List<String> getAvailableSpecializations() {
    final specializations = state.allDoctors
        .map((doctor) => doctor.specialization)
        .where((spec) => spec != null && spec.isNotEmpty)
        .toSet()
        .toList();
    
    specializations.sort();
    return specializations.cast<String>();
  }
}

/// Map provider
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});

/// Helper providers
final selectedDoctorProvider = Provider<DoctorLocationModel?>((ref) {
  return ref.watch(mapProvider).selectedDoctor;
});

final filteredDoctorsProvider = Provider<List<DoctorLocationModel>>((ref) {
  return ref.watch(mapProvider).filteredDoctors;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(mapProvider).isLoading;
});

final currentLocationProvider = Provider<Position?>((ref) {
  return ref.watch(mapProvider).currentLocation;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../trips/application/trips_controller.dart';
import '../../trips/domain/trip_models.dart';
import '../data/location_repository.dart';
import '../data/map_service_impl.dart';
import '../domain/location_models.dart';
import '../domain/map_service.dart';

final mapServiceProvider = Provider<MapService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasMapsKey) {
    return GoogleMapService(config.mapsApiKey);
  }
  return const MockMapService();
});

final locationRepositoryProvider = Provider<LocationRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return LocationRepository(client);
});

class TripTrackingState {
  const TripTrackingState({
    this.latest,
    this.route,
    this.consentGiven = false,
    this.isSharing = false,
    this.isLoading = false,
    this.error,
  });

  final LocationUpdate? latest;
  final RouteEstimate? route;
  final bool consentGiven;
  final bool isSharing;
  final bool isLoading;
  final String? error;

  TripTrackingState copyWith({
    LocationUpdate? latest,
    RouteEstimate? route,
    bool? consentGiven,
    bool? isSharing,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TripTrackingState(
      latest: latest ?? this.latest,
      route: route ?? this.route,
      consentGiven: consentGiven ?? this.consentGiven,
      isSharing: isSharing ?? this.isSharing,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripTrackingController extends Notifier<TripTrackingState> {
  TripTrackingController(this.tripId);

  final String tripId;

  @override
  TripTrackingState build() {
    Future.microtask(refresh);
    return const TripTrackingState(isLoading: true);
  }

  LocationRepository? get _repo => ref.read(locationRepositoryProvider);
  MapService get _maps => ref.read(mapServiceProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final trip = ref.read(tripDetailControllerProvider(tripId)).trip;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      LocationUpdate? latest;
      if (repo != null) {
        latest = await repo.latestLocation(tripId);
      }

      RouteEstimate? route;
      final origin = _origin(trip);
      final dest = _dest(trip);
      if (origin != null && dest != null) {
        route = await _maps.estimateRoute(origin: origin, destination: dest);
      }

      state = TripTrackingState(
        latest: latest,
        route: route,
        consentGiven: state.consentGiven,
        isSharing: state.isSharing,
      );
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar el tracking.',
      );
    }
  }

  void setConsent(bool value) {
    state = state.copyWith(consentGiven: value, clearError: true);
    if (!value) {
      state = state.copyWith(isSharing: false);
    }
  }

  Future<bool> shareLocation({
    double? lat,
    double? lng,
    bool simulateNearOrigin = false,
  }) async {
    final repo = _repo;
    final auth = ref.read(authControllerProvider);
    final trip = ref.read(tripDetailControllerProvider(tripId)).trip;
    if (repo == null || auth.profile == null || trip == null) return false;
    if (!state.consentGiven) {
      state = state.copyWith(error: 'Debes aceptar compartir ubicación.');
      return false;
    }
    if (trip.driverId != auth.profile!.id) {
      state = state.copyWith(error: 'Solo el conductor puede compartir.');
      return false;
    }

    var useLat = lat;
    var useLng = lng;
    if (simulateNearOrigin || useLat == null || useLng == null) {
      final origin = _origin(trip);
      if (origin == null) {
        state = state.copyWith(error: 'Sin coordenadas de origen.');
        return false;
      }
      final bump = (DateTime.now().second % 10) * 0.01;
      useLat = origin.lat + bump * 0.05;
      useLng = origin.lng + bump * 0.05;
    }

    state = state.copyWith(isSharing: true, clearError: true);
    try {
      final update = await repo.postLocation(
        tripId: tripId,
        lat: useLat,
        lng: useLng,
      );
      state = state.copyWith(latest: update, isSharing: false);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSharing: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSharing: false,
        error: 'No pudimos enviar la ubicación.',
      );
      return false;
    }
  }

  GeoPoint? _origin(TripSummary? trip) {
    if (trip?.originLat == null || trip?.originLng == null) return null;
    return GeoPoint(trip!.originLat!, trip.originLng!);
  }

  GeoPoint? _dest(TripSummary? trip) {
    if (trip?.destinationLat == null || trip?.destinationLng == null) {
      return null;
    }
    return GeoPoint(trip!.destinationLat!, trip.destinationLng!);
  }
}

final tripTrackingControllerProvider =
    NotifierProvider.family<TripTrackingController, TripTrackingState, String>(
      TripTrackingController.new,
    );

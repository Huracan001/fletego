import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/enums/vehicle_enums.dart';
import '../../auth/application/auth_controller.dart';
import '../../vehicles/application/driver_fleet_controller.dart';
import '../../vehicles/domain/vehicle_models.dart';
import '../data/offer_repository.dart';
import '../domain/matching_service.dart';
import '../domain/offer_models.dart';

final offerRepositoryProvider = Provider<OfferRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return OfferRepository(client);
});

class MarketplaceState {
  const MarketplaceState({
    this.ranked = const [],
    this.selectedVehicleId,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<RankedLoad> ranked;
  final String? selectedVehicleId;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  MarketplaceState copyWith({
    List<RankedLoad>? ranked,
    String? selectedVehicleId,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return MarketplaceState(
      ranked: ranked ?? this.ranked,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MarketplaceController extends Notifier<MarketplaceState> {
  @override
  MarketplaceState build() {
    ref.listen(driverFleetControllerProvider, (prev, next) {
      if (prev?.vehicles != next.vehicles ||
          prev?.latestAvailability != next.latestAvailability) {
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return const MarketplaceState(isLoading: true);
  }

  OfferRepository? get _repo => ref.read(offerRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final auth = ref.read(authControllerProvider);
    final fleet = ref.read(driverFleetControllerProvider);
    if (repo == null || auth.status != AuthStatus.authenticated) {
      state = const MarketplaceState();
      return;
    }

    final vehicle = _resolveVehicle(fleet);
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedVehicleId: vehicle?.id,
    );

    try {
      final loads = await repo.listMarketplaceLoads();
      if (vehicle == null) {
        state = MarketplaceState(
          ranked: const [],
          selectedVehicleId: null,
          error: fleet.vehicles.isEmpty
              ? 'Agrega un vehículo para ver cargas compatibles.'
              : null,
        );
        return;
      }

      VehicleType? type = vehicle.vehicleType;
      if (type == null) {
        for (final t in fleet.types) {
          if (t.id == vehicle.vehicleTypeId) {
            type = t;
            break;
          }
        }
      }

      final availability = fleet.latestAvailability;
      final ranked = MatchingService.rankLoads(
        loads: loads,
        vehicle: vehicle,
        vehicleType: type,
        driver: fleet.driverProfile,
        availability: availability,
        driverLat: null,
        driverLng: null,
        eligibleOnly: false,
      );

      // Prefer eligible first in UI order while keeping score sort within groups
      ranked.sort((a, b) {
        if (a.eligible != b.eligible) return a.eligible ? -1 : 1;
        return b.score.compareTo(a.score);
      });

      state = MarketplaceState(
        ranked: ranked,
        selectedVehicleId: vehicle.id,
      );
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar las cargas.',
      );
    }
  }

  void selectVehicle(String vehicleId) {
    state = state.copyWith(selectedVehicleId: vehicleId);
    refresh();
  }

  Future<Offer?> submitOffer({
    required String requestId,
    required double priceAmount,
    String? message,
  }) async {
    final repo = _repo;
    final vehicleId = state.selectedVehicleId;
    if (repo == null || vehicleId == null) return null;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final offer = await repo.createOffer(
        requestId: requestId,
        vehicleId: vehicleId,
        priceAmount: priceAmount,
        message: message,
      );
      state = state.copyWith(isSubmitting: false);
      await refresh();
      return offer;
    } on AppFailure catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'No pudimos enviar la oferta.',
      );
      return null;
    }
  }

  Vehicle? _resolveVehicle(DriverFleetState fleet) {
    if (fleet.vehicles.isEmpty) return null;
    final selected = state.selectedVehicleId;
    if (selected != null) {
      for (final v in fleet.vehicles) {
        if (v.id == selected) return v;
      }
    }
    final avail = fleet.latestAvailability;
    if (avail != null &&
        avail.status == AvailabilityStatus.available) {
      for (final v in fleet.vehicles) {
        if (v.id == avail.vehicleId) return v;
      }
    }
    return fleet.vehicles.first;
  }
}

final marketplaceControllerProvider =
    NotifierProvider<MarketplaceController, MarketplaceState>(
      MarketplaceController.new,
    );

class RequestOffersState {
  const RequestOffersState({
    this.offers = const [],
    this.isLoading = false,
    this.isAccepting = false,
    this.error,
    this.acceptedTripId,
  });

  final List<Offer> offers;
  final bool isLoading;
  final bool isAccepting;
  final String? error;
  final String? acceptedTripId;

  RequestOffersState copyWith({
    List<Offer>? offers,
    bool? isLoading,
    bool? isAccepting,
    String? error,
    String? acceptedTripId,
    bool clearError = false,
    bool clearAccepted = false,
  }) {
    return RequestOffersState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      isAccepting: isAccepting ?? this.isAccepting,
      error: clearError ? null : (error ?? this.error),
      acceptedTripId: clearAccepted
          ? null
          : (acceptedTripId ?? this.acceptedTripId),
    );
  }
}

class RequestOffersController extends Notifier<RequestOffersState> {
  RequestOffersController(this.requestId);

  final String requestId;

  @override
  RequestOffersState build() {
    Future.microtask(refresh);
    return const RequestOffersState(isLoading: true);
  }

  OfferRepository? get _repo => ref.read(offerRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    if (repo == null) {
      state = const RequestOffersState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final offers = MatchingService.sortOffers(
        await repo.listOffersForRequest(requestId),
      );
      state = RequestOffersState(offers: offers);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar las ofertas.',
      );
    }
  }

  Future<bool> accept(String offerId) async {
    final repo = _repo;
    if (repo == null) return false;

    state = state.copyWith(isAccepting: true, clearError: true);
    try {
      final trip = await repo.acceptOffer(offerId);
      state = state.copyWith(
        isAccepting: false,
        acceptedTripId: trip.id,
      );
      await refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isAccepting: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isAccepting: false,
        error: 'No pudimos aceptar la oferta.',
      );
      return false;
    }
  }
}

final requestOffersControllerProvider = NotifierProvider.family<
  RequestOffersController,
  RequestOffersState,
  String
>(RequestOffersController.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/enums/vehicle_enums.dart';
import '../../auth/application/auth_controller.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle_models.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return VehicleRepository(client);
});

class DriverFleetState {
  const DriverFleetState({
    this.driverProfile,
    this.vehicles = const [],
    this.types = const [],
    this.latestAvailability,
    this.isLoading = false,
    this.error,
  });

  final DriverProfile? driverProfile;
  final List<Vehicle> vehicles;
  final List<VehicleType> types;
  final DriverAvailability? latestAvailability;
  final bool isLoading;
  final String? error;

  bool get isAvailable =>
      latestAvailability?.status == AvailabilityStatus.available;

  DriverFleetState copyWith({
    DriverProfile? driverProfile,
    List<Vehicle>? vehicles,
    List<VehicleType>? types,
    DriverAvailability? latestAvailability,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearAvailability = false,
  }) {
    return DriverFleetState(
      driverProfile: driverProfile ?? this.driverProfile,
      vehicles: vehicles ?? this.vehicles,
      types: types ?? this.types,
      latestAvailability: clearAvailability
          ? null
          : (latestAvailability ?? this.latestAvailability),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DriverFleetController extends Notifier<DriverFleetState> {
  @override
  DriverFleetState build() {
    ref.listen<AuthSessionState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        refresh();
      } else if (next.status == AuthStatus.unauthenticated) {
        state = const DriverFleetState();
      }
    });
    Future.microtask(refresh);
    return const DriverFleetState(isLoading: true);
  }

  VehicleRepository? get _repo => ref.read(vehicleRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final auth = ref.read(authControllerProvider);
    if (repo == null || auth.status != AuthStatus.authenticated) {
      state = const DriverFleetState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final types = await repo.listVehicleTypes();
      final profile = await repo.ensureDriverProfile();
      final vehicles = await repo.listMyVehicles();
      final availability = await repo.latestAvailability(profile.id);
      state = DriverFleetState(
        driverProfile: profile,
        vehicles: vehicles,
        types: types,
        latestAvailability: availability,
      );
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar tu flota.',
      );
    }
  }

  Future<bool> saveDriverProfile({
    required String licenseNumber,
    DateTime? licenseExpiry,
    int? yearsExperience,
    bool acceptsReturnLoads = true,
  }) async {
    final repo = _repo;
    final profile = state.driverProfile;
    if (repo == null || profile == null) return false;

    try {
      final updated = await repo.updateDriverProfile(
        driverProfileId: profile.id,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        yearsExperience: yearsExperience,
        acceptsReturnLoads: acceptsReturnLoads,
      );
      await repo.addDriverDocumentMeta(
        driverProfileId: profile.id,
        kind: DocumentKind.license,
        expiryDate: licenseExpiry,
      );
      state = state.copyWith(driverProfile: updated, clearError: true);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<Vehicle?> addVehicle({
    required String vehicleTypeId,
    required String plate,
    String? brand,
    String? model,
    int? year,
    double? capacityKg,
    double? maxCargoKg,
    bool hasRefrigeration = false,
    bool hasTarp = false,
    bool acceptsDangerousGoods = false,
  }) async {
    final repo = _repo;
    final profile = state.driverProfile;
    if (repo == null || profile == null) return null;

    try {
      final vehicle = await repo.createVehicle(
        vehicleTypeId: vehicleTypeId,
        plate: plate,
        brand: brand,
        model: model,
        year: year,
        capacityKg: capacityKg,
        maxCargoKg: maxCargoKg,
        hasRefrigeration: hasRefrigeration,
        hasTarp: hasTarp,
        acceptsDangerousGoods: acceptsDangerousGoods,
      );
      await repo.linkDriverToVehicle(
        driverProfileId: profile.id,
        vehicleId: vehicle.id,
        isPrimary: state.vehicles.isEmpty,
      );
      await refresh();
      return vehicle;
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    }
  }

  Future<bool> setAvailable({
    required String vehicleId,
    bool acceptsReturnCargo = true,
    double? maxDeadheadKm,
  }) async {
    final repo = _repo;
    final profile = state.driverProfile;
    if (repo == null || profile == null) return false;

    try {
      final availability = await repo.publishAvailability(
        driverProfileId: profile.id,
        vehicleId: vehicleId,
        status: AvailabilityStatus.available,
        availableFrom: DateTime.now(),
        acceptsReturnCargo: acceptsReturnCargo,
        maxDeadheadKm: maxDeadheadKm,
      );
      state = state.copyWith(
        latestAvailability: availability,
        clearError: true,
      );
      await refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> setOffline() async {
    final repo = _repo;
    final profile = state.driverProfile;
    final availability = state.latestAvailability;
    if (repo == null || profile == null || availability == null) return false;

    try {
      await repo.goOffline(
        driverProfileId: profile.id,
        vehicleId: availability.vehicleId,
      );
      state = state.copyWith(clearAvailability: true, clearError: true);
      await refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}

final driverFleetControllerProvider =
    NotifierProvider<DriverFleetController, DriverFleetState>(
      DriverFleetController.new,
    );

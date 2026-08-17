import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../cargo/application/cargo_wizard_controller.dart';
import '../../cargo/domain/cargo_models.dart';
import '../../trips/application/trips_controller.dart';
import '../../trips/domain/trip_models.dart';
import '../../vehicles/application/driver_fleet_controller.dart';
import '../../vehicles/domain/vehicle_models.dart';
import '../domain/company_driver.dart';
import 'company_controller.dart';

class CompanyDashboardState {
  const CompanyDashboardState({
    this.companyId,
    this.activeTrips = const [],
    this.drivers = const [],
    this.vehicles = const [],
    this.pendingRequests = const [],
    this.isLoading = false,
    this.error,
  });

  final String? companyId;
  final List<TripSummary> activeTrips;
  final List<CompanyDriver> drivers;
  final List<Vehicle> vehicles;
  final List<CargoRequestSummary> pendingRequests;
  final bool isLoading;
  final String? error;

  CompanyDashboardState copyWith({
    String? companyId,
    List<TripSummary>? activeTrips,
    List<CompanyDriver>? drivers,
    List<Vehicle>? vehicles,
    List<CargoRequestSummary>? pendingRequests,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CompanyDashboardState(
      companyId: companyId ?? this.companyId,
      activeTrips: activeTrips ?? this.activeTrips,
      drivers: drivers ?? this.drivers,
      vehicles: vehicles ?? this.vehicles,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CompanyDashboardController extends Notifier<CompanyDashboardState> {
  @override
  CompanyDashboardState build() {
    ref.listen<String?>(selectedCompanyIdProvider, (prev, next) {
      if (next != null && next != prev) {
        refresh(companyId: next);
      }
    });
    ref.listen(activeMembershipProvider, (prev, next) {
      final id = next?.company.id;
      if (id != null && id != state.companyId) {
        Future.microtask(() => refresh(companyId: id));
      }
    });

    final membership = ref.read(activeMembershipProvider);
    if (membership != null) {
      Future.microtask(() => refresh(companyId: membership.company.id));
    }
    return const CompanyDashboardState(isLoading: true);
  }

  Future<void> refresh({String? companyId}) async {
    final id =
        companyId ??
        ref.read(selectedCompanyIdProvider) ??
        ref.read(activeMembershipProvider)?.company.id;

    if (id == null) {
      state = const CompanyDashboardState();
      return;
    }

    final companyRepo = ref.read(companyRepositoryProvider);
    final tripRepo = ref.read(tripRepositoryProvider);
    final vehicleRepo = ref.read(vehicleRepositoryProvider);
    final cargoRepo = ref.read(cargoRepositoryProvider);

    if (companyRepo == null ||
        tripRepo == null ||
        vehicleRepo == null ||
        cargoRepo == null) {
      state = CompanyDashboardState(
        companyId: id,
        error: 'Supabase no está configurado.',
      );
      return;
    }

    state = state.copyWith(companyId: id, isLoading: true, clearError: true);

    // Load each slice independently so one failing RPC/RLS doesn't blank the panel.
    final errors = <String>[];

    var trips = <TripSummary>[];
    var drivers = <CompanyDriver>[];
    var vehicles = <Vehicle>[];
    var requests = <CargoRequestSummary>[];

    try {
      trips = await tripRepo.listCompanyTrips(id, activeOnly: true);
    } on AppFailure catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('No pudimos cargar los viajes.');
    }

    try {
      drivers = await companyRepo.listDrivers(id);
    } on AppFailure catch (e) {
      // RPC missing until Phase 12 SQL is applied — treat as empty fleet drivers.
      final lower = e.message.toLowerCase();
      if (!lower.contains('list_company_drivers') &&
          !lower.contains('could not find') &&
          !lower.contains('pgrst202')) {
        errors.add(e.message);
      }
    } catch (_) {
      // ignore — empty drivers
    }

    try {
      vehicles = await vehicleRepo.listCompanyVehicles(id);
    } on AppFailure catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('No pudimos cargar la flota.');
    }

    try {
      requests = await cargoRepo.listCompanyRequests(id, pendingOnly: true);
    } on AppFailure catch (e) {
      errors.add(e.message);
    } catch (_) {
      errors.add('No pudimos cargar las solicitudes.');
    }

    state = CompanyDashboardState(
      companyId: id,
      activeTrips: trips,
      drivers: drivers,
      vehicles: vehicles,
      pendingRequests: requests,
      error: errors.isEmpty ? null : errors.first,
    );
  }

  Future<Vehicle?> addCompanyVehicle({
    required String companyId,
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
    final repo = ref.read(vehicleRepositoryProvider);
    if (repo == null) return null;

    try {
      final vehicle = await repo.createVehicle(
        vehicleTypeId: vehicleTypeId,
        plate: plate,
        companyId: companyId,
        brand: brand,
        model: model,
        year: year,
        capacityKg: capacityKg,
        maxCargoKg: maxCargoKg,
        hasRefrigeration: hasRefrigeration,
        hasTarp: hasTarp,
        acceptsDangerousGoods: acceptsDangerousGoods,
      );
      await refresh(companyId: companyId);
      return vehicle;
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    }
  }
}

final companyDashboardControllerProvider =
    NotifierProvider<CompanyDashboardController, CompanyDashboardState>(
      CompanyDashboardController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/enums/trip_status.dart';
import '../../auth/application/auth_controller.dart';
import '../data/trip_repository.dart';
import '../domain/trip_models.dart';
import '../domain/trip_state_service.dart';

final tripRepositoryProvider = Provider<TripRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return TripRepository(client);
});

class TripsListState {
  const TripsListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TripSummary> items;
  final bool isLoading;
  final String? error;

  TripSummary? get activeTrip {
    for (final t in items) {
      if (t.status.isActive) return t;
    }
    return null;
  }

  TripsListState copyWith({
    List<TripSummary>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TripsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripsListController extends Notifier<TripsListState> {
  @override
  TripsListState build() {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        Future.microtask(refresh);
      } else if (next.status == AuthStatus.unauthenticated) {
        state = const TripsListState();
      }
    });
    Future.microtask(refresh);
    return const TripsListState(isLoading: true);
  }

  TripRepository? get _repo => ref.read(tripRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final auth = ref.read(authControllerProvider);
    if (repo == null || auth.status != AuthStatus.authenticated) {
      state = const TripsListState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.listMyTrips();
      state = TripsListState(items: items);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar tus viajes.',
      );
    }
  }
}

final tripsListControllerProvider =
    NotifierProvider<TripsListController, TripsListState>(
      TripsListController.new,
    );

class TripDetailState {
  const TripDetailState({
    this.trip,
    this.history = const [],
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  final TripSummary? trip;
  final List<TripHistoryEntry> history;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  TripDetailState copyWith({
    TripSummary? trip,
    List<TripHistoryEntry>? history,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool clearError = false,
    bool clearTrip = false,
  }) {
    return TripDetailState(
      trip: clearTrip ? null : (trip ?? this.trip),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripDetailController extends Notifier<TripDetailState> {
  TripDetailController(this.tripId);

  final String tripId;
  static const _machine = TripStateService();

  @override
  TripDetailState build() {
    Future.microtask(refresh);
    return const TripDetailState(isLoading: true);
  }

  TripRepository? get _repo => ref.read(tripRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    if (repo == null) {
      state = const TripDetailState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final trip = await repo.getTrip(tripId);
      final history = trip == null
          ? <TripHistoryEntry>[]
          : await repo.listHistory(tripId);
      state = TripDetailState(trip: trip, history: history);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar el viaje.',
      );
    }
  }

  Future<bool> advanceTo(TripStatus next, {String? note}) async {
    final repo = _repo;
    final trip = state.trip;
    if (repo == null || trip == null) return false;

    state = state.copyWith(isUpdating: true, clearError: true);
    try {
      final updated = await repo.advanceStatus(
        tripId: trip.id,
        toStatus: next,
        note: note,
      );
      // Re-fetch with join for route labels
      await refresh();
      if (state.trip == null) {
        state = state.copyWith(trip: updated, isUpdating: false);
      } else {
        state = state.copyWith(isUpdating: false);
      }
      ref.read(tripsListControllerProvider.notifier).refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isUpdating: false,
        error: 'No pudimos actualizar el estado.',
      );
      return false;
    }
  }

  Future<bool> advanceNextDriverStep() async {
    final trip = state.trip;
    if (trip == null) return false;
    final next = _machine.nextDriverStep(trip.status);
    if (next == null) return false;
    return advanceTo(next);
  }

  Future<bool> completeTrip() async {
    final trip = state.trip;
    if (trip == null) return false;
    if (!_machine.canTransition(trip.status, TripStatus.completed)) {
      return false;
    }
    return advanceTo(TripStatus.completed, note: 'Viaje completado');
  }

  Future<bool> cancel({String? reason}) async {
    final repo = _repo;
    final trip = state.trip;
    if (repo == null || trip == null) return false;

    state = state.copyWith(isUpdating: true, clearError: true);
    try {
      await repo.cancelTrip(tripId: trip.id, reason: reason);
      await refresh();
      ref.read(tripsListControllerProvider.notifier).refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isUpdating: false,
        error: 'No pudimos cancelar el viaje.',
      );
      return false;
    }
  }
}

final tripDetailControllerProvider =
    NotifierProvider.family<TripDetailController, TripDetailState, String>(
      TripDetailController.new,
    );

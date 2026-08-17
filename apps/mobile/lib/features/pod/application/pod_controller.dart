import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../trips/application/trips_controller.dart';
import '../data/pod_repository.dart';
import '../domain/pod_models.dart';

final podRepositoryProvider = Provider<PodRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PodRepository(client);
});

class TripPodState {
  const TripPodState({
    this.pickup,
    this.pod,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final PickupEvidence? pickup;
  final ProofOfDelivery? pod;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  TripPodState copyWith({
    PickupEvidence? pickup,
    ProofOfDelivery? pod,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TripPodState(
      pickup: pickup ?? this.pickup,
      pod: pod ?? this.pod,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripPodController extends Notifier<TripPodState> {
  TripPodController(this.tripId);

  final String tripId;

  @override
  TripPodState build() {
    Future.microtask(refresh);
    return const TripPodState(isLoading: true);
  }

  PodRepository? get _repo => ref.read(podRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    if (repo == null) {
      state = const TripPodState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pickup = await repo.getPickup(tripId);
      final pod = await repo.getPod(tripId);
      state = TripPodState(pickup: pickup, pod: pod);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar evidencias.',
      );
    }
  }

  Future<bool> savePickup({
    String? notes,
    List<String> photoPaths = const [],
    double? lat,
    double? lng,
  }) async {
    final repo = _repo;
    if (repo == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final pickup = await repo.submitPickup(
        tripId: tripId,
        notes: notes,
        photoPaths: photoPaths,
        lat: lat,
        lng: lng,
      );
      state = state.copyWith(pickup: pickup, isSaving: false);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'No pudimos guardar la recogida.',
      );
      return false;
    }
  }

  Future<bool> savePod({
    required String recipientName,
    String? recipientIdRef,
    String? signaturePath,
    List<String> photoPaths = const [],
    String? notes,
    double? lat,
    double? lng,
  }) async {
    final repo = _repo;
    if (repo == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final pod = await repo.submitPod(
        tripId: tripId,
        recipientName: recipientName,
        recipientIdRef: recipientIdRef,
        signaturePath: signaturePath,
        photoPaths: photoPaths,
        notes: notes,
        lat: lat,
        lng: lng,
      );
      state = state.copyWith(pod: pod, isSaving: false);
      // Trip may have moved to delivered
      await ref.read(tripDetailControllerProvider(tripId).notifier).refresh();
      ref.read(tripsListControllerProvider.notifier).refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'No pudimos guardar el POD.',
      );
      return false;
    }
  }
}

final tripPodControllerProvider =
    NotifierProvider.family<TripPodController, TripPodState, String>(
      TripPodController.new,
    );

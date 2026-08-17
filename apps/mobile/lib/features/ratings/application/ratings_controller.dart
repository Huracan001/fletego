import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../trips/application/trips_controller.dart';
import '../data/rating_repository.dart';
import '../domain/rating_models.dart';

final ratingRepositoryProvider = Provider<RatingRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return RatingRepository(client);
});

class TripRatingsState {
  const TripRatingsState({
    this.ratings = const [],
    this.myRating,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<TripRating> ratings;
  final TripRating? myRating;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  TripRatingsState copyWith({
    List<TripRating>? ratings,
    TripRating? myRating,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool clearMine = false,
  }) {
    return TripRatingsState(
      ratings: ratings ?? this.ratings,
      myRating: clearMine ? null : (myRating ?? this.myRating),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripRatingsController extends Notifier<TripRatingsState> {
  TripRatingsController(this.tripId);

  final String tripId;

  @override
  TripRatingsState build() {
    Future.microtask(refresh);
    return const TripRatingsState(isLoading: true);
  }

  RatingRepository? get _repo => ref.read(ratingRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final uid = ref.read(authControllerProvider).profile?.id;
    if (repo == null) {
      state = const TripRatingsState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ratings = await repo.listForTrip(tripId);
      TripRating? mine;
      for (final r in ratings) {
        if (r.fromUserId == uid) {
          mine = r;
          break;
        }
      }
      state = TripRatingsState(ratings: ratings, myRating: mine);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar calificaciones.',
      );
    }
  }

  Future<bool> submit({
    required int overall,
    required Map<String, int> dimensions,
    String? comment,
  }) async {
    final repo = _repo;
    if (repo == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final rating = await repo.submit(
        tripId: tripId,
        overall: overall,
        dimensions: dimensions,
        comment: comment,
      );
      state = state.copyWith(
        isSaving: false,
        myRating: rating,
        ratings: [
          ...state.ratings.where((r) => r.fromUserId != rating.fromUserId),
          rating,
        ],
      );
      ref.read(tripsListControllerProvider.notifier).refresh();
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'No pudimos guardar la calificación.',
      );
      return false;
    }
  }
}

final tripRatingsControllerProvider =
    NotifierProvider.family<TripRatingsController, TripRatingsState, String>(
      TripRatingsController.new,
    );

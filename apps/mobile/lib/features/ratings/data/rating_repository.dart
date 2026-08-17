import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/rating_models.dart';

class RatingRepository {
  RatingRepository(this._client);

  final SupabaseClient _client;

  Future<List<TripRating>> listForTrip(String tripId) async {
    try {
      final rows = await _client
          .from('ratings')
          .select()
          .eq('trip_id', tripId)
          .order('created_at');
      return (rows as List)
          .map((r) => TripRating.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar las calificaciones.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<TripRating?> myRatingForTrip(String tripId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final all = await listForTrip(tripId);
    for (final r in all) {
      if (r.fromUserId == uid) return r;
    }
    return null;
  }

  Future<TripRating> submit({
    required String tripId,
    required int overall,
    required Map<String, int> dimensions,
    String? comment,
  }) async {
    if (overall < 1 || overall > 5) {
      throw const ValidationFailure('Elige una calificación de 1 a 5.');
    }

    try {
      final row = await _client.rpc(
        'submit_rating',
        params: {
          'p_trip_id': tripId,
          'p_overall': overall,
          'p_dimensions': dimensions,
          'p_comment': comment,
        },
      );
      Map<String, dynamic> map;
      if (row is Map) {
        map = Map<String, dynamic>.from(row);
      } else if (row is List && row.isNotEmpty && row.first is Map) {
        map = Map<String, dynamic>.from(row.first as Map);
      } else {
        throw const UnexpectedFailure('Respuesta inesperada.');
      }
      return TripRating.fromJson(map);
    } on PostgrestException catch (e) {
      throw NetworkFailure(_error(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  String _error(String message) {
    final m = message.toLowerCase();
    if (m.contains('trip_not_rateable')) {
      return 'Solo puedes calificar viajes entregados o completados.';
    }
    if (m.contains('invalid_overall')) {
      return 'Elige una calificación de 1 a 5.';
    }
    if (m.contains('not_allowed')) {
      return 'No puedes calificar este viaje.';
    }
    return 'No pudimos guardar la calificación.${message.isNotEmpty ? ' ($message)' : ''}';
  }
}

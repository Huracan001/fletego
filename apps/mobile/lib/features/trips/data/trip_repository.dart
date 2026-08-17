import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../shared/enums/trip_status.dart';
import '../domain/trip_models.dart';
import '../domain/trip_state_service.dart';

class TripRepository {
  TripRepository(this._client);

  final SupabaseClient _client;
  static const _select =
      '*, cargo_requests(origin_city, destination_city, cargo_type, origin_lat, origin_lng, destination_lat, destination_lng)';

  Future<List<TripSummary>> listMyTrips({bool activeOnly = false}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthFailure('Debes iniciar sesión.');

    try {
      final rows = await _fetchTripRows(uid);
      var trips =
          rows
              .map((r) => TripSummary.fromJson(Map<String, dynamic>.from(r)))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (activeOnly) {
        trips = trips.where((t) => t.status.isActive).toList();
      }
      return trips;
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos cargar tus viajes.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<TripSummary>> listCompanyTrips(
    String companyId, {
    bool activeOnly = false,
  }) async {
    try {
      List<Map<String, dynamic>> rows;
      try {
        final raw = await _client
            .from('trips')
            .select(_select)
            .eq('company_id', companyId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(40);
        rows = (raw as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
      } on PostgrestException {
        final raw = await _client
            .from('trips')
            .select('*')
            .eq('company_id', companyId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(40);
        rows = (raw as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
      }

      var trips = rows.map(TripSummary.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (activeOnly) {
        trips = trips.where((t) => t.status.isActive).toList();
      }
      return trips;
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos cargar los viajes de la empresa.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTripRows(String uid) async {
    Future<List<Map<String, dynamic>>> query(String select) async {
      final asCustomer = await _client
          .from('trips')
          .select(select)
          .eq('customer_id', uid)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(40);

      final asDriver = await _client
          .from('trips')
          .select(select)
          .eq('driver_id', uid)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(40);

      final byId = <String, Map<String, dynamic>>{};
      for (final row in [...(asCustomer as List), ...(asDriver as List)]) {
        final map = Map<String, dynamic>.from(row as Map);
        byId[map['id'] as String] = map;
      }
      return byId.values.toList();
    }

    try {
      return await query(_select);
    } on PostgrestException {
      // Embed join can fail if relationship hint differs — still list trips.
      return await query('*');
    }
  }

  Future<TripSummary?> getTrip(String tripId) async {
    try {
      final row = await _client
          .from('trips')
          .select(_select)
          .eq('id', tripId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();
      if (row == null) return null;
      return TripSummary.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar el viaje.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<TripHistoryEntry>> listHistory(String tripId) async {
    try {
      final rows = await _client
          .from('trip_status_history')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (r) =>
                TripHistoryEntry.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar el historial.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<TripSummary> advanceStatus({
    required String tripId,
    required TripStatus toStatus,
    String? note,
  }) async {
    const service = TripStateService();
    // Client-side guard; DB also validates
    final current = await getTrip(tripId);
    if (current == null) {
      throw const ValidationFailure('Viaje no encontrado.');
    }
    if (!service.canTransition(current.status, toStatus)) {
      throw ValidationFailure(
        'Transición inválida: ${current.status.dbValue} → ${toStatus.dbValue}',
      );
    }

    try {
      final row = await _client.rpc(
        'advance_trip_status',
        params: {
          'p_trip_id': tripId,
          'p_to_status': toStatus.dbValue,
          'p_note': note,
        },
      );
      return _tripFromRpc(row);
    } on PostgrestException catch (e) {
      throw NetworkFailure(_advanceError(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<TripSummary> cancelTrip({
    required String tripId,
    String? reason,
  }) async {
    try {
      final row = await _client.rpc(
        'cancel_trip',
        params: {'p_trip_id': tripId, 'p_reason': reason},
      );
      return _tripFromRpc(row);
    } on PostgrestException catch (e) {
      throw NetworkFailure(_cancelError(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> softDelete(String tripId) async {
    try {
      await _client.rpc('soft_delete_trip', params: {'p_trip_id': tripId});
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos archivar el viaje.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  TripSummary _tripFromRpc(dynamic row) {
    Map<String, dynamic> map;
    if (row is Map) {
      map = Map<String, dynamic>.from(row);
    } else if (row is List && row.isNotEmpty && row.first is Map) {
      map = Map<String, dynamic>.from(row.first as Map);
    } else {
      throw const UnexpectedFailure('Respuesta inesperada del servidor.');
    }
    return TripSummary.fromJson(map);
  }

  String _advanceError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid_transition')) {
      return 'Esa transición de estado no está permitida.';
    }
    if (m.contains('driver_only_step')) {
      return 'Solo el conductor puede avanzar este paso.';
    }
    if (m.contains('not_allowed')) {
      return 'No tienes permiso para este viaje.';
    }
    return 'No pudimos actualizar el viaje.${message.isNotEmpty ? ' ($message)' : ''}';
  }

  String _cancelError(String message) {
    final m = message.toLowerCase();
    if (m.contains('cannot_cancel')) {
      return 'Este viaje ya no se puede cancelar.';
    }
    return 'No pudimos cancelar el viaje.${message.isNotEmpty ? ' ($message)' : ''}';
  }
}

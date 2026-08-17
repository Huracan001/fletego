import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/location_models.dart';

class LocationRepository {
  LocationRepository(this._client);

  final SupabaseClient _client;

  Future<LocationUpdate> postLocation({
    required String tripId,
    required double lat,
    required double lng,
    double? speedMps,
    double? headingDeg,
    double? accuracyM,
  }) async {
    try {
      final row = await _client.rpc(
        'post_trip_location',
        params: {
          'p_trip_id': tripId,
          'p_lat': lat,
          'p_lng': lng,
          'p_speed_mps': speedMps,
          'p_heading_deg': headingDeg,
          'p_accuracy_m': accuracyM,
        },
      );
      return LocationUpdate.fromJson(_asMap(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure(_error(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<LocationUpdate?> latestLocation(String tripId) async {
    try {
      final row = await _client.rpc(
        'get_trip_latest_location',
        params: {'p_trip_id': tripId},
      );
      if (row == null) return null;
      if (row is! Map) return null;
      final map = Map<String, dynamic>.from(row);
      if (map.isEmpty || map['id'] == null) return null;
      return LocationUpdate.fromJson(map);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return null;
      throw NetworkFailure('No pudimos cargar la ubicación.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      // Empty / null composite from RPC — treat as no location yet
      return null;
    }
  }

  Map<String, dynamic> _asMap(dynamic row) {
    if (row is Map) return Map<String, dynamic>.from(row);
    if (row is List && row.isNotEmpty && row.first is Map) {
      return Map<String, dynamic>.from(row.first as Map);
    }
    throw const UnexpectedFailure('Respuesta inesperada del servidor.');
  }

  String _error(String message) {
    final m = message.toLowerCase();
    if (m.contains('driver_only')) {
      return 'Solo el conductor puede compartir ubicación.';
    }
    if (m.contains('trip_not_active')) {
      return 'El viaje ya no está activo.';
    }
    if (m.contains('invalid_coordinates')) {
      return 'Coordenadas inválidas.';
    }
    return 'No pudimos guardar la ubicación.${message.isNotEmpty ? ' ($message)' : ''}';
  }
}

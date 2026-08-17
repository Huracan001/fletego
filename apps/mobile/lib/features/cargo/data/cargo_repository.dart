import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../vehicles/domain/vehicle_models.dart';
import '../domain/cargo_models.dart';

class CargoRepository {
  CargoRepository(this._client);

  final SupabaseClient _client;

  Future<List<VehicleType>> listVehicleTypes() async {
    try {
      final rows = await _client
          .from('vehicle_types')
          .select()
          .eq('is_active', true)
          .order('name_es');
      return (rows as List)
          .map((r) => VehicleType.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar tipos de camión.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<CargoRequestSummary> submit(CargoRequestDraft draft) async {
    if (draft.cargoType == null) {
      throw const ValidationFailure('Selecciona el tipo de carga.');
    }
    if (!draft.origin.isValid || !draft.destination.isValid) {
      throw const ValidationFailure('Completa origen y destino.');
    }

    try {
      final row = await _client.rpc(
        'submit_cargo_request',
        params: {'p_payload': draft.toSubmitPayload()},
      );

      Map<String, dynamic> map;
      if (row is Map) {
        map = Map<String, dynamic>.from(row);
      } else if (row is List && row.isNotEmpty && row.first is Map) {
        map = Map<String, dynamic>.from(row.first as Map);
      } else {
        throw const UnexpectedFailure('No pudimos crear la solicitud.');
      }

      return CargoRequestSummary.fromJson(map);
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos enviar la solicitud.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<CargoRequestSummary>> listMyRequests() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthFailure('Debes iniciar sesión.');

    try {
      final rows = await _client
          .from('cargo_requests')
          .select(
            'id, status, cargo_type, origin_city, destination_city, created_at, total_weight_kg, requested_vehicle_type:vehicle_types!cargo_requests_requested_vehicle_type_id_fkey(name_es)',
          )
          .eq('customer_id', uid)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(50);

      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        // Normalize nested key for fromJson
        if (map['requested_vehicle_type'] != null) {
          map['vehicle_types'] = map['requested_vehicle_type'];
        }
        return CargoRequestSummary.fromJson(map);
      }).toList();
    } on PostgrestException catch (e) {
      // Fallback without vehicle type join if FK hint fails
      try {
        final rows = await _client
            .from('cargo_requests')
            .select(
              'id, status, cargo_type, origin_city, destination_city, created_at, total_weight_kg',
            )
            .eq('customer_id', uid)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(50);
        return (rows as List)
            .map(
              (r) => CargoRequestSummary.fromJson(
                Map<String, dynamic>.from(r as Map),
              ),
            )
            .toList();
      } catch (_) {
        throw NetworkFailure('No pudimos cargar tus solicitudes.', e);
      }
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<CargoRequestSummary>> listCompanyRequests(
    String companyId, {
    bool pendingOnly = false,
  }) async {
    try {
      List<CargoRequestSummary> parse(List raw) {
        return raw.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          if (map['requested_vehicle_type'] != null) {
            map['vehicle_types'] = map['requested_vehicle_type'];
          }
          return CargoRequestSummary.fromJson(map);
        }).toList();
      }

      List<CargoRequestSummary> items;
      try {
        final rows = await _client
            .from('cargo_requests')
            .select(
              'id, status, cargo_type, origin_city, destination_city, created_at, total_weight_kg, company_id, requested_vehicle_type:vehicle_types!cargo_requests_requested_vehicle_type_id_fkey(name_es)',
            )
            .eq('company_id', companyId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(50);
        items = parse(rows as List);
      } on PostgrestException {
        final rows = await _client
            .from('cargo_requests')
            .select(
              'id, status, cargo_type, origin_city, destination_city, created_at, total_weight_kg, company_id',
            )
            .eq('company_id', companyId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(50);
        items = parse(rows as List);
      }

      if (pendingOnly) {
        items = items.where((r) => r.status.isPendingOpen).toList();
      }
      return items;
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos cargar las solicitudes de la empresa.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }
}

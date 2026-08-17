import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/pod_models.dart';

class PodRepository {
  PodRepository(this._client);

  final SupabaseClient _client;

  Future<PickupEvidence?> getPickup(String tripId) async {
    try {
      final row = await _client
          .from('pickup_evidence')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      if (row == null) return null;
      return PickupEvidence.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar la evidencia de recogida.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<ProofOfDelivery?> getPod(String tripId) async {
    try {
      final row = await _client
          .from('proof_of_delivery')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      if (row == null) return null;
      return ProofOfDelivery.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar el POD.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<PickupEvidence> submitPickup({
    required String tripId,
    String? notes,
    List<String> photoPaths = const [],
    double? lat,
    double? lng,
  }) async {
    try {
      final row = await _client.rpc(
        'submit_pickup_evidence',
        params: {
          'p_trip_id': tripId,
          'p_notes': notes,
          'p_photo_paths': photoPaths,
          'p_lat': lat,
          'p_lng': lng,
        },
      );
      return PickupEvidence.fromJson(_asMap(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure(_pickupError(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<ProofOfDelivery> submitPod({
    required String tripId,
    required String recipientName,
    String? recipientIdRef,
    String? signaturePath,
    List<String> photoPaths = const [],
    String? notes,
    double? lat,
    double? lng,
    bool markDelivered = true,
  }) async {
    if (recipientName.trim().isEmpty) {
      throw const ValidationFailure('Ingresa el nombre del receptor.');
    }

    try {
      final row = await _client.rpc(
        'submit_proof_of_delivery',
        params: {
          'p_trip_id': tripId,
          'p_recipient_name': recipientName.trim(),
          'p_recipient_id_ref': recipientIdRef,
          'p_signature_path': signaturePath,
          'p_photo_paths': photoPaths,
          'p_notes': notes,
          'p_lat': lat,
          'p_lng': lng,
          'p_mark_delivered': markDelivered,
        },
      );
      return ProofOfDelivery.fromJson(_asMap(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure(_podError(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic row) {
    if (row is Map) return Map<String, dynamic>.from(row);
    if (row is List && row.isNotEmpty && row.first is Map) {
      return Map<String, dynamic>.from(row.first as Map);
    }
    throw const UnexpectedFailure('Respuesta inesperada del servidor.');
  }

  String _pickupError(String message) {
    final m = message.toLowerCase();
    if (m.contains('driver_only')) {
      return 'Solo el conductor puede registrar la recogida.';
    }
    if (m.contains('invalid_status')) {
      return 'Aún no puedes registrar evidencia de recogida en este estado.';
    }
    return 'No pudimos guardar la evidencia.${message.isNotEmpty ? ' ($message)' : ''}';
  }

  String _podError(String message) {
    final m = message.toLowerCase();
    if (m.contains('driver_only')) {
      return 'Solo el conductor puede registrar el POD.';
    }
    if (m.contains('recipient_required')) {
      return 'Ingresa el nombre del receptor.';
    }
    if (m.contains('invalid_status')) {
      return 'Registra el POD al llegar / entregar en destino.';
    }
    return 'No pudimos guardar el POD.${message.isNotEmpty ? ' ($message)' : ''}';
  }
}

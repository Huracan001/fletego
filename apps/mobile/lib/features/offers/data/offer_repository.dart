import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/offer_models.dart';

class OfferRepository {
  OfferRepository(this._client);

  final SupabaseClient _client;

  Future<List<MarketplaceLoad>> listMarketplaceLoads() async {
    try {
      final rows = await _client.rpc('list_marketplace_loads');
      return (rows as List)
          .map(
            (r) => MarketplaceLoad.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos cargar el marketplace.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<Offer> createOffer({
    required String requestId,
    required String vehicleId,
    required double priceAmount,
    String? message,
    DateTime? etaPickupAt,
    double? distanceKmEstimate,
  }) async {
    if (priceAmount <= 0) {
      throw const ValidationFailure('Ingresa un precio válido.');
    }

    try {
      final row = await _client.rpc(
        'create_offer',
        params: {
          'p_request_id': requestId,
          'p_vehicle_id': vehicleId,
          'p_price_amount': priceAmount,
          'p_message': message,
          'p_eta_pickup_at': etaPickupAt?.toUtc().toIso8601String(),
          'p_distance_km_estimate': distanceKmEstimate,
        },
      );

      final map = _asMap(row);
      return Offer.fromJson(map);
    } on PostgrestException catch (e) {
      throw NetworkFailure(_offerError(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<Offer>> listOffersForRequest(String requestId) async {
    try {
      final rows = await _client
          .from('offers')
          .select()
          .eq('request_id', requestId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      return (rows as List)
          .map((r) => Offer.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar las ofertas.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<Offer>> listMyOffers() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthFailure('Debes iniciar sesión.');

    try {
      final rows = await _client
          .from('offers')
          .select()
          .eq('transporter_profile_id', uid)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(50);

      return (rows as List)
          .map((r) => Offer.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar tus ofertas.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<TripBootstrap> acceptOffer(String offerId) async {
    try {
      final row = await _client.rpc(
        'accept_offer',
        params: {'p_offer_id': offerId},
      );
      return TripBootstrap.fromJson(_asMap(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure(_acceptError(e.message), e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> withdrawOffer(String offerId) async {
    try {
      await _client
          .from('offers')
          .update({'status': 'withdrawn'})
          .eq('id', offerId)
          .eq('status', 'pending');
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos retirar la oferta.', e);
    } catch (e) {
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

  String _offerError(String message) {
    final m = message.toLowerCase();
    if (m.contains('driver_profile_required')) {
      return 'Completa tu perfil de conductor primero.';
    }
    if (m.contains('request_not_open')) {
      return 'Esta solicitud ya no acepta ofertas.';
    }
    if (m.contains('cannot_offer_own_request')) {
      return 'No puedes ofertar en tu propia solicitud.';
    }
    if (m.contains('vehicle_not_allowed')) {
      return 'No puedes usar ese vehículo.';
    }
    if (m.contains('invalid_price')) {
      return 'Ingresa un precio válido.';
    }
    return 'No pudimos enviar la oferta.${message.isNotEmpty ? ' ($message)' : ''}';
  }

  String _acceptError(String message) {
    final m = message.toLowerCase();
    if (m.contains('offer_not_pending')) {
      return 'Esta oferta ya no está pendiente.';
    }
    if (m.contains('not_allowed')) {
      return 'Solo el cliente puede aceptar esta oferta.';
    }
    if (m.contains('request_not_open')) {
      return 'La solicitud ya fue asignada o cancelada.';
    }
    return 'No pudimos aceptar la oferta.${message.isNotEmpty ? ' ($message)' : ''}';
  }
}

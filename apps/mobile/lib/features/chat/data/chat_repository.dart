import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/chat_models.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  Future<List<ChatMessage>> listMessages(String tripId) async {
    try {
      final rows = await _client
          .from('messages')
          .select()
          .eq('trip_id', tripId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true)
          .limit(200);

      return (rows as List)
          .map((r) => ChatMessage.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar el chat.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<ChatMessage> sendMessage({
    required String tripId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Escribe un mensaje.');
    }

    try {
      final row = await _client.rpc(
        'send_trip_message',
        params: {
          'p_trip_id': tripId,
          'p_body': trimmed,
        },
      );
      return ChatMessage.fromJson(_asMap(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure(_sendError(e.message), e);
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

  String _sendError(String message) {
    final m = message.toLowerCase();
    if (m.contains('empty_body')) return 'Escribe un mensaje.';
    if (m.contains('not_allowed')) {
      return 'No puedes escribir en este viaje.';
    }
    return 'No pudimos enviar el mensaje.${message.isNotEmpty ? ' ($message)' : ''}';
  }
}

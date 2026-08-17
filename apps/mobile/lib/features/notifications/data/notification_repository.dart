import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../chat/domain/chat_models.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> listMine({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthFailure('Debes iniciar sesión.');

    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List)
          .map(
            (r) =>
                AppNotification.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar notificaciones.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<int> unreadCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;

    try {
      final rows = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .filter('read_at', 'is', null);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<AppNotification> markRead(String id) async {
    try {
      final row = await _client.rpc(
        'mark_notification_read',
        params: {'p_notification_id': id},
      );
      Map<String, dynamic> map;
      if (row is Map) {
        map = Map<String, dynamic>.from(row);
      } else if (row is List && row.isNotEmpty && row.first is Map) {
        map = Map<String, dynamic>.from(row.first as Map);
      } else {
        throw const UnexpectedFailure('Respuesta inesperada.');
      }
      return AppNotification.fromJson(map);
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos marcar como leída.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.rpc('mark_all_notifications_read');
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos marcar todas como leídas.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }
}

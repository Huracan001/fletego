import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/chat/domain/chat_models.dart';
import 'package:fletego/features/notifications/domain/push_notification_service.dart';

void main() {
  test('ChatMessage parses and detects mine', () {
    final msg = ChatMessage.fromJson({
      'id': 'm1',
      'trip_id': 't1',
      'sender_id': 'u1',
      'body': 'Hola',
      'created_at': '2026-08-17T12:00:00Z',
    });
    expect(msg.isMine('u1'), isTrue);
    expect(msg.isMine('u2'), isFalse);
  });

  test('AppNotification unread and tripId from data', () {
    final n = AppNotification.fromJson({
      'id': 'n1',
      'user_id': 'u1',
      'type': 'chat_message',
      'title': 'Nuevo mensaje',
      'body': 'Hola',
      'data': {'trip_id': 't1'},
      'created_at': '2026-08-17T12:00:00Z',
    });
    expect(n.isUnread, isTrue);
    expect(n.tripId, 't1');
  });

  test('NoOp push service completes', () async {
    const push = NoOpPushNotificationService();
    await push.registerToken('tok');
    await push.dispatch(userId: 'u1', title: 'Hi');
  });
}

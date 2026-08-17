import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/push_notification_service.dart';
import '../../chat/domain/chat_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return NotificationRepository(client);
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  // Swap for FCM/APNs implementation when keys + Edge Function exist.
  return const NoOpPushNotificationService();
});

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unread = 0,
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> items;
  final int unread;
  final bool isLoading;
  final String? error;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unread,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unread: unread ?? this.unread,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        Future.microtask(refresh);
      } else if (next.status == AuthStatus.unauthenticated) {
        state = const NotificationsState();
      }
    });
    Future.microtask(refresh);
    return const NotificationsState(isLoading: true);
  }

  NotificationRepository? get _repo =>
      ref.read(notificationRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final auth = ref.read(authControllerProvider);
    if (repo == null || auth.status != AuthStatus.authenticated) {
      state = const NotificationsState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.listMine();
      final unread = items.where((n) => n.isUnread).length;
      state = NotificationsState(items: items, unread: unread);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar notificaciones.',
      );
    }
  }

  Future<void> markRead(String id) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      await repo.markRead(id);
      await refresh();
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> markAllRead() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      await repo.markAllRead();
      await refresh();
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

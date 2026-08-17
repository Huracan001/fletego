import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return ChatRepository(client);
});

class TripChatState {
  const TripChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  TripChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return TripChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TripChatController extends Notifier<TripChatState> {
  TripChatController(this.tripId);

  final String tripId;

  @override
  TripChatState build() {
    Future.microtask(refresh);
    return const TripChatState(isLoading: true);
  }

  ChatRepository? get _repo => ref.read(chatRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    if (repo == null) {
      state = const TripChatState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await repo.listMessages(tripId);
      state = TripChatState(messages: messages);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar el chat.',
      );
    }
  }

  Future<bool> send(String body) async {
    final repo = _repo;
    if (repo == null) return false;

    state = state.copyWith(isSending: true, clearError: true);
    try {
      final msg = await repo.sendMessage(tripId: tripId, body: body);
      state = state.copyWith(
        messages: [...state.messages, msg],
        isSending: false,
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error: 'No pudimos enviar el mensaje.',
      );
      return false;
    }
  }
}

final tripChatControllerProvider =
    NotifierProvider.family<TripChatController, TripChatState, String>(
      TripChatController.new,
    );

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).profile?.id;
});

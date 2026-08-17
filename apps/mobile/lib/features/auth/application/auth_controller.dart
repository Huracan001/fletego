import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/enums/onboarding_intent.dart';
import '../data/auth_repository.dart';
import '../domain/profile.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return AuthRepository(client);
});

/// High-level auth session for routing.
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.user,
    this.profile,
    this.emailConfirmationPending = false,
    this.message,
  });

  final AuthStatus status;
  final User? user;
  final Profile? profile;
  final bool emailConfirmationPending;
  final String? message;

  bool get needsOnboarding =>
      status == AuthStatus.authenticated &&
      (profile == null || !profile!.hasCompletedOnboarding);

  AuthSessionState copyWith({
    AuthStatus? status,
    User? user,
    Profile? profile,
    bool? emailConfirmationPending,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      emailConfirmationPending:
          emailConfirmationPending ?? this.emailConfirmationPending,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class AuthController extends Notifier<AuthSessionState> {
  StreamSubscription<AuthState>? _sub;

  AuthRepository? get _repo => ref.read(authRepositoryProvider);
  AppConfig get _config => ref.read(appConfigProvider);

  @override
  AuthSessionState build() {
    ref.onDispose(() {
      _sub?.cancel();
    });

    Future.microtask(_bootstrap);
    return const AuthSessionState(status: AuthStatus.unknown);
  }

  Future<void> _bootstrap() async {
    final repo = _repo;
    if (repo == null) {
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
      return;
    }

    _sub = repo.authStateChanges().listen((event) async {
      await _syncFromSession(event.session);
    });

    await _syncFromSession(repo.currentSession);
  }

  Future<void> _syncFromSession(Session? session) async {
    final repo = _repo;
    if (repo == null) {
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
      return;
    }

    if (session == null) {
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final profile = await repo.fetchCurrentProfile();
      state = AuthSessionState(
        status: AuthStatus.authenticated,
        user: session.user,
        profile: profile,
      );
    } catch (e, st) {
      debugPrint('Profile sync failed: $e\n$st');
      state = AuthSessionState(
        status: AuthStatus.authenticated,
        user: session.user,
        message: e is AppFailure ? e.message : 'No pudimos cargar tu perfil.',
      );
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        message: _config.hasSupabase
            ? 'Supabase no está listo.'
            : 'Agrega SUPABASE_ANON_KEY en apps/mobile/.env',
      );
      return false;
    }

    try {
      final response = await repo.signIn(email: email, password: password);
      await _syncFromSession(response.session);
      return response.session != null;
    } on AppFailure catch (e) {
      state = state.copyWith(message: e.message);
      return false;
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    OnboardingIntent? intent,
  }) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        message: 'Agrega SUPABASE_ANON_KEY en apps/mobile/.env',
      );
      return SignUpResult.failed;
    }

    try {
      final response = await repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        intent: intent,
      );

      if (response.session == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          emailConfirmationPending: true,
          message: 'Te enviamos un correo para verificar tu cuenta. Luego inicia sesión.',
        );
        return SignUpResult.emailConfirmationRequired;
      }

      await _syncFromSession(response.session);

      if (intent != null && state.profile?.hasCompletedOnboarding != true) {
        await completeOnboarding(intent);
      }

      return SignUpResult.signedIn;
    } on AppFailure catch (e) {
      state = state.copyWith(message: e.message);
      return SignUpResult.failed;
    }
  }

  Future<bool> completeOnboarding(OnboardingIntent intent) async {
    final repo = _repo;
    if (repo == null) return false;

    try {
      final profile = await repo.completeOnboarding(intent: intent);
      state = state.copyWith(
        profile: profile,
        status: AuthStatus.authenticated,
        clearMessage: true,
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(message: e.message);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        message: 'Agrega SUPABASE_ANON_KEY en apps/mobile/.env',
      );
      return false;
    }

    try {
      await repo.resetPassword(email);
      state = state.copyWith(
        message: 'Si el correo existe, te enviamos instrucciones para restablecer la contraseña.',
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(message: e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    final repo = _repo;
    if (repo == null) {
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      await repo.signOut();
    } on AppFailure catch (e) {
      state = state.copyWith(message: e.message);
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

enum SignUpResult { signedIn, emailConfirmationRequired, failed }

final authControllerProvider =
    NotifierProvider<AuthController, AuthSessionState>(AuthController.new);

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../shared/enums/onboarding_intent.dart';
import '../domain/profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    OnboardingIntent? intent,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (intent != null) 'onboarding_intent': intent.dbValue,
        },
      );
      return response;
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthMessage(e.message), e);
    } catch (e) {
      throw AuthFailure('No pudimos crear tu cuenta. Inténtalo de nuevo.', e);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthMessage(e.message), e);
    } catch (e) {
      throw AuthFailure('No pudimos iniciar sesión. Inténtalo de nuevo.', e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthMessage(e.message), e);
    } catch (e) {
      throw AuthFailure('No pudimos cerrar sesión.', e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthMessage(e.message), e);
    } catch (e) {
      throw AuthFailure(
        'No pudimos enviar el correo de recuperación. Inténtalo de nuevo.',
        e,
      );
    }
  }

  Future<Profile?> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return null;
      return Profile.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos cargar tu perfil. Verifica la conexión.',
        e,
      );
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<Profile> completeOnboarding({
    required OnboardingIntent intent,
    String? fullName,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailure('Debes iniciar sesión para continuar.');
    }

    final isCustomer =
        intent == OnboardingIntent.needTransport ||
        intent == OnboardingIntent.manageTransport;
    final isDriver = intent == OnboardingIntent.offerTransport;

    try {
      final row = await _client
          .from('profiles')
          .update({
            'onboarding_intent': intent.dbValue,
            'is_customer': isCustomer,
            'is_driver': isDriver,
            'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
            if (fullName != null && fullName.trim().isNotEmpty) ...{
              'full_name': fullName.trim(),
              'display_name': fullName.trim(),
            },
          })
          .eq('id', user.id)
          .select()
          .single();

      return Profile.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos guardar tu onboarding.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (lower.contains('password')) {
      return 'La contraseña no cumple los requisitos (mín. 6 caracteres).';
    }
    if (lower.contains('email')) {
      return 'Revisa el correo electrónico ingresado.';
    }
    if (lower.contains('network') || lower.contains('fetch')) {
      return 'No pudimos conectar. Revisa tu conexión.';
    }
    return 'No pudimos completar la autenticación. Inténtalo de nuevo.';
  }
}

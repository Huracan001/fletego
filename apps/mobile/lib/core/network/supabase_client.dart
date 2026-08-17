import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/app_config_provider.dart';

/// Initializes Supabase when credentials exist; otherwise stays null (demo mode).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase) return null;
  return Supabase.instance.client;
});

Future<void> initializeSupabase(AppConfig config) async {
  if (!config.hasSupabase) return;
  await Supabase.initialize(
    url: config.supabaseUrl,
    // publishableKey replaces deprecated anonKey in supabase_flutter 2.17+.
    publishableKey: config.supabaseAnonKey,
  );
}

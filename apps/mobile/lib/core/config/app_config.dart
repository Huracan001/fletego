import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration from dart-defines and optional `.env.example` asset.
/// Never store service-role keys here. Prefer `--dart-define-from-file=.env`.
class AppConfig {
  const AppConfig({
    required this.env,
    required this.demoMode,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.mapsApiKey,
  });

  final AppEnvironment env;
  final bool demoMode;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String mapsApiKey;

  bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT') &&
      supabaseAnonKey != 'paste_your_anon_key_here';

  bool get hasMapsKey =>
      mapsApiKey.isNotEmpty && mapsApiKey != 'your_maps_api_key';

  /// Loads optional example env asset, then overlays compile-time `--dart-define`.
  static Future<AppConfig> load() async {
    await _loadDotEnv();
    return AppConfig.fromEnvironment();
  }

  /// Sync factory for tests / providers after [load] has run.
  factory AppConfig.fromEnvironment() {
    final envName = _read('APP_ENV', defaultValue: 'development');
    final url = _read('SUPABASE_URL');
    final anon = _read('SUPABASE_ANON_KEY');
    final maps = _read('MAPS_API_KEY');
    final demoRaw = _read('DEMO_MODE', defaultValue: '');
    final hasSupabase =
        url.isNotEmpty && anon.isNotEmpty && anon != 'paste_your_anon_key_here';
    final demoMode = demoRaw.isEmpty
        ? !hasSupabase
        : demoRaw.toLowerCase() == 'true';

    return AppConfig(
      env: AppEnvironment.parse(envName),
      demoMode: demoMode || !hasSupabase,
      supabaseUrl: url,
      supabaseAnonKey: anon,
      mapsApiKey: maps,
    );
  }

  static Future<void> _loadDotEnv() async {
    // Prefer real secrets via `--dart-define-from-file=.env` (not bundled).
    // Fall back to example asset for placeholder/demo bootstraps only.
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      // Relies on dart-defines.
    }
  }

  static String _read(String key, {String defaultValue = ''}) {
    const defines = {
      'APP_ENV': String.fromEnvironment('APP_ENV'),
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
      'MAPS_API_KEY': String.fromEnvironment('MAPS_API_KEY'),
      'DEMO_MODE': String.fromEnvironment('DEMO_MODE'),
    };

    final fromDefine = defines[key];
    if (fromDefine != null && fromDefine.isNotEmpty) return fromDefine;

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.maybeGet(key);
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }

    return defaultValue;
  }
}

enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) {
    switch (value.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }
}

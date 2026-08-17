import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/monitoring/crash_reporting_service.dart';
import 'core/network/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();
  final crash = NoOpCrashReportingService();
  final analytics = NoOpAnalyticsService();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crash.recordError(details.exception, details.stack);
  };

  try {
    await initializeSupabase(config);
  } catch (error, stack) {
    await crash.recordError(error, stack);
  }

  await analytics.track(
    AnalyticsEvents.appOpened,
    properties: {
      'env': config.env.name,
      'demo_mode': config.demoMode,
      'has_supabase': config.hasSupabase,
    },
  );

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const FletegoApp(),
    ),
  );
}

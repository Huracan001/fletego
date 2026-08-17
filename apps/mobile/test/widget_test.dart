import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/app.dart';
import 'package:fletego/core/config/app_config.dart';
import 'package:fletego/core/config/app_config_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('unauthenticated flow reaches welcome', (tester) async {
    const config = AppConfig(
      env: AppEnvironment.development,
      demoMode: true,
      supabaseUrl: '',
      supabaseAnonKey: '',
      mapsApiKey: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const FletegoApp(),
      ),
    );

    expect(find.text('FLETEGO'), findsWidgets);

    // Auth bootstrap + redirect to welcome
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('marketplace'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
  });
}

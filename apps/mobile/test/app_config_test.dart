import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/core/config/app_config.dart';

void main() {
  test('AppConfig.fromEnvironment defaults to demo without keys', () {
    final config = AppConfig.fromEnvironment();
    expect(config.hasSupabase, isFalse);
    expect(config.demoMode, isTrue);
    expect(config.supabaseUrl, isEmpty);
  });

  test('AppEnvironment.parse maps known values', () {
    expect(AppEnvironment.parse('production'), AppEnvironment.production);
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('dev'), AppEnvironment.development);
  });
}

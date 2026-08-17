import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/maps/data/map_service_impl.dart';
import 'package:fletego/features/maps/domain/map_service.dart';

void main() {
  const maps = MockMapService();

  test('estimates route with positive distance and eta', () async {
    final estimate = await maps.estimateRoute(
      origin: const GeoPoint(-17.7833, -63.1821),
      destination: const GeoPoint(-17.3895, -66.1568),
    );
    expect(estimate.distanceKm, greaterThan(250));
    expect(estimate.durationMinutes, greaterThan(60));
    expect(estimate.polyline, hasLength(2));
  });

  test('buildTripMap includes origin destination driver markers', () {
    final view = maps.buildTripMap(
      origin: const GeoPoint(-17.78, -63.18),
      destination: const GeoPoint(-17.39, -66.15),
      driver: const GeoPoint(-17.5, -64.5),
    );
    expect(view.markers, hasLength(3));
    expect(view.providerReady, isFalse);
    expect(
      view.markers.any((m) => m.kind == MapMarkerKind.driver),
      isTrue,
    );
  });

  test('GoogleMapService reports provider ready when key present', () {
    final google = GoogleMapService('test-key');
    expect(google.isProviderReady, isTrue);
  });
}

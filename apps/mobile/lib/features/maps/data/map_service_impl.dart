import 'dart:math' as math;

import '../domain/map_service.dart';

/// Deterministic mock: haversine distance + ~55 km/h average for BO roads.
class MockMapService implements MapService {
  const MockMapService();

  static const _avgSpeedKmh = 55.0;

  @override
  bool get isProviderReady => false;

  @override
  Future<RouteEstimate> estimateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    final km = distanceKm(origin, destination);
    final minutes = math.max(1, (km / _avgSpeedKmh * 60).round());
    return RouteEstimate(
      distanceKm: km,
      durationMinutes: minutes,
      polyline: [origin, destination],
    );
  }

  @override
  TripMapView buildTripMap({
    GeoPoint? origin,
    GeoPoint? destination,
    GeoPoint? driver,
    String? originLabel,
    String? destinationLabel,
    RouteEstimate? route,
  }) {
    final markers = <MapMarker>[
      if (origin != null)
        MapMarker(
          point: origin,
          label: originLabel ?? 'Origen',
          kind: MapMarkerKind.origin,
        ),
      if (destination != null)
        MapMarker(
          point: destination,
          label: destinationLabel ?? 'Destino',
          kind: MapMarkerKind.destination,
        ),
      if (driver != null)
        MapMarker(
          point: driver,
          label: 'Conductor',
          kind: MapMarkerKind.driver,
        ),
    ];
    return TripMapView(
      markers: markers,
      route: route,
      driverPoint: driver,
      providerReady: false,
    );
  }

  static double distanceKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

/// Placeholder for Google Maps / Directions when MAPS_API_KEY is set.
/// For now delegates to mock math; UI still uses [FletegoMap] schematic.
class GoogleMapService implements MapService {
  GoogleMapService(this.apiKey);

  final String apiKey;
  final _mock = const MockMapService();

  @override
  bool get isProviderReady => apiKey.isNotEmpty;

  @override
  Future<RouteEstimate> estimateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) {
    // Wire Directions API later; keep architecture stable.
    return _mock.estimateRoute(origin: origin, destination: destination);
  }

  @override
  TripMapView buildTripMap({
    GeoPoint? origin,
    GeoPoint? destination,
    GeoPoint? driver,
    String? originLabel,
    String? destinationLabel,
    RouteEstimate? route,
  }) {
    final view = _mock.buildTripMap(
      origin: origin,
      destination: destination,
      driver: driver,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      route: route,
    );
    return TripMapView(
      markers: view.markers,
      route: view.route,
      driverPoint: view.driverPoint,
      providerReady: true,
    );
  }
}

import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}

class RouteEstimate extends Equatable {
  const RouteEstimate({
    required this.distanceKm,
    required this.durationMinutes,
    this.polyline = const [],
  });

  final double distanceKm;
  final int durationMinutes;
  final List<GeoPoint> polyline;

  String get distanceLabel =>
      distanceKm >= 100
          ? '${distanceKm.toStringAsFixed(0)} km'
          : '${distanceKm.toStringAsFixed(1)} km';

  String get etaLabel {
    if (durationMinutes < 60) return '~$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '~${h}h' : '~${h}h ${m}m';
  }

  @override
  List<Object?> get props => [distanceKm, durationMinutes];
}

class MapMarker extends Equatable {
  const MapMarker({
    required this.point,
    required this.label,
    this.kind = MapMarkerKind.generic,
  });

  final GeoPoint point;
  final String label;
  final MapMarkerKind kind;

  @override
  List<Object?> get props => [point, label, kind];
}

enum MapMarkerKind { origin, destination, driver, generic }

class TripMapView extends Equatable {
  const TripMapView({
    required this.markers,
    this.route,
    this.driverPoint,
    this.providerReady = false,
  });

  final List<MapMarker> markers;
  final RouteEstimate? route;
  final GeoPoint? driverPoint;
  final bool providerReady;

  @override
  List<Object?> get props => [markers, route, driverPoint, providerReady];
}

/// Provider-agnostic maps API. Swap Mock ↔ Google without UI changes.
abstract class MapService {
  bool get isProviderReady;

  Future<RouteEstimate> estimateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });

  TripMapView buildTripMap({
    GeoPoint? origin,
    GeoPoint? destination,
    GeoPoint? driver,
    String? originLabel,
    String? destinationLabel,
    RouteEstimate? route,
  });
}

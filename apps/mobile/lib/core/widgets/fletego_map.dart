import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../../features/maps/domain/map_service.dart';

/// Schematic map plane — works without MAPS_API_KEY.
/// When a real provider is wired, replace the painter body, keep this API.
class FletegoMap extends StatelessWidget {
  const FletegoMap({
    super.key,
    required this.view,
    this.height = 220,
  });

  final TripMapView view;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FletegoRadii.md),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _TripMapPainter(view: view),
            ),
            Positioned(
              left: FletegoSpacing.sm,
              bottom: FletegoSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FletegoColors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  view.providerReady
                      ? 'Mapa (proveedor listo)'
                      : 'Mapa esquemático · sin MAPS_API_KEY',
                  style: FletegoTypography.textTheme.bodySmall,
                ),
              ),
            ),
            if (view.route != null)
              Positioned(
                right: FletegoSpacing.sm,
                top: FletegoSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: FletegoColors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FletegoColors.border),
                  ),
                  child: Text(
                    '${view.route!.distanceLabel} · ${view.route!.etaLabel}',
                    style: FletegoTypography.textTheme.labelLarge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripMapPainter extends CustomPainter {
  _TripMapPainter({required this.view});

  final TripMapView view;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8EEF8);
    canvas.drawRect(Offset.zero & size, bg);

    // Soft grid
    final grid = Paint()
      ..color = const Color(0xFFD0DAEA)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = view.markers.map((m) => m.point).toList();
    if (points.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Sin coordenadas de ruta',
          style: FletegoTypography.textTheme.bodyMedium?.copyWith(
            color: FletegoColors.navy,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 24);
      tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
      );
      return;
    }

    double minLat = points.first.lat;
    double maxLat = points.first.lat;
    double minLng = points.first.lng;
    double maxLng = points.first.lng;
    for (final p in points) {
      minLat = minLat < p.lat ? minLat : p.lat;
      maxLat = maxLat > p.lat ? maxLat : p.lat;
      minLng = minLng < p.lng ? minLng : p.lng;
      maxLng = maxLng > p.lng ? maxLng : p.lng;
    }
    if ((maxLat - minLat).abs() < 0.01) {
      minLat -= 0.05;
      maxLat += 0.05;
    }
    if ((maxLng - minLng).abs() < 0.01) {
      minLng -= 0.05;
      maxLng += 0.05;
    }

    Offset project(GeoPoint p) {
      final pad = 28.0;
      final x =
          pad +
          (p.lng - minLng) / (maxLng - minLng) * (size.width - pad * 2);
      final y =
          pad +
          (1 - (p.lat - minLat) / (maxLat - minLat)) * (size.height - pad * 2);
      return Offset(x, y);
    }

    final origin = view.markers
        .where((m) => m.kind == MapMarkerKind.origin)
        .map((m) => m.point)
        .firstOrNull;
    final dest = view.markers
        .where((m) => m.kind == MapMarkerKind.destination)
        .map((m) => m.point)
        .firstOrNull;

    if (origin != null && dest != null) {
      final routePaint = Paint()
        ..color = FletegoColors.primary.withValues(alpha: 0.7)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(project(origin), project(dest), routePaint);
    }

    for (final marker in view.markers) {
      final o = project(marker.point);
      final color = switch (marker.kind) {
        MapMarkerKind.origin => FletegoColors.navy,
        MapMarkerKind.destination => FletegoColors.success,
        MapMarkerKind.driver => FletegoColors.primary,
        MapMarkerKind.generic => FletegoColors.navy,
      };
      canvas.drawCircle(o, 8, Paint()..color = color);
      canvas.drawCircle(
        o,
        8,
        Paint()
          ..color = FletegoColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TripMapPainter oldDelegate) =>
      oldDelegate.view != view;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../core/widgets/fletego_map.dart';
import '../../trips/application/trips_controller.dart';
import '../application/tracking_controller.dart';
import '../domain/map_service.dart';

class TripTrackingPanel extends ConsumerWidget {
  const TripTrackingPanel({
    super.key,
    required this.tripId,
    required this.isDriver,
  });

  final String tripId;
  final bool isDriver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripDetailControllerProvider(tripId)).trip;
    final tracking = ref.watch(tripTrackingControllerProvider(tripId));
    final maps = ref.watch(mapServiceProvider);

    if (trip == null || trip.status.isTerminal) {
      return const SizedBox.shrink();
    }

    final origin = (trip.originLat != null && trip.originLng != null)
        ? GeoPoint(trip.originLat!, trip.originLng!)
        : null;
    final dest = (trip.destinationLat != null && trip.destinationLng != null)
        ? GeoPoint(trip.destinationLat!, trip.destinationLng!)
        : null;
    GeoPoint? driver;
    if (tracking.latest != null) {
      driver = GeoPoint(tracking.latest!.lat, tracking.latest!.lng);
    } else if (trip.currentLat != null && trip.currentLng != null) {
      driver = GeoPoint(trip.currentLat!, trip.currentLng!);
    }

    final view = maps.buildTripMap(
      origin: origin,
      destination: dest,
      driver: driver,
      originLabel: trip.originCity,
      destinationLabel: trip.destinationCity,
      route: tracking.route,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ruta y tracking', style: FletegoTypography.textTheme.titleMedium),
        const SizedBox(height: FletegoSpacing.sm),
        FletegoMap(view: view),
        if (tracking.route != null) ...[
          const SizedBox(height: FletegoSpacing.sm),
          Text(
            'Estimado: ${tracking.route!.distanceLabel} · ${tracking.route!.etaLabel}',
            style: FletegoTypography.textTheme.bodyMedium,
          ),
        ],
        if (tracking.latest != null) ...[
          const SizedBox(height: 4),
          Text(
            'Última ubicación: ${_fmt(tracking.latest!.recordedAt)}',
            style: FletegoTypography.textTheme.bodySmall,
          ),
        ],
        if (tracking.error != null) ...[
          const SizedBox(height: FletegoSpacing.sm),
          Text(tracking.error!, style: FletegoTypography.textTheme.bodySmall),
        ],
        if (isDriver) ...[
          const SizedBox(height: FletegoSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Compartir mi ubicación en este viaje'),
            subtitle: const Text(
              'Solo mientras el viaje esté activo. Sin tracking en segundo plano.',
            ),
            value: tracking.consentGiven,
            onChanged: (v) => ref
                .read(tripTrackingControllerProvider(tripId).notifier)
                .setConsent(v),
          ),
          FletegoButton(
            label: tracking.isSharing
                ? 'Enviando…'
                : 'Actualizar ubicación (demo)',
            isLoading: tracking.isSharing,
            onPressed: !tracking.consentGiven || tracking.isSharing
                ? null
                : () async {
                    final ok = await ref
                        .read(tripTrackingControllerProvider(tripId).notifier)
                        .shareLocation(simulateNearOrigin: true);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Ubicación compartida'
                              : (ref
                                        .read(
                                          tripTrackingControllerProvider(
                                            tripId,
                                          ),
                                        )
                                        .error ??
                                    'Error'),
                        ),
                      ),
                    );
                  },
          ),
        ],
        const SizedBox(height: FletegoSpacing.lg),
      ],
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}:'
        '${l.second.toString().padLeft(2, '0')}';
  }
}

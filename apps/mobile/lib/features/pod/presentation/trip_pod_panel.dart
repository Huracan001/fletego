import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/trip_status.dart';
import '../../trips/application/trips_controller.dart';
import '../application/pod_controller.dart';

class TripPodPanel extends ConsumerWidget {
  const TripPodPanel({
    super.key,
    required this.tripId,
    required this.isDriver,
  });

  final String tripId;
  final bool isDriver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripDetailControllerProvider(tripId)).trip;
    final state = ref.watch(tripPodControllerProvider(tripId));
    if (trip == null) return const SizedBox.shrink();

    final canPickup = _canShowPickup(trip.status);
    final canPod = _canShowPod(trip.status);
    if (!canPickup && !canPod && state.pickup == null && state.pod == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidencias / POD',
          style: FletegoTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: FletegoSpacing.sm),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
            child: Text(state.error!, style: FletegoTypography.textTheme.bodySmall),
          ),
        if (canPickup || state.pickup != null) ...[
          _PickupSection(
            tripId: tripId,
            isDriver: isDriver,
            canEdit: isDriver && canPickup,
          ),
          const SizedBox(height: FletegoSpacing.md),
        ],
        if (canPod || state.pod != null)
          _PodSection(
            tripId: tripId,
            isDriver: isDriver,
            canEdit: isDriver && canPod,
          ),
        const SizedBox(height: FletegoSpacing.lg),
      ],
    );
  }

  bool _canShowPickup(TripStatus status) => switch (status) {
    TripStatus.arrivedAtPickup ||
    TripStatus.cargoPickedUp ||
    TripStatus.inTransit ||
    TripStatus.arrivedAtDestination ||
    TripStatus.delivering ||
    TripStatus.delivered ||
    TripStatus.completed => true,
    _ => false,
  };

  bool _canShowPod(TripStatus status) => switch (status) {
    TripStatus.arrivedAtDestination ||
    TripStatus.delivering ||
    TripStatus.delivered ||
    TripStatus.completed => true,
    _ => false,
  };
}

class _PickupSection extends ConsumerStatefulWidget {
  const _PickupSection({
    required this.tripId,
    required this.isDriver,
    required this.canEdit,
  });

  final String tripId;
  final bool isDriver;
  final bool canEdit;

  @override
  ConsumerState<_PickupSection> createState() => _PickupSectionState();
}

class _PickupSectionState extends ConsumerState<_PickupSection> {
  final _notes = TextEditingController();
  var _demoPhoto = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripPodControllerProvider(widget.tripId));
    final existing = state.pickup;

    return FletegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recogida', style: FletegoTypography.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (existing != null) ...[
            Text(
              'Registrada ${_fmt(existing.capturedAt)}',
              style: FletegoTypography.textTheme.bodySmall,
            ),
            if (existing.notes != null && existing.notes!.isNotEmpty)
              Text(existing.notes!, style: FletegoTypography.textTheme.bodyMedium),
            if (existing.photoPaths.isNotEmpty)
              Text(
                '${existing.photoPaths.length} foto(s)',
                style: FletegoTypography.textTheme.bodySmall,
              ),
            if (existing.lat != null && existing.lng != null)
              Text(
                'GPS: ${existing.lat!.toStringAsFixed(4)}, ${existing.lng!.toStringAsFixed(4)}',
                style: FletegoTypography.textTheme.bodySmall,
              ),
          ] else if (!widget.canEdit)
            Text(
              'Aún sin evidencia de recogida.',
              style: FletegoTypography.textTheme.bodyMedium,
            ),
          if (widget.canEdit) ...[
            const SizedBox(height: FletegoSpacing.sm),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas de recogida',
                border: OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Adjuntar foto demo'),
              value: _demoPhoto,
              onChanged: (v) => setState(() => _demoPhoto = v ?? false),
            ),
            FletegoButton(
              label: existing == null
                  ? 'Registrar recogida'
                  : 'Actualizar recogida',
              isLoading: state.isSaving,
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final trip = ref
                          .read(tripDetailControllerProvider(widget.tripId))
                          .trip;
                      final ok = await ref
                          .read(tripPodControllerProvider(widget.tripId).notifier)
                          .savePickup(
                            notes: _notes.text.trim().isEmpty
                                ? null
                                : _notes.text.trim(),
                            photoPaths: _demoPhoto
                                ? [
                                    'pod-documents/${widget.tripId}/pickup_demo.jpg',
                                  ]
                                : const [],
                            lat: trip?.originLat ?? trip?.currentLat,
                            lng: trip?.originLng ?? trip?.currentLng,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Recogida registrada'
                                : (ref
                                          .read(
                                            tripPodControllerProvider(
                                              widget.tripId,
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
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

class _PodSection extends ConsumerStatefulWidget {
  const _PodSection({
    required this.tripId,
    required this.isDriver,
    required this.canEdit,
  });

  final String tripId;
  final bool isDriver;
  final bool canEdit;

  @override
  ConsumerState<_PodSection> createState() => _PodSectionState();
}

class _PodSectionState extends ConsumerState<_PodSection> {
  final _name = TextEditingController();
  final _idRef = TextEditingController();
  final _notes = TextEditingController();
  var _demoPhoto = true;
  var _signed = true;

  @override
  void dispose() {
    _name.dispose();
    _idRef.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripPodControllerProvider(widget.tripId));
    final existing = state.pod;

    return FletegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prueba de entrega (POD)',
            style: FletegoTypography.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (existing != null) ...[
            Text(
              'Receptor: ${existing.recipientName}',
              style: FletegoTypography.textTheme.bodyMedium,
            ),
            if (existing.recipientIdRef != null)
              Text(
                'Doc: ${existing.recipientIdRef}',
                style: FletegoTypography.textTheme.bodySmall,
              ),
            Text(
              'Capturado ${_fmt(existing.capturedAt)}'
              '${existing.hasSignature ? ' · Con firma' : ''}',
              style: FletegoTypography.textTheme.bodySmall,
            ),
            if (existing.photoPaths.isNotEmpty)
              Text(
                '${existing.photoPaths.length} foto(s)',
                style: FletegoTypography.textTheme.bodySmall,
              ),
            if (existing.lat != null && existing.lng != null)
              Text(
                'GPS: ${existing.lat!.toStringAsFixed(4)}, ${existing.lng!.toStringAsFixed(4)}',
                style: FletegoTypography.textTheme.bodySmall,
              ),
          ] else if (!widget.canEdit)
            Text(
              'Aún sin POD.',
              style: FletegoTypography.textTheme.bodyMedium,
            ),
          if (widget.canEdit) ...[
            const SizedBox(height: FletegoSpacing.sm),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre del receptor *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: FletegoSpacing.sm),
            TextField(
              controller: _idRef,
              decoration: const InputDecoration(
                labelText: 'CI / referencia (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: FletegoSpacing.sm),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Foto de entrega (demo)'),
              value: _demoPhoto,
              onChanged: (v) => setState(() => _demoPhoto = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Firma / conformidad del receptor'),
              value: _signed,
              onChanged: (v) => setState(() => _signed = v ?? false),
            ),
            FletegoButton(
              label: existing == null
                  ? 'Registrar POD y marcar entregado'
                  : 'Actualizar POD',
              isLoading: state.isSaving,
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final trip = ref
                          .read(tripDetailControllerProvider(widget.tripId))
                          .trip;
                      final ok = await ref
                          .read(tripPodControllerProvider(widget.tripId).notifier)
                          .savePod(
                            recipientName: _name.text,
                            recipientIdRef: _idRef.text.trim().isEmpty
                                ? null
                                : _idRef.text.trim(),
                            notes: _notes.text.trim().isEmpty
                                ? null
                                : _notes.text.trim(),
                            photoPaths: _demoPhoto
                                ? [
                                    'pod-documents/${widget.tripId}/delivery_demo.jpg',
                                  ]
                                : const [],
                            signaturePath: _signed
                                ? 'pod-documents/${widget.tripId}/signature_demo.png'
                                : null,
                            lat: trip?.destinationLat ?? trip?.currentLat,
                            lng: trip?.destinationLng ?? trip?.currentLng,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'POD guardado'
                                : (ref
                                          .read(
                                            tripPodControllerProvider(
                                              widget.tripId,
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
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

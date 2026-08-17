import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/trip_status.dart';
import '../../auth/application/auth_controller.dart';
import '../../maps/presentation/trip_tracking_panel.dart';
import '../../pod/presentation/trip_pod_panel.dart';
import '../../ratings/presentation/trip_ratings_panel.dart';
import '../application/trips_controller.dart';
import '../domain/trip_state_service.dart';

class TripDetailPage extends ConsumerWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  static const _machine = TripStateService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripDetailControllerProvider(tripId));
    final uid = ref.watch(authControllerProvider).profile?.id;
    final trip = state.trip;
    final isDriver = trip != null && uid != null && trip.driverId == uid;
    final isCustomer = trip != null && uid != null && trip.customerId == uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip?.routeLabel ?? 'Viaje'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.myTrips);
            }
          },
        ),
        actions: [
          if (trip != null && (isDriver || isCustomer))
            IconButton(
              tooltip: 'Chat',
              onPressed: () => context.push(
                AppRoutes.tripChat,
                extra: {'tripId': tripId, 'routeLabel': trip.routeLabel},
              ),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(tripDetailControllerProvider(tripId).notifier).refresh(),
          child: state.isLoading && trip == null
              ? const FletegoLoadingState()
              : state.error != null && trip == null
              ? FletegoErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(tripDetailControllerProvider(tripId).notifier)
                      .refresh(),
                )
              : trip == null
              ? const FletegoEmptyState(
                  title: 'Viaje no encontrado',
                  message: 'Puede haber sido archivado.',
                )
              : ListView(
                  padding: const EdgeInsets.all(FletegoSpacing.lg),
                  children: [
                    FletegoStatusBadge(
                      label: trip.status.labelEs,
                      tone: trip.status.isTerminal
                          ? (trip.status == TripStatus.completed
                                ? FletegoBadgeTone.success
                                : FletegoBadgeTone.neutral)
                          : FletegoBadgeTone.primary,
                    ),
                    const SizedBox(height: FletegoSpacing.md),
                    Text(
                      trip.routeLabel,
                      style: FletegoTypography.textTheme.headlineSmall,
                    ),
                    if (trip.cargoType != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        trip.cargoType!.labelEs,
                        style: FletegoTypography.textTheme.bodyMedium,
                      ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: FletegoSpacing.sm),
                      Text(
                        state.error!,
                        style: FletegoTypography.textTheme.bodySmall?.copyWith(
                          color: FletegoColors.navy,
                        ),
                      ),
                    ],
                    if (isDriver || isCustomer) ...[
                      const SizedBox(height: FletegoSpacing.lg),
                      FletegoButton(
                        label: 'Abrir chat del viaje',
                        onPressed: () => context.push(
                          AppRoutes.tripChat,
                          extra: {
                            'tripId': tripId,
                            'routeLabel': trip.routeLabel,
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: FletegoSpacing.lg),
                    TripTrackingPanel(tripId: tripId, isDriver: isDriver),
                    TripPodPanel(tripId: tripId, isDriver: isDriver),
                    TripRatingsPanel(
                      tripId: tripId,
                      isDriver: isDriver,
                      isCustomer: isCustomer,
                    ),
                    if (isDriver) ..._driverActions(context, ref, state),
                    if (isCustomer) ..._customerActions(context, ref, state),
                    if ((isDriver || isCustomer) &&
                        _machine.canCancel(trip.status)) ...[
                      const SizedBox(height: FletegoSpacing.sm),
                      FletegoSecondaryButton(
                        label: 'Cancelar viaje',
                        onPressed: state.isUpdating
                            ? null
                            : () => _confirmCancel(context, ref),
                      ),
                    ],
                    if ((isDriver || isCustomer) && trip.status.isTerminal) ...[
                      const SizedBox(height: FletegoSpacing.sm),
                      TextButton(
                        onPressed: state.isUpdating
                            ? null
                            : () async {
                                final repo = ref.read(tripRepositoryProvider);
                                if (repo == null) return;
                                try {
                                  await repo.softDelete(trip.id);
                                  if (!context.mounted) return;
                                  ref
                                      .read(
                                        tripsListControllerProvider.notifier,
                                      )
                                      .refresh();
                                  context.go(AppRoutes.myTrips);
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No se pudo archivar'),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Archivar viaje'),
                      ),
                    ],
                    const SizedBox(height: FletegoSpacing.xl),
                    Text(
                      'Historial',
                      style: FletegoTypography.textTheme.titleMedium,
                    ),
                    const SizedBox(height: FletegoSpacing.sm),
                    if (state.history.isEmpty)
                      Text(
                        'Sin eventos aún.',
                        style: FletegoTypography.textTheme.bodyMedium,
                      )
                    else
                      ...state.history.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: FletegoSpacing.sm,
                          ),
                          child: FletegoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.toStatus.labelEs,
                                  style: FletegoTypography.textTheme.titleSmall,
                                ),
                                if (h.fromStatus != null)
                                  Text(
                                    'Desde: ${h.fromStatus!.labelEs}',
                                    style:
                                        FletegoTypography.textTheme.bodySmall,
                                  ),
                                if (h.note != null && h.note!.isNotEmpty)
                                  Text(
                                    h.note!,
                                    style:
                                        FletegoTypography.textTheme.bodyMedium,
                                  ),
                                Text(
                                  _formatWhen(h.createdAt),
                                  style: FletegoTypography.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _driverActions(
    BuildContext context,
    WidgetRef ref,
    TripDetailState state,
  ) {
    final trip = state.trip!;
    final next = _machine.nextDriverStep(trip.status);
    final widgets = <Widget>[];

    if (next != null) {
      widgets.add(
        FletegoButton(
          label: _machine.actionLabelEs(next),
          isLoading: state.isUpdating,
          onPressed: state.isUpdating
              ? null
              : () async {
                  final ok = await ref
                      .read(tripDetailControllerProvider(tripId).notifier)
                      .advanceNextDriverStep();
                  if (!context.mounted) return;
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Estado: ${_machine.actionLabelEs(next)}',
                        ),
                      ),
                    );
                  }
                },
        ),
      );
    }

    if (_machine.canTransition(trip.status, TripStatus.completed)) {
      widgets.add(const SizedBox(height: FletegoSpacing.sm));
      widgets.add(
        FletegoButton(
          label: 'Completar viaje',
          isLoading: state.isUpdating,
          onPressed: state.isUpdating
              ? null
              : () => ref
                    .read(tripDetailControllerProvider(tripId).notifier)
                    .completeTrip(),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _customerActions(
    BuildContext context,
    WidgetRef ref,
    TripDetailState state,
  ) {
    final trip = state.trip!;
    if (!_machine.canTransition(trip.status, TripStatus.completed)) {
      return [
        Text(
          'El conductor irá actualizando el estado del viaje.',
          style: FletegoTypography.textTheme.bodyMedium,
        ),
      ];
    }

    return [
      FletegoButton(
        label: 'Confirmar y completar',
        isLoading: state.isUpdating,
        onPressed: state.isUpdating
            ? null
            : () async {
                final ok = await ref
                    .read(tripDetailControllerProvider(tripId).notifier)
                    .completeTrip();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Viaje completado' : (state.error ?? 'Error'),
                    ),
                  ),
                );
              },
      ),
    ];
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_CancelResult>(
      context: context,
      builder: (ctx) => const _CancelTripDialog(),
    );
    if (result == null || !result.confirmed || !context.mounted) return;

    final success = await ref
        .read(tripDetailControllerProvider(tripId).notifier)
        .cancel(reason: result.reason);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Viaje cancelado' : 'No se pudo cancelar'),
      ),
    );
  }

  String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _CancelResult {
  const _CancelResult({required this.confirmed, this.reason});
  final bool confirmed;
  final String? reason;
}

class _CancelTripDialog extends StatefulWidget {
  const _CancelTripDialog();

  @override
  State<_CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<_CancelTripDialog> {
  late final TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar viaje'),
      content: TextField(
        controller: _reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Motivo (opcional)',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _CancelResult(confirmed: false)),
          child: const Text('Volver'),
        ),
        TextButton(
          onPressed: () {
            final text = _reasonCtrl.text.trim();
            Navigator.pop(
              context,
              _CancelResult(
                confirmed: true,
                reason: text.isEmpty ? null : text,
              ),
            );
          },
          child: const Text('Cancelar viaje'),
        ),
      ],
    );
  }
}

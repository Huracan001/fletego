import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/trip_status.dart';
import '../application/trips_controller.dart';
import '../domain/trip_models.dart';

class MyTripsPage extends ConsumerWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripsListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis viajes (${state.items.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(tripsListControllerProvider.notifier).refresh(),
          child: state.isLoading
              ? const FletegoLoadingState()
              : state.error != null && state.items.isEmpty
              ? FletegoErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(tripsListControllerProvider.notifier)
                      .refresh(),
                )
              : state.items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    FletegoEmptyState(
                      title: 'Sin viajes',
                      message:
                          'Cuando aceptes una oferta o te asignen un flete, aparecerá aquí.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(FletegoSpacing.lg),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FletegoSpacing.sm),
                  itemBuilder: (context, index) {
                    final trip = state.items[index];
                    return _TripListCard(trip: trip);
                  },
                ),
        ),
      ),
    );
  }
}

class _TripListCard extends StatelessWidget {
  const _TripListCard({required this.trip});

  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    return FletegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.routeLabel,
                  style: FletegoTypography.textTheme.titleMedium,
                ),
              ),
              FletegoStatusBadge(
                label: trip.status.labelEs,
                tone: switch (trip.status) {
                  TripStatus.completed => FletegoBadgeTone.success,
                  TripStatus.cancelled || TripStatus.failed =>
                    FletegoBadgeTone.neutral,
                  _ => FletegoBadgeTone.primary,
                },
              ),
            ],
          ),
          if (trip.cargoType != null) ...[
            const SizedBox(height: 6),
            Text(
              trip.cargoType!.labelEs,
              style: FletegoTypography.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: FletegoSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FletegoSecondaryButton(
                  label: 'Ver viaje',
                  onPressed: () => context.push(
                    AppRoutes.tripDetail,
                    extra: trip.id,
                  ),
                ),
              ),
              const SizedBox(width: FletegoSpacing.sm),
              Expanded(
                child: FletegoButton(
                  label: 'Chat',
                  onPressed: () => context.push(
                    AppRoutes.tripChat,
                    extra: {
                      'tripId': trip.id,
                      'routeLabel': trip.routeLabel,
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

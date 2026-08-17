import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/cargo_enums.dart';
import '../../trips/application/trips_controller.dart';
import '../application/cargo_wizard_controller.dart';
import '../domain/cargo_models.dart';

class MyRequestsPage extends ConsumerWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRequestsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.requestTruck),
        label: const Text('Nueva'),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(myRequestsControllerProvider.notifier).refresh(),
          child: state.isLoading
              ? const FletegoLoadingState()
              : state.error != null && state.items.isEmpty
              ? FletegoErrorState(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(myRequestsControllerProvider.notifier).refresh(),
                )
              : state.items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    FletegoEmptyState(
                      title: 'Sin solicitudes',
                      message: 'Solicita un camión para empezar.',
                      actionLabel: 'Solicitar un camión',
                      onAction: () => context.push(AppRoutes.requestTruck),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(FletegoSpacing.lg),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FletegoSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final route =
                        '${item.originCity} → ${item.destinationCity}';
                    final assigned = item.status == RequestStatus.assigned;
                    return FletegoCard(
                      onTap: () => _openRequest(context, ref, item, route),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route,
                                  style:
                                      FletegoTypography.textTheme.titleMedium,
                                ),
                              ),
                              FletegoStatusBadge(
                                label: item.status.labelEs,
                                tone: switch (item.status) {
                                  RequestStatus.matching ||
                                  RequestStatus.offered =>
                                    FletegoBadgeTone.primary,
                                  RequestStatus.assigned =>
                                    FletegoBadgeTone.success,
                                  _ => FletegoBadgeTone.neutral,
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.cargoType.labelEs,
                            style: FletegoTypography.textTheme.bodyMedium,
                          ),
                          if (item.totalWeightKg != null)
                            Text(
                              '${item.totalWeightKg!.toStringAsFixed(0)} kg',
                              style: FletegoTypography.metric(fontSize: 20),
                            ),
                          if (item.vehicleTypeName != null)
                            Text(
                              item.vehicleTypeName!,
                              style: FletegoTypography.textTheme.bodySmall,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            assigned ? 'Ver viaje →' : 'Ver ofertas →',
                            style: FletegoTypography.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _openRequest(
    BuildContext context,
    WidgetRef ref,
    CargoRequestSummary item,
    String route,
  ) async {
    if (item.status == RequestStatus.assigned) {
      var trips = ref.read(tripsListControllerProvider).items;
      var trip = trips.where((t) => t.requestId == item.id).firstOrNull;
      if (trip == null) {
        await ref.read(tripsListControllerProvider.notifier).refresh();
        if (!context.mounted) return;
        trips = ref.read(tripsListControllerProvider).items;
        trip = trips.where((t) => t.requestId == item.id).firstOrNull;
      }
      if (!context.mounted) return;
      if (trip != null) {
        context.push(AppRoutes.tripDetail, extra: trip.id);
      } else {
        context.push(AppRoutes.myTrips);
      }
      return;
    }

    context.push(
      AppRoutes.requestOffers,
      extra: {
        'requestId': item.id,
        'routeLabel': route,
      },
    );
  }
}

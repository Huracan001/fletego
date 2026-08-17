import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../auth/application/auth_controller.dart';
import '../../trips/application/trips_controller.dart';
import '../../vehicles/application/driver_fleet_controller.dart';
import '../../../shared/enums/trip_status.dart';
import '../../../shared/enums/vehicle_enums.dart';

class DriverHomePage extends ConsumerWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).profile?.greetingName;
    final hello = (name == null || name.isEmpty) ? 'Hola' : 'Hola, $name';
    final fleet = ref.watch(driverFleetControllerProvider);
    final trips = ref.watch(tripsListControllerProvider);
    final available = fleet.isAvailable;
    final active = trips.activeTrip;
    final activeCount = trips.items.where((t) => t.status.isActive).length;
    final totalCount = trips.items.length;
    final completedCount =
        trips.items.where((t) => t.status == TripStatus.completed).length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(driverFleetControllerProvider.notifier).refresh(),
              ref.read(tripsListControllerProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(FletegoSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hello,
                      style: FletegoTypography.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notificaciones',
                    onPressed: () => context.push(AppRoutes.notifications),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              const SizedBox(height: FletegoSpacing.xs),
              Text(
                'Publica tu disponibilidad y encuentra cargas compatibles.',
                style: FletegoTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: FletegoSpacing.md),
              FletegoStatusBadge(
                label: available
                    ? AvailabilityStatus.available.labelEs
                    : AvailabilityStatus.offline.labelEs,
                tone: available
                    ? FletegoBadgeTone.success
                    : FletegoBadgeTone.neutral,
              ),
              const SizedBox(height: FletegoSpacing.lg),
              FletegoButton(
                label: 'Ver cargas disponibles',
                onPressed: () => context.push(AppRoutes.marketplace),
              ),
              const SizedBox(height: FletegoSpacing.sm),
              FletegoSecondaryButton(
                label: available
                    ? 'Gestionar disponibilidad'
                    : 'Estoy disponible',
                onPressed: () => context.push(AppRoutes.availability),
              ),
              const SizedBox(height: FletegoSpacing.sm),
              FletegoSecondaryButton(
                label: 'Mis viajes ($totalCount)',
                onPressed: () => context.push(AppRoutes.myTrips),
              ),
              const SizedBox(height: FletegoSpacing.sm),
              FletegoSecondaryButton(
                label: 'Mis vehículos (${fleet.vehicles.length})',
                onPressed: () => context.push(AppRoutes.vehicles),
              ),
              const SizedBox(height: FletegoSpacing.sm),
              TextButton(
                onPressed: () => context.push(AppRoutes.driverProfile),
                child: const Text('Perfil de conductor'),
              ),
              const SizedBox(height: FletegoSpacing.xl),
              Text(
                'Viaje activo',
                style: FletegoTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: FletegoSpacing.sm),
              if (active != null) ...[
                FletegoCard(
                  onTap: () => context.push(
                    AppRoutes.tripDetail,
                    extra: active.id,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.routeLabel,
                        style: FletegoTypography.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      FletegoStatusBadge(
                        label: active.status.labelEs,
                        tone: FletegoBadgeTone.primary,
                      ),
                      const SizedBox(height: FletegoSpacing.sm),
                      FletegoButton(
                        label: 'Abrir chat',
                        onPressed: () => context.push(
                          AppRoutes.tripChat,
                          extra: {
                            'tripId': active.id,
                            'routeLabel': active.routeLabel,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const FletegoEmptyState(
                  title: 'Sin viaje activo',
                  message:
                      'Cuando acepten tu oferta, el viaje aparecerá aquí. También en Mis viajes.',
                ),
              const SizedBox(height: FletegoSpacing.xl),
              Text('Resumen', style: FletegoTypography.textTheme.titleMedium),
              const SizedBox(height: FletegoSpacing.sm),
              FletegoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${fleet.vehicles.length}',
                            style: FletegoTypography.metric(),
                          ),
                          Text(
                            'Vehículos',
                            style: FletegoTypography.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: FletegoColors.border,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: FletegoSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$activeCount',
                              style: FletegoTypography.metric(),
                            ),
                            Text(
                              'Activos',
                              style: FletegoTypography.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: FletegoColors.border,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: FletegoSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedCount',
                              style: FletegoTypography.metric(),
                            ),
                            Text(
                              'Completados',
                              style: FletegoTypography.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: FletegoColors.border,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: FletegoSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalCount',
                              style: FletegoTypography.metric(),
                            ),
                            Text(
                              'Total',
                              style: FletegoTypography.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

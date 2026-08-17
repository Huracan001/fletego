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

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final name = profile?.greetingName;
    final hello = (name == null || name.isEmpty) ? 'Hola' : 'Hola, $name';
    final trips = ref.watch(tripsListControllerProvider);
    final active = trips.activeTrip;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(tripsListControllerProvider.notifier).refresh(),
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
                '¿Listo para mover tu carga?',
                style: FletegoTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: FletegoSpacing.lg),
              FletegoButton(
                label: 'Solicitar un camión',
                onPressed: () => context.push(AppRoutes.requestTruck),
              ),
              const SizedBox(height: FletegoSpacing.xl),
              Text(
                'Viaje activo',
                style: FletegoTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: FletegoSpacing.sm),
              if (trips.isLoading && active == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (trips.error != null && active == null)
                FletegoErrorState(
                  message: trips.error!,
                  onRetry: () =>
                      ref.read(tripsListControllerProvider.notifier).refresh(),
                )
              else if (active != null)
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
                    ],
                  ),
                )
              else
                const FletegoEmptyState(
                  title: 'Sin viaje activo',
                  message:
                      'Si ya aceptaste una oferta, abre Mis viajes o desliza para actualizar.',
                ),
              const SizedBox(height: FletegoSpacing.lg),
              Text(
                'Acciones rápidas',
                style: FletegoTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: FletegoSpacing.sm),
              Wrap(
                spacing: FletegoSpacing.sm,
                runSpacing: FletegoSpacing.sm,
                children: [
                  _QuickAction(
                    label: 'Mis viajes',
                    onTap: () => context.push(AppRoutes.myTrips),
                  ),
                  _QuickAction(
                    label: 'Notificaciones',
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  _QuickAction(
                    label: 'Mis solicitudes',
                    onTap: () => context.push(AppRoutes.myRequests),
                  ),
                  _QuickAction(
                    label: 'Mi empresa',
                    onTap: () => context.push(AppRoutes.createCompany),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FletegoColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FletegoColors.border),
          ),
          child: Text(label, style: FletegoTypography.textTheme.labelLarge),
        ),
      ),
    );
  }
}

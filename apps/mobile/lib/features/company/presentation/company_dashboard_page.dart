import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/cargo_enums.dart';
import '../../../shared/enums/company_enums.dart';
import '../../../shared/enums/trip_status.dart';
import '../../../shared/enums/vehicle_enums.dart';
import '../../cargo/domain/cargo_models.dart';
import '../../trips/domain/trip_models.dart';
import '../../vehicles/domain/vehicle_models.dart';
import '../application/company_controller.dart';
import '../application/company_dashboard_controller.dart';
import '../domain/company.dart';
import '../domain/company_driver.dart';
import '../domain/company_permission_service.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(companyListControllerProvider).memberships;
    final state = ref.watch(companyDashboardControllerProvider);

    CompanyMembership? membership;
    for (final m in memberships) {
      if (m.company.id == companyId) {
        membership = m;
        break;
      }
    }
    membership ??= ref.watch(activeMembershipProvider);

    final company = membership?.company;
    final role = membership?.role;
    final canManageVehicles =
        role != null &&
        CompanyPermissionService.can(role, CompanyPermission.manageVehicles);

    if (state.companyId != companyId && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCompanyIdProvider.notifier).select(companyId);
        ref
            .read(companyDashboardControllerProvider.notifier)
            .refresh(companyId: companyId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'Empresa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.managerHome);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Miembros y perfil',
            onPressed: () =>
                context.push(AppRoutes.companyDetail, extra: companyId),
            icon: const Icon(Icons.groups_outlined),
          ),
        ],
      ),
      floatingActionButton: canManageVehicles
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(AppRoutes.vehicleForm, extra: companyId);
                if (context.mounted) {
                  await ref
                      .read(companyDashboardControllerProvider.notifier)
                      .refresh(companyId: companyId);
                }
              },
              backgroundColor: FletegoColors.primary,
              foregroundColor: FletegoColors.white,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Agregar vehículo'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(companyDashboardControllerProvider.notifier)
              .refresh(companyId: companyId),
          child: ListView(
            padding: const EdgeInsets.all(FletegoSpacing.lg),
            children: [
              if (company != null) ...[
                Text(
                  company.name,
                  style: FletegoTypography.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  role != null
                      ? '${company.companyType.labelEs} · ${role.labelEs}'
                      : company.companyType.labelEs,
                  style: FletegoTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: FletegoSpacing.xl),
              ],
              if (state.isLoading &&
                  state.activeTrips.isEmpty &&
                  state.vehicles.isEmpty &&
                  state.drivers.isEmpty &&
                  state.pendingRequests.isEmpty)
                const FletegoLoadingState(message: 'Cargando panel...')
              else ...[
                if (state.error != null) ...[
                  FletegoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.error!,
                          style: FletegoTypography.textTheme.bodySmall?.copyWith(
                            color: FletegoColors.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(companyDashboardControllerProvider.notifier)
                              .refresh(companyId: companyId),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FletegoSpacing.md),
                ],
                _SectionHeader(
                  title: 'Viajes activos',
                  count: state.activeTrips.length,
                ),
                const SizedBox(height: FletegoSpacing.sm),
                if (state.activeTrips.isEmpty)
                  const FletegoEmptyState(
                    title: 'Sin viajes activos',
                    message:
                        'Cuando la empresa acepte o asigne un flete, aparecerá aquí.',
                  )
                else
                  ...state.activeTrips.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                      child: _TripCard(trip: t),
                    ),
                  ),
                const SizedBox(height: FletegoSpacing.xl),
                _SectionHeader(
                  title: 'Conductores',
                  count: state.drivers.length,
                ),
                const SizedBox(height: FletegoSpacing.sm),
                if (state.drivers.isEmpty)
                  const FletegoEmptyState(
                    title: 'Sin conductores en flota',
                    message:
                        'Asigna conductores a vehículos de la empresa (desde el perfil del conductor).',
                  )
                else
                  ...state.drivers.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                      child: _DriverCard(driver: d),
                    ),
                  ),
                const SizedBox(height: FletegoSpacing.xl),
                _SectionHeader(
                  title: 'Vehículos',
                  count: state.vehicles.length,
                ),
                const SizedBox(height: FletegoSpacing.sm),
                if (state.vehicles.isEmpty)
                  const FletegoEmptyState(
                    title: 'Sin vehículos',
                    message: 'Agrega camiones a la flota de la empresa.',
                  )
                else
                  ...state.vehicles.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                      child: _VehicleCard(vehicle: v),
                    ),
                  ),
                const SizedBox(height: FletegoSpacing.xl),
                _SectionHeader(
                  title: 'Solicitudes pendientes',
                  count: state.pendingRequests.length,
                ),
                const SizedBox(height: FletegoSpacing.sm),
                if (state.pendingRequests.isEmpty)
                  const FletegoEmptyState(
                    title: 'Sin solicitudes pendientes',
                    message:
                        'Las solicitudes de esta empresa en búsqueda u ofertas aparecen aquí.',
                  )
                else
                  ...state.pendingRequests.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                      child: _RequestCard(request: r),
                    ),
                  ),
                const SizedBox(height: FletegoSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: FletegoTypography.textTheme.titleMedium),
        ),
        Text(
          '$count',
          style: FletegoTypography.textTheme.labelLarge?.copyWith(
            color: FletegoColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    return FletegoCard(
      onTap: () => context.push(AppRoutes.tripDetail, extra: trip.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.routeLabel,
                  style: FletegoTypography.textTheme.titleSmall,
                ),
              ),
              FletegoStatusBadge(
                label: trip.status.labelEs,
                tone: trip.status == TripStatus.completed
                    ? FletegoBadgeTone.success
                    : FletegoBadgeTone.primary,
              ),
            ],
          ),
          if (trip.cargoType != null) ...[
            const SizedBox(height: 4),
            Text(
              trip.cargoType!.labelEs,
              style: FletegoTypography.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final CompanyDriver driver;

  @override
  Widget build(BuildContext context) {
    return FletegoCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: FletegoColors.surfaceMuted,
            child: Text(
              driver.fullName.isNotEmpty
                  ? driver.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: FletegoColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: FletegoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName,
                  style: FletegoTypography.textTheme.titleSmall,
                ),
                Text(
                  driver.subtitle,
                  style: FletegoTypography.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FletegoStatusBadge(
            label: driver.verificationStatus.labelEs,
            tone: driver.verificationStatus == VerificationStatus.approved
                ? FletegoBadgeTone.success
                : FletegoBadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle vehicle;

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
                  vehicle.title,
                  style: FletegoTypography.textTheme.titleSmall,
                ),
              ),
              FletegoStatusBadge(
                label: vehicle.availabilityStatus.labelEs,
                tone: vehicle.availabilityStatus == AvailabilityStatus.available
                    ? FletegoBadgeTone.success
                    : FletegoBadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(vehicle.subtitle, style: FletegoTypography.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final CargoRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final route = '${request.originCity} → ${request.destinationCity}';
    return FletegoCard(
      onTap: () => context.push(
        AppRoutes.requestOffers,
        extra: {'requestId': request.id, 'routeLabel': route},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  route,
                  style: FletegoTypography.textTheme.titleSmall,
                ),
              ),
              FletegoStatusBadge(
                label: request.status.labelEs,
                tone: switch (request.status) {
                  RequestStatus.offered => FletegoBadgeTone.primary,
                  RequestStatus.matching ||
                  RequestStatus.submitted => FletegoBadgeTone.warning,
                  _ => FletegoBadgeTone.neutral,
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.cargoType.labelEs,
            style: FletegoTypography.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

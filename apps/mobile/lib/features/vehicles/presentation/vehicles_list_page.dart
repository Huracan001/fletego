import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/company_enums.dart';
import '../../../shared/enums/vehicle_enums.dart';
import '../application/driver_fleet_controller.dart';
import '../domain/vehicle_models.dart';

class VehiclesListPage extends ConsumerWidget {
  const VehiclesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverFleetControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.vehicleForm),
        backgroundColor: FletegoColors.primary,
        foregroundColor: FletegoColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(driverFleetControllerProvider.notifier).refresh(),
          child: state.isLoading
              ? const FletegoLoadingState(message: 'Cargando vehículos...')
              : state.error != null && state.vehicles.isEmpty
              ? FletegoErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(driverFleetControllerProvider.notifier)
                      .refresh(),
                )
              : state.vehicles.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    FletegoEmptyState(
                      title: 'Sin vehículos',
                      message: 'Registra tu camión para publicar disponibilidad y recibir cargas.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(FletegoSpacing.lg),
                  itemCount: state.vehicles.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FletegoSpacing.sm),
                  itemBuilder: (context, index) {
                    final vehicle = state.vehicles[index];
                    return _VehicleCard(vehicle: vehicle);
                  },
                ),
        ),
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
                  style: FletegoTypography.textTheme.titleMedium,
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
          Text(vehicle.subtitle, style: FletegoTypography.textTheme.bodyMedium),
          if (vehicle.maxCargoKg != null) ...[
            const SizedBox(height: 4),
            Text(
              'Capacidad: ${vehicle.maxCargoKg!.toStringAsFixed(0)} kg',
              style: FletegoTypography.metric(fontSize: 18),
            ),
          ],
          const SizedBox(height: FletegoSpacing.sm),
          FletegoStatusBadge(
            label: vehicle.verificationStatus.labelEs,
            tone: vehicle.verificationStatus == VerificationStatus.approved
                ? FletegoBadgeTone.success
                : FletegoBadgeTone.warning,
          ),
        ],
      ),
    );
  }
}

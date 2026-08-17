import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../application/driver_fleet_controller.dart';
import '../domain/vehicle_models.dart';

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});

  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  String? _vehicleId;
  bool _acceptsReturn = true;
  final _deadhead = TextEditingController(text: '80');
  bool _loading = false;

  @override
  void dispose() {
    _deadhead.dispose();
    super.dispose();
  }

  Future<void> _goAvailable() async {
    final state = ref.read(driverFleetControllerProvider);
    if (state.vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero registra un vehículo.')),
      );
      context.push(AppRoutes.vehicleForm);
      return;
    }

    final vehicleId = _vehicleId ?? state.vehicles.first.id;
    setState(() => _loading = true);
    final ok = await ref
        .read(driverFleetControllerProvider.notifier)
        .setAvailable(
          vehicleId: vehicleId,
          acceptsReturnCargo: _acceptsReturn,
          maxDeadheadKm: double.tryParse(_deadhead.text.replaceAll(',', '.')),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      final error = ref.read(driverFleetControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No pudimos publicar disponibilidad.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ahora estás disponible para cargas.')),
    );
    context.pop();
  }

  Future<void> _goOffline() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(driverFleetControllerProvider.notifier)
        .setOffline();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverFleetControllerProvider);
    final vehicles = state.vehicles;
    final selected =
        _vehicleId ?? (vehicles.isEmpty ? null : vehicles.first.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FletegoSpacing.lg),
          children: [
            Text(
              state.isAvailable
                  ? 'Estás marcado como disponible'
                  : 'Publica que estás disponible',
              style: FletegoTypography.textTheme.headlineSmall,
            ),
            const SizedBox(height: FletegoSpacing.xs),
            Text(
              'Solo rastreamos ubicación en viajes activos. Aquí solo publicas tu estado y vehículo.',
              style: FletegoTypography.textTheme.bodyMedium,
            ),
            const SizedBox(height: FletegoSpacing.lg),
            if (vehicles.isEmpty)
              FletegoEmptyState(
                title: 'Necesitas un vehículo',
                message: 'Registra al menos un camión para publicarte.',
                actionLabel: 'Registrar vehículo',
                onAction: () => context.push(AppRoutes.vehicleForm),
              )
            else ...[
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selected,
                decoration: const InputDecoration(labelText: 'Vehículo'),
                items: vehicles
                    .map(
                      (Vehicle v) =>
                          DropdownMenuItem(value: v.id, child: Text(v.title)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _vehicleId = v),
              ),
              const SizedBox(height: FletegoSpacing.md),
              TextFormField(
                controller: _deadhead,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Km máximos en vacío',
                  helperText: 'Distancia máxima que aceptas sin carga',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acepto carga de retorno'),
                value: _acceptsReturn,
                onChanged: (v) => setState(() => _acceptsReturn = v),
              ),
              const SizedBox(height: FletegoSpacing.lg),
              if (state.isAvailable)
                FletegoSecondaryButton(
                  label: 'Dejar de estar disponible',
                  onPressed: _loading ? null : _goOffline,
                )
              else
                FletegoButton(
                  label: 'Estoy disponible',
                  isLoading: _loading,
                  onPressed: _goAvailable,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

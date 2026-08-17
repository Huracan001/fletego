import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/cargo_enums.dart';
import '../application/cargo_wizard_controller.dart';
import '../domain/cargo_models.dart';

class CargoRequestWizardPage extends ConsumerStatefulWidget {
  const CargoRequestWizardPage({super.key});

  @override
  ConsumerState<CargoRequestWizardPage> createState() =>
      _CargoRequestWizardPageState();
}

class _CargoRequestWizardPageState
    extends ConsumerState<CargoRequestWizardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cargoWizardControllerProvider.notifier).reset();
    });
  }

  Future<void> _onPrimary() async {
    final controller = ref.read(cargoWizardControllerProvider.notifier);
    final state = ref.read(cargoWizardControllerProvider);

    if (state.step < CargoWizardState.totalSteps - 1) {
      controller.continueNext();
      final err = ref.read(cargoWizardControllerProvider).error;
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    final ok = await controller.submit();
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(cargoWizardControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'No pudimos enviar la solicitud.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitud enviada'),
        content: const Text(
          'Estamos buscando camiones compatibles. Podrás ver ofertas cuando los transportistas respondan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver mis solicitudes'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.go(AppRoutes.myRequests);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cargoWizardControllerProvider);
    final titles = const [
      'Tipo de carga',
      'Origen',
      'Destino',
      'Detalles de la carga',
      'Tipo de camión',
      'Fecha y hora',
      'Requisitos especiales',
      'Revisar y solicitar',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[state.step]),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FletegoSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paso ${state.step + 1} de ${CargoWizardState.totalSteps}',
                    style: FletegoTypography.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 6,
                      backgroundColor: FletegoColors.surfaceMuted,
                      color: FletegoColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FletegoSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FletegoSpacing.lg,
                ),
                child: _StepBody(step: state.step),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FletegoSpacing.lg),
              child: Row(
                children: [
                  if (state.step > 0)
                    Expanded(
                      child: FletegoSecondaryButton(
                        label: 'Atrás',
                        onPressed: state.isSubmitting
                            ? null
                            : () => ref
                                  .read(cargoWizardControllerProvider.notifier)
                                  .back(),
                      ),
                    ),
                  if (state.step > 0) const SizedBox(width: FletegoSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FletegoButton(
                      label: state.step == CargoWizardState.totalSteps - 1
                          ? 'Solicitar camiones'
                          : 'Continuar',
                      isLoading: state.isSubmitting,
                      onPressed: _onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({required this.step});
  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (step) {
      0 => const _CargoTypeStep(),
      1 => const _PlaceStep(isOrigin: true),
      2 => const _PlaceStep(isOrigin: false),
      3 => const _CargoDetailsStep(),
      4 => const _TruckStep(),
      5 => const _ScheduleStep(),
      6 => const _RequirementsStep(),
      _ => const _ReviewStep(),
    };
  }
}

class _CargoTypeStep extends ConsumerWidget {
  const _CargoTypeStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cargoWizardControllerProvider).draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué vas a transportar?',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.md),
        ...CargoType.values.map((type) {
          final selected = draft.cargoType == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
            child: FletegoCard(
              onTap: () {
                final next = draft.copyWith(
                  cargoType: type,
                  container: type == CargoType.contenedor
                      ? (draft.container ?? const ContainerDraft())
                      : draft.container,
                );
                ref
                    .read(cargoWizardControllerProvider.notifier)
                    .updateDraft(next);
              },
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? FletegoColors.primary
                        : FletegoColors.textMuted,
                  ),
                  const SizedBox(width: FletegoSpacing.md),
                  Text(
                    type.labelEs,
                    style: FletegoTypography.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PlaceStep extends ConsumerWidget {
  const _PlaceStep({required this.isOrigin});
  final bool isOrigin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cargoWizardControllerProvider).draft;
    final place = isOrigin ? draft.origin : draft.destination;

    void setPlace(PlaceDraft next) {
      ref
          .read(cargoWizardControllerProvider.notifier)
          .updateDraft(
            isOrigin
                ? draft.copyWith(origin: next)
                : draft.copyWith(destination: next),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOrigin ? '¿Dónde recogemos?' : '¿A dónde entregamos?',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.xs),
        Text(
          'Elige una ciudad o escribe manualmente. El mapa completo llega cuando configures MAPS_API_KEY.',
          style: FletegoTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: FletegoSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BoliviaCity.presets.map((city) {
            final selected = place.city == city.name;
            return ChoiceChip(
              label: Text(city.name),
              selected: selected,
              onSelected: (_) {
                setPlace(
                  place.copyWith(
                    city: city.name,
                    adminArea: city.adminArea,
                    lat: city.lat,
                    lng: city.lng,
                    label: city.name,
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: FletegoSpacing.lg),
        TextFormField(
          initialValue: place.city,
          decoration: const InputDecoration(labelText: 'Ciudad *'),
          onChanged: (v) => setPlace(place.copyWith(city: v)),
        ),
        const SizedBox(height: FletegoSpacing.md),
        TextFormField(
          initialValue: place.addressLine ?? '',
          decoration: const InputDecoration(
            labelText: 'Dirección / referencia',
          ),
          onChanged: (v) => setPlace(place.copyWith(addressLine: v)),
        ),
        const SizedBox(height: FletegoSpacing.md),
        TextFormField(
          initialValue: place.instructions ?? '',
          maxLines: 2,
          decoration: InputDecoration(
            labelText: isOrigin
                ? 'Instrucciones de recogida'
                : 'Instrucciones de entrega',
          ),
          onChanged: (v) => setPlace(place.copyWith(instructions: v)),
        ),
        if (place.lat != null) ...[
          const SizedBox(height: FletegoSpacing.sm),
          Text(
            'Coords: ${place.lat!.toStringAsFixed(4)}, ${place.lng!.toStringAsFixed(4)}',
            style: FletegoTypography.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _CargoDetailsStep extends ConsumerWidget {
  const _CargoDetailsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cargoWizardControllerProvider).draft;
    final isContainer = draft.cargoType == CargoType.contenedor;
    final container = draft.container ?? const ContainerDraft();

    void update(CargoRequestDraft next) {
      ref.read(cargoWizardControllerProvider.notifier).updateDraft(next);
    }

    if (isContainer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos del contenedor',
            style: FletegoTypography.textTheme.headlineSmall,
          ),
          const SizedBox(height: FletegoSpacing.md),
          DropdownButtonFormField<ContainerSize>(
            // ignore: deprecated_member_use
            value: container.containerType,
            decoration: const InputDecoration(labelText: 'Tipo de contenedor'),
            items: ContainerSize.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.labelEs)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              update(
                draft.copyWith(container: container.copyWith(containerType: v)),
              );
            },
          ),
          const SizedBox(height: FletegoSpacing.md),
          TextFormField(
            initialValue: container.containerNumber ?? '',
            decoration: const InputDecoration(
              labelText: 'Número de contenedor',
            ),
            onChanged: (v) => update(
              draft.copyWith(container: container.copyWith(containerNumber: v)),
            ),
          ),
          const SizedBox(height: FletegoSpacing.md),
          TextFormField(
            initialValue: container.grossWeightKg?.toString() ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Peso bruto (kg) *'),
            onChanged: (v) {
              final w = double.tryParse(v.replaceAll(',', '.'));
              update(
                draft.copyWith(
                  totalWeightKg: w,
                  container: container.copyWith(grossWeightKg: w),
                ),
              );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Refrigerado'),
            value: container.refrigerated,
            onChanged: (v) => update(
              draft.copyWith(
                requiresRefrigeration: v,
                container: container.copyWith(refrigerated: v),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Carga peligrosa'),
            value: container.dangerousGoods,
            onChanged: (v) => update(
              draft.copyWith(
                dangerousGoods: v,
                container: container.copyWith(dangerousGoods: v),
              ),
            ),
          ),
          TextFormField(
            initialValue: container.bookingRef ?? '',
            decoration: const InputDecoration(
              labelText: 'Booking / referencia',
            ),
            onChanged: (v) => update(
              draft.copyWith(container: container.copyWith(bookingRef: v)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de la carga',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.md),
        TextFormField(
          initialValue: draft.totalWeightKg?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso total (kg) *'),
          onChanged: (v) => update(
            draft.copyWith(
              totalWeightKg: double.tryParse(v.replaceAll(',', '.')),
            ),
          ),
        ),
        const SizedBox(height: FletegoSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: draft.lengthM?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Largo (m)'),
                onChanged: (v) => update(
                  draft.copyWith(
                    lengthM: double.tryParse(v.replaceAll(',', '.')),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: draft.widthM?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Ancho (m)'),
                onChanged: (v) => update(
                  draft.copyWith(
                    widthM: double.tryParse(v.replaceAll(',', '.')),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: draft.heightM?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Alto (m)'),
                onChanged: (v) => update(
                  draft.copyWith(
                    heightM: double.tryParse(v.replaceAll(',', '.')),
                  ),
                ),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Apilable'),
          value: draft.stackable,
          onChanged: (v) => update(draft.copyWith(stackable: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Requiere carpa'),
          value: draft.requiresTarp,
          onChanged: (v) => update(draft.copyWith(requiresTarp: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Carga especial / equipo'),
          value: draft.requiresSpecialLoading,
          onChanged: (v) => update(draft.copyWith(requiresSpecialLoading: v)),
        ),
        TextFormField(
          initialValue: draft.specialInstructions ?? '',
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Instrucciones'),
          onChanged: (v) => update(draft.copyWith(specialInstructions: v)),
        ),
      ],
    );
  }
}

class _TruckStep extends ConsumerWidget {
  const _TruckStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cargoWizardControllerProvider);
    final draft = state.draft;
    final rec = state.recommendation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué camión necesitas?',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.md),
        FletegoCard(
          onTap: () {
            ref
                .read(cargoWizardControllerProvider.notifier)
                .updateDraft(
                  draft.copyWith(
                    unknownTruck: true,
                    requestedVehicleTypeId: rec?.vehicleType.id,
                  ),
                );
          },
          child: Row(
            children: [
              Icon(
                draft.unknownTruck ? Icons.check_circle : Icons.help_outline,
                color: draft.unknownTruck
                    ? FletegoColors.success
                    : FletegoColors.primary,
              ),
              const SizedBox(width: FletegoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No sé qué camión necesito',
                      style: FletegoTypography.textTheme.titleMedium,
                    ),
                    Text(
                      'FLETEGO te recomienda según tu carga.',
                      style: FletegoTypography.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (rec != null) ...[
          const SizedBox(height: FletegoSpacing.md),
          Text(
            'Camión recomendado',
            style: FletegoTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: FletegoSpacing.sm),
          FletegoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.vehicleType.nameEs,
                  style: FletegoTypography.metric(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(rec.reason, style: FletegoTypography.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        const SizedBox(height: FletegoSpacing.lg),
        Text(
          'O elige manualmente',
          style: FletegoTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: FletegoSpacing.sm),
        if (state.vehicleTypes.isEmpty)
          const Text(
            'Aún no hay catálogo de vehículos. Corre la migración Phase 4 en Supabase.',
          )
        else
          ...state.vehicleTypes.map((type) {
            final selected =
                !draft.unknownTruck && draft.requestedVehicleTypeId == type.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FletegoCard(
                onTap: () {
                  ref
                      .read(cargoWizardControllerProvider.notifier)
                      .updateDraft(
                        draft.copyWith(
                          unknownTruck: false,
                          requestedVehicleTypeId: type.id,
                        ),
                      );
                },
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? FletegoColors.primary
                          : FletegoColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(type.nameEs)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ScheduleStep extends ConsumerWidget {
  const _ScheduleStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cargoWizardControllerProvider).draft;

    void update(CargoRequestDraft next) {
      ref.read(cargoWizardControllerProvider.notifier).updateDraft(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuándo lo necesitas?',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.md),
        FletegoCard(
          onTap: () => update(draft.copyWith(scheduleMode: ScheduleMode.asap)),
          child: Row(
            children: [
              Icon(
                draft.scheduleMode == ScheduleMode.asap
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: FletegoColors.primary,
              ),
              const SizedBox(width: 12),
              Text(ScheduleMode.asap.labelEs),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FletegoCard(
          onTap: () =>
              update(draft.copyWith(scheduleMode: ScheduleMode.scheduled)),
          child: Row(
            children: [
              Icon(
                draft.scheduleMode == ScheduleMode.scheduled
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: FletegoColors.primary,
              ),
              const SizedBox(width: 12),
              Text(ScheduleMode.scheduled.labelEs),
            ],
          ),
        ),
        if (draft.scheduleMode == ScheduleMode.scheduled) ...[
          const SizedBox(height: FletegoSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              draft.pickupAt == null
                  ? 'Elegir fecha y hora'
                  : 'Recogida: ${draft.pickupAt}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                initialDate: draft.pickupAt ?? DateTime.now(),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  draft.pickupAt ??
                      DateTime.now().add(const Duration(hours: 2)),
                ),
              );
              if (time == null) return;
              update(
                draft.copyWith(
                  pickupAt: DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                  pickupWindowStart:
                      '${time.hour.toString().padLeft(2, '0')}:00',
                  pickupWindowEnd:
                      '${(time.hour + 2).clamp(0, 23).toString().padLeft(2, '0')}:00',
                ),
              );
            },
          ),
          if (draft.pickupWindowStart != null)
            Text(
              'Ventana: ${draft.pickupWindowStart}–${draft.pickupWindowEnd}',
              style: FletegoTypography.textTheme.bodyMedium,
            ),
        ],
      ],
    );
  }
}

class _RequirementsStep extends ConsumerWidget {
  const _RequirementsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cargoWizardControllerProvider).draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos especiales',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.md),
        ...SpecialRequirement.values.map((req) {
          final selected = draft.specialRequirements.contains(req);
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(req.labelEs),
            value: selected,
            onChanged: (v) {
              final next = {...draft.specialRequirements};
              if (v == true) {
                next.add(req);
              } else {
                next.remove(req);
              }
              ref
                  .read(cargoWizardControllerProvider.notifier)
                  .updateDraft(draft.copyWith(specialRequirements: next));
            },
          );
        }),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cargoWizardControllerProvider);
    final d = state.draft;
    String truckName = 'Por definir';
    for (final t in state.vehicleTypes) {
      if (t.id == d.requestedVehicleTypeId) {
        truckName = t.nameEs;
        break;
      }
    }

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: FletegoTypography.textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: Text(value, style: FletegoTypography.textTheme.titleSmall),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisa tu solicitud',
          style: FletegoTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: FletegoSpacing.md),
        FletegoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Ruta', '${d.origin.city} → ${d.destination.city}'),
              row('Carga', d.cargoType?.labelEs ?? '-'),
              row(
                'Peso',
                d.totalWeightKg == null
                    ? '-'
                    : '${d.totalWeightKg!.toStringAsFixed(0)} kg',
              ),
              row('Camión', truckName),
              row(
                'Fecha',
                d.scheduleMode == ScheduleMode.asap
                    ? 'Lo antes posible'
                    : (d.pickupAt?.toString() ?? 'Programado'),
              ),
              if (d.specialRequirements.isNotEmpty)
                row(
                  'Extras',
                  d.specialRequirements.map((e) => e.labelEs).join(', '),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

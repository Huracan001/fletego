import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../vehicles/application/driver_fleet_controller.dart';
import '../application/offers_controller.dart';
import '../domain/offer_models.dart';

class MarketplacePage extends ConsumerWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceControllerProvider);
    final fleet = ref.watch(driverFleetControllerProvider);
    final selectedId =
        state.selectedVehicleId ??
        (fleet.vehicles.isNotEmpty ? fleet.vehicles.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargas disponibles'),
        leading: IconButton(
          tooltip: 'Volver al inicio',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.driverHome),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(marketplaceControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(FletegoSpacing.lg),
            children: [
              if (fleet.vehicles.isNotEmpty && selectedId != null) ...[
                Text(
                  'Camión para ofertar',
                  style: FletegoTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: FletegoSpacing.sm),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedId),
                  initialValue: selectedId,
                  items: fleet.vehicles
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v.id, child: Text(v.title)),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      ref
                          .read(marketplaceControllerProvider.notifier)
                          .selectVehicle(id);
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: FletegoSpacing.lg),
              ],
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: FletegoLoadingState(),
                )
              else if (state.error != null && state.ranked.isEmpty)
                FletegoErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(marketplaceControllerProvider.notifier)
                      .refresh(),
                )
              else if (state.ranked.isEmpty)
                const FletegoEmptyState(
                  title: 'Sin cargas compatibles',
                  message: 'Cuando haya solicitudes abiertas compatibles con tu camión, aparecerán aquí.',
                )
              else
                ...state.ranked.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                    child: _LoadCard(
                      item: item,
                      onOffer: item.eligible
                          ? () => _showOfferSheet(context, ref, item)
                          : null,
                    ),
                  ),
                ),
              if (state.error != null && state.ranked.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: FletegoSpacing.sm),
                  child: Text(
                    state.error!,
                    style: FletegoTypography.textTheme.bodySmall?.copyWith(
                      color: FletegoColors.navy,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOfferSheet(
    BuildContext context,
    WidgetRef ref,
    RankedLoad item,
  ) async {
    final draft = await showModalBottomSheet<_OfferDraft>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OfferSheet(routeLabel: item.load.routeLabel),
    );

    if (draft == null || !context.mounted) return;

    final offer = await ref
        .read(marketplaceControllerProvider.notifier)
        .submitOffer(
          requestId: item.load.id,
          priceAmount: draft.price,
          message: draft.message,
        );

    if (!context.mounted) return;
    final error = ref.read(marketplaceControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          offer != null
              ? 'Oferta enviada por ${offer.priceLabel}'
              : (error ?? 'No se pudo enviar'),
        ),
      ),
    );
  }
}

class _OfferDraft {
  const _OfferDraft({required this.price, this.message});
  final double price;
  final String? message;
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.routeLabel});

  final String routeLabel;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  late final TextEditingController _messageCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final price = double.parse(_priceCtrl.text.trim());
    final message = _messageCtrl.text.trim();
    Navigator.of(
      context,
    ).pop(_OfferDraft(price: price, message: message.isEmpty ? null : message));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: FletegoSpacing.lg,
        right: FletegoSpacing.lg,
        top: FletegoSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + FletegoSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ofertar · ${widget.routeLabel}',
              style: FletegoTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: FletegoSpacing.md),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio (BOB)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Precio inválido';
                return null;
              },
            ),
            const SizedBox(height: FletegoSpacing.sm),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: FletegoSpacing.md),
            FletegoButton(label: 'Enviar oferta', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  const _LoadCard({required this.item, this.onOffer});

  final RankedLoad item;
  final VoidCallback? onOffer;

  @override
  Widget build(BuildContext context) {
    final load = item.load;
    return FletegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  load.routeLabel,
                  style: FletegoTypography.textTheme.titleMedium,
                ),
              ),
              FletegoStatusBadge(
                label: item.eligible ? 'Match ${item.score}' : 'No compatible',
                tone: item.eligible
                    ? FletegoBadgeTone.success
                    : FletegoBadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            load.cargoType.labelEs,
            style: FletegoTypography.textTheme.bodyMedium,
          ),
          if (load.totalWeightKg != null)
            Text(
              '${load.totalWeightKg!.toStringAsFixed(0)} kg',
              style: FletegoTypography.metric(fontSize: 20),
            ),
          if (item.reasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                item.reasons.take(3).join(' · '),
                style: FletegoTypography.textTheme.bodySmall,
              ),
            ),
          if (item.blockers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.blockers.first,
                style: FletegoTypography.textTheme.bodySmall?.copyWith(
                  color: FletegoColors.navy,
                ),
              ),
            ),
          if (onOffer != null) ...[
            const SizedBox(height: FletegoSpacing.sm),
            FletegoButton(label: 'Hacer oferta', onPressed: onOffer),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/offer_enums.dart';
import '../application/offers_controller.dart';
import '../domain/offer_models.dart';

class RequestOffersPage extends ConsumerWidget {
  const RequestOffersPage({
    super.key,
    required this.requestId,
    this.routeLabel,
  });

  final String requestId;
  final String? routeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestOffersControllerProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: Text(routeLabel ?? 'Ofertas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.myRequests),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(requestOffersControllerProvider(requestId).notifier)
              .refresh(),
          child: state.isLoading
              ? const FletegoLoadingState()
              : state.error != null && state.offers.isEmpty
              ? FletegoErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(
                        requestOffersControllerProvider(requestId).notifier,
                      )
                      .refresh(),
                )
              : state.offers.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    FletegoEmptyState(
                      title: 'Aún no hay ofertas',
                      message:
                          'Los conductores compatibles pueden ofertar desde el marketplace.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(FletegoSpacing.lg),
                  itemCount: state.offers.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FletegoSpacing.sm),
                  itemBuilder: (context, index) {
                    final offer = state.offers[index];
                    return _OfferCard(
                      offer: offer,
                      busy: state.isAccepting,
                      onAccept: offer.status == OfferStatus.pending
                          ? () => _accept(context, ref, offer)
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    Offer offer,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceptar oferta'),
        content: Text(
          '¿Aceptar la oferta de ${offer.priceLabel}? Se creará el viaje y se rechazarán las demás.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final success = await ref
        .read(requestOffersControllerProvider(requestId).notifier)
        .accept(offer.id);

    if (!context.mounted) return;
    final err = ref.read(requestOffersControllerProvider(requestId)).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Oferta aceptada. Viaje creado.'
              : (err ?? 'No se pudo aceptar'),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    this.onAccept,
  });

  final Offer offer;
  final bool busy;
  final VoidCallback? onAccept;

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
                  offer.priceLabel,
                  style: FletegoTypography.metric(fontSize: 28),
                ),
              ),
              FletegoStatusBadge(
                label: offer.status.labelEs,
                tone: switch (offer.status) {
                  OfferStatus.pending => FletegoBadgeTone.primary,
                  OfferStatus.accepted => FletegoBadgeTone.success,
                  _ => FletegoBadgeTone.neutral,
                },
              ),
            ],
          ),
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              offer.message!,
              style: FletegoTypography.textTheme.bodyMedium,
            ),
          ],
          if (onAccept != null) ...[
            const SizedBox(height: FletegoSpacing.sm),
            FletegoButton(
              label: 'Aceptar oferta',
              isLoading: busy,
              onPressed: busy ? null : onAccept,
            ),
          ],
        ],
      ),
    );
  }
}

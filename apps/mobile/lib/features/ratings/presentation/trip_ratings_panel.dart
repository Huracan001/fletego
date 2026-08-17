import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/trip_status.dart';
import '../../auth/application/auth_controller.dart';
import '../../trips/application/trips_controller.dart';
import '../application/ratings_controller.dart';
import '../domain/rating_models.dart';

class TripRatingsPanel extends ConsumerWidget {
  const TripRatingsPanel({
    super.key,
    required this.tripId,
    required this.isDriver,
    required this.isCustomer,
  });

  final String tripId;
  final bool isDriver;
  final bool isCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripDetailControllerProvider(tripId)).trip;
    final state = ref.watch(tripRatingsControllerProvider(tripId));
    if (trip == null) return const SizedBox.shrink();

    final rateable =
        trip.status == TripStatus.delivered ||
        trip.status == TripStatus.completed;
    if (!rateable && state.ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    final perspective = isCustomer
        ? RatingPerspective.customerRatesDriver
        : isDriver
        ? RatingPerspective.driverRatesCustomer
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calificaciones',
          style: FletegoTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: FletegoSpacing.sm),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
            child: Text(
              state.error!,
              style: FletegoTypography.textTheme.bodySmall,
            ),
          ),
        if (state.myRating != null)
          FletegoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu calificación: ${state.myRating!.overall}/5',
                  style: FletegoTypography.textTheme.titleSmall,
                ),
                if (state.myRating!.comment != null)
                  Text(
                    state.myRating!.comment!,
                    style: FletegoTypography.textTheme.bodyMedium,
                  ),
              ],
            ),
          )
        else if (rateable && perspective != null)
          _RatingForm(
            tripId: tripId,
            perspective: perspective,
            isSaving: state.isSaving,
          )
        else if (!rateable)
          Text(
            'Podrás calificar cuando el viaje esté entregado o completado.',
            style: FletegoTypography.textTheme.bodyMedium,
          ),
        if (state.ratings.where((r) => r.fromUserId != ref.watch(authControllerProvider).profile?.id).isNotEmpty) ...[
          const SizedBox(height: FletegoSpacing.sm),
          ...state.ratings
              .where(
                (r) =>
                    r.fromUserId !=
                    ref.watch(authControllerProvider).profile?.id,
              )
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                  child: FletegoCard(
                    child: Text(
                      'Recibida: ${r.overall}/5'
                      '${r.comment != null ? ' — ${r.comment}' : ''}',
                      style: FletegoTypography.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
        ],
        const SizedBox(height: FletegoSpacing.lg),
      ],
    );
  }
}

class _RatingForm extends ConsumerStatefulWidget {
  const _RatingForm({
    required this.tripId,
    required this.perspective,
    required this.isSaving,
  });

  final String tripId;
  final RatingPerspective perspective;
  final bool isSaving;

  @override
  ConsumerState<_RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends ConsumerState<_RatingForm> {
  int _overall = 5;
  late Map<String, int> _dims;
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dims = {
      for (final d in RatingDimensions.defsFor(widget.perspective)) d.key: 5,
    };
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defs = RatingDimensions.defsFor(widget.perspective);
    final title = widget.perspective == RatingPerspective.customerRatesDriver
        ? 'Califica al conductor'
        : 'Califica al cliente';

    return FletegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FletegoTypography.textTheme.titleSmall),
          const SizedBox(height: FletegoSpacing.sm),
          Text('General', style: FletegoTypography.textTheme.bodySmall),
          _StarRow(
            value: _overall,
            onChanged: (v) => setState(() => _overall = v),
          ),
          const SizedBox(height: FletegoSpacing.sm),
          for (final d in defs) ...[
            Text(d.labelEs, style: FletegoTypography.textTheme.bodySmall),
            _StarRow(
              value: _dims[d.key] ?? 5,
              onChanged: (v) => setState(() => _dims[d.key] = v),
            ),
            const SizedBox(height: 4),
          ],
          TextField(
            controller: _comment,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: FletegoSpacing.sm),
          FletegoButton(
            label: 'Enviar calificación',
            isLoading: widget.isSaving,
            onPressed: widget.isSaving
                ? null
                : () async {
                    final ok = await ref
                        .read(
                          tripRatingsControllerProvider(widget.tripId).notifier,
                        )
                        .submit(
                          overall: _overall,
                          dimensions: Map<String, int>.from(_dims),
                          comment: _comment.text.trim().isEmpty
                              ? null
                              : _comment.text.trim(),
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Calificación enviada'
                              : (ref
                                        .read(
                                          tripRatingsControllerProvider(
                                            widget.tripId,
                                          ),
                                        )
                                        .error ??
                                    'Error'),
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              color: i <= value ? FletegoColors.primary : FletegoColors.navy,
            ),
          ),
      ],
    );
  }
}

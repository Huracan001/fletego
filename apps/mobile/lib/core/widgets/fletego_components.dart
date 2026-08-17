import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class FletegoButton extends StatelessWidget {
  const FletegoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: FletegoColors.white,
            ),
          )
        : Text(label);

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class FletegoSecondaryButton extends StatelessWidget {
  const FletegoSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(onPressed: onPressed, child: Text(label));
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class FletegoCard extends StatelessWidget {
  const FletegoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FletegoSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: FletegoColors.white,
        borderRadius: FletegoRadii.borderLg,
        border: Border.all(color: FletegoColors.border),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FletegoRadii.borderLg,
        child: content,
      ),
    );
  }
}

class FletegoStatusBadge extends StatelessWidget {
  const FletegoStatusBadge({
    super.key,
    required this.label,
    this.tone = FletegoBadgeTone.neutral,
  });

  final String label;
  final FletegoBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      FletegoBadgeTone.primary => (
        FletegoColors.primary.withValues(alpha: 0.12),
        FletegoColors.primary,
      ),
      FletegoBadgeTone.success => (
        FletegoColors.success.withValues(alpha: 0.14),
        FletegoColors.success,
      ),
      FletegoBadgeTone.warning => (
        FletegoColors.warning.withValues(alpha: 0.16),
        const Color(0xFFB45309),
      ),
      FletegoBadgeTone.danger => (
        FletegoColors.error.withValues(alpha: 0.12),
        FletegoColors.error,
      ),
      FletegoBadgeTone.neutral => (
        FletegoColors.surfaceMuted,
        FletegoColors.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FletegoRadii.full),
      ),
      child: Text(
        label,
        style: FletegoTypography.textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

enum FletegoBadgeTone { primary, success, warning, danger, neutral }

class FletegoEmptyState extends StatelessWidget {
  const FletegoEmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FletegoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: FletegoTypography.textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: FletegoSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: FletegoTypography.textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: FletegoSpacing.lg),
              FletegoButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class FletegoLoadingState extends StatelessWidget {
  const FletegoLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: FletegoColors.primary),
          if (message != null) ...[
            const SizedBox(height: FletegoSpacing.md),
            Text(message!, style: FletegoTypography.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class FletegoErrorState extends StatelessWidget {
  const FletegoErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FletegoEmptyState(
      title: 'Algo salió mal',
      message: message,
      actionLabel: onRetry == null ? null : 'Reintentar',
      onAction: onRetry,
    );
  }
}

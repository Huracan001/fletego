import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_brand_mark.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/onboarding_intent.dart';
import '../../auth/application/auth_controller.dart';

/// First-run / incomplete profile: ¿Qué quieres hacer?
class OnboardingIntentPage extends ConsumerStatefulWidget {
  const OnboardingIntentPage({super.key});

  @override
  ConsumerState<OnboardingIntentPage> createState() =>
      _OnboardingIntentPageState();
}

class _OnboardingIntentPageState extends ConsumerState<OnboardingIntentPage> {
  bool _loading = false;

  Future<void> _select(OnboardingIntent intent) async {
    final auth = ref.read(authControllerProvider);

    if (auth.status != AuthStatus.authenticated) {
      context.go(AppRoutes.signup, extra: intent);
      return;
    }

    setState(() => _loading = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .completeOnboarding(intent);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      final message = ref.read(authControllerProvider).message;
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        ref.read(authControllerProvider.notifier).clearMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final showBack = auth.status != AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(AppRoutes.welcome),
              )
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FletegoSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FletegoBrandMark(compact: true),
                  const SizedBox(height: FletegoSpacing.xl),
                  Text(
                    '¿Qué quieres hacer?',
                    style: FletegoTypography.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: FletegoSpacing.xs),
                  Text(
                    'Elegiremos una experiencia simple según tu objetivo.',
                    style: FletegoTypography.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: FletegoSpacing.lg),
                  _IntentCard(
                    emoji: '📦',
                    title: 'Necesito transportar',
                    subtitle: 'Quiero un camión para mi carga.',
                    onTap: () => _select(OnboardingIntent.needTransport),
                  ),
                  const SizedBox(height: FletegoSpacing.sm),
                  _IntentCard(
                    emoji: '🚛',
                    title: 'Ofrezco transporte',
                    subtitle: 'Tengo camión y quiero transportar carga.',
                    onTap: () => _select(OnboardingIntent.offerTransport),
                  ),
                  const SizedBox(height: FletegoSpacing.sm),
                  _IntentCard(
                    emoji: '🏢',
                    title: 'Gestiono transporte',
                    subtitle:
                        'Administro operaciones para una empresa o terceros.',
                    onTap: () => _select(OnboardingIntent.manageTransport),
                  ),
                ],
              ),
            ),
            if (_loading)
              const ColoredBox(
                color: Color(0x66F6F8FC),
                child: Center(
                  child: CircularProgressIndicator(
                    color: FletegoColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FletegoCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: FletegoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FletegoTypography.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: FletegoTypography.textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FletegoColors.textMuted),
        ],
      ),
    );
  }
}

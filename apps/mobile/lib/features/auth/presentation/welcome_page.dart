import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_brand_mark.dart';
import '../../../core/widgets/fletego_components.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FletegoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: FletegoSpacing.xl),
              const FletegoBrandMark(),
              const Spacer(),
              Text(
                'El marketplace de transporte pesado',
                style: FletegoTypography.textTheme.headlineLarge,
              ),
              const SizedBox(height: FletegoSpacing.sm),
              Text(
                'Solicita el camión correcto para tu carga o encuentra fletes compatibles y reduce viajes en vacío.',
                style: FletegoTypography.textTheme.bodyLarge?.copyWith(
                  color: FletegoColors.textSecondary,
                ),
              ),
              const SizedBox(height: FletegoSpacing.xl),
              FletegoButton(
                label: 'Comenzar',
                onPressed: () => context.go(AppRoutes.onboardingIntent),
              ),
              const SizedBox(height: FletegoSpacing.sm),
              FletegoSecondaryButton(
                label: 'Ya tengo cuenta',
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: FletegoSpacing.lg),
              Center(
                child: Text(
                  'FLETEGO by Pick&Truck',
                  style: FletegoTypography.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: FletegoSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

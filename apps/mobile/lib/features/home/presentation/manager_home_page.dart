import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../auth/application/auth_controller.dart';
import '../../company/application/company_controller.dart';

class ManagerHomePage extends ConsumerWidget {
  const ManagerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).profile?.greetingName;
    final hello = (name == null || name.isEmpty) ? 'Hola' : 'Hola, $name';
    final companies = ref.watch(companyListControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(companyListControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(FletegoSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hello,
                      style: FletegoTypography.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              const SizedBox(height: FletegoSpacing.xs),
              Text(
                'Panel operativo: viajes, flota, conductores y solicitudes.',
                style: FletegoTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: FletegoSpacing.lg),
              FletegoButton(
                label: 'Crear empresa',
                onPressed: () => context.push(AppRoutes.createCompany),
              ),
              const SizedBox(height: FletegoSpacing.xl),
              Text(
                'Mis empresas',
                style: FletegoTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: FletegoSpacing.sm),
              if (companies.isLoading)
                const FletegoLoadingState()
              else if (companies.error != null)
                FletegoErrorState(
                  message: companies.error!,
                  onRetry: () => ref
                      .read(companyListControllerProvider.notifier)
                      .refresh(),
                )
              else if (companies.memberships.isEmpty)
                const FletegoEmptyState(
                  title: 'Aún no tienes empresa',
                  message: 'Crea tu empresa para gestionar operadores, viajes y flota.',
                )
              else
                ...companies.memberships.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                    child: FletegoCard(
                      onTap: () {
                        ref
                            .read(selectedCompanyIdProvider.notifier)
                            .select(m.company.id);
                        context.push(
                          AppRoutes.companyDashboard,
                          extra: m.company.id,
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: FletegoColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.apartment,
                              color: FletegoColors.navy,
                            ),
                          ),
                          const SizedBox(width: FletegoSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.company.name,
                                  style: FletegoTypography.textTheme.titleSmall,
                                ),
                                Text(
                                  '${m.company.companyType.labelEs} · ${m.role.labelEs}',
                                  style: FletegoTypography.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: FletegoColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

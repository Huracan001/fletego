import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/company_enums.dart';
import '../../auth/application/auth_controller.dart';
import '../application/company_controller.dart';
import '../domain/company.dart';
import '../domain/company_permission_service.dart';

class CompanyDetailPage extends ConsumerStatefulWidget {
  const CompanyDetailPage({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends ConsumerState<CompanyDetailPage> {
  List<CompanyMember> _members = const [];
  bool _loadingMembers = true;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMembers);
  }

  Future<void> _loadMembers() async {
    final repo = ref.read(companyRepositoryProvider);
    if (repo == null) {
      setState(() {
        _loadingMembers = false;
        _membersError = 'Supabase no está configurado.';
      });
      return;
    }

    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });

    try {
      final members = await repo.listMembers(widget.companyId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingMembers = false;
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _membersError = e.message;
      });
    }
  }

  CompanyMembership? get _membership {
    final list = ref.read(companyListControllerProvider).memberships;
    for (final m in list) {
      if (m.company.id == widget.companyId) return m;
    }
    return null;
  }

  Future<void> _invite() async {
    final membership = _membership;
    if (membership == null) return;
    if (!CompanyPermissionService.can(
      membership.role,
      CompanyPermission.manageMembers,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo un administrador puede invitar miembros.'),
        ),
      );
      return;
    }

    final emailController = TextEditingController();
    var role = CompanyRole.companyViewer;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: FletegoSpacing.lg,
            right: FletegoSpacing.lg,
            top: FletegoSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + FletegoSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invitar miembro',
                    style: FletegoTypography.textTheme.titleLarge,
                  ),
                  const SizedBox(height: FletegoSpacing.xs),
                  Text(
                    'Debe tener una cuenta FLETEGO con ese correo.',
                    style: FletegoTypography.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: FletegoSpacing.md),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                  ),
                  const SizedBox(height: FletegoSpacing.md),
                  DropdownButtonFormField<CompanyRole>(
                    // ignore: deprecated_member_use
                    value: role,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: CompanyRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.labelEs),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => role = v);
                    },
                  ),
                  const SizedBox(height: FletegoSpacing.lg),
                  FletegoButton(
                    label: 'Invitar',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      emailController.dispose();
      return;
    }

    final repo = ref.read(companyRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.inviteByEmail(
        companyId: widget.companyId,
        email: emailController.text,
        role: role,
      );
      emailController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miembro agregado correctamente.')),
      );
      await _loadMembers();
    } on AppFailure catch (e) {
      emailController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _changeRole(CompanyMember member) async {
    final membership = _membership;
    if (membership == null ||
        !CompanyPermissionService.can(
          membership.role,
          CompanyPermission.manageMembers,
        )) {
      return;
    }

    final currentUserId = ref.read(authControllerProvider).user?.id;
    if (member.userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes cambiar tu propio rol desde aquí.'),
        ),
      );
      return;
    }

    final role = await showModalBottomSheet<CompanyRole>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Rol de ${member.displayName}',
                  style: FletegoTypography.textTheme.titleMedium,
                ),
              ),
              ...CompanyRole.values.map(
                (r) => ListTile(
                  title: Text(r.labelEs),
                  trailing: member.role == r
                      ? const Icon(Icons.check, color: FletegoColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, r),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (role == null || role == member.role) return;
    final repo = ref.read(companyRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.updateMemberRole(memberId: member.id, role: role);
      await _loadMembers();
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(companyListControllerProvider);
    CompanyMembership? membership;
    for (final m in listState.memberships) {
      if (m.company.id == widget.companyId) {
        membership = m;
        break;
      }
    }

    final company = membership?.company;
    final canManage =
        membership != null &&
        CompanyPermissionService.can(
          membership.role,
          CompanyPermission.manageMembers,
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(company?.name ?? 'Empresa'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Invitar',
              onPressed: _invite,
              icon: const Icon(Icons.person_add_alt_1),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FletegoSpacing.lg),
          children: [
            if (company != null) ...[
              FletegoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: FletegoTypography.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      company.companyType.labelEs,
                      style: FletegoTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: FletegoSpacing.sm),
                    FletegoStatusBadge(
                      label: company.verificationStatus.labelEs,
                      tone:
                          company.verificationStatus ==
                              VerificationStatus.approved
                          ? FletegoBadgeTone.success
                          : FletegoBadgeTone.neutral,
                    ),
                    if (company.nit != null && company.nit!.isNotEmpty) ...[
                      const SizedBox(height: FletegoSpacing.sm),
                      Text(
                        'NIT: ${company.nit}',
                        style: FletegoTypography.textTheme.bodySmall,
                      ),
                    ],
                    if (membership != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tu rol: ${membership.role.labelEs}',
                        style: FletegoTypography.textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: FletegoSpacing.xl),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Miembros',
                    style: FletegoTypography.textTheme.titleMedium,
                  ),
                ),
                if (canManage)
                  TextButton(onPressed: _invite, child: const Text('Invitar')),
              ],
            ),
            const SizedBox(height: FletegoSpacing.sm),
            if (_loadingMembers)
              const FletegoLoadingState(message: 'Cargando miembros...')
            else if (_membersError != null)
              FletegoErrorState(message: _membersError!, onRetry: _loadMembers)
            else if (_members.isEmpty)
              const FletegoEmptyState(
                title: 'Sin miembros',
                message: 'Invita a operadores o conductores de tu equipo.',
              )
            else
              ..._members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: FletegoSpacing.sm),
                  child: FletegoCard(
                    onTap: canManage ? () => _changeRole(m) : null,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: FletegoColors.surfaceMuted,
                          child: Text(
                            m.displayName.isNotEmpty
                                ? m.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: FletegoColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: FletegoSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.displayName,
                                style: FletegoTypography.textTheme.titleSmall,
                              ),
                              Text(
                                m.email ?? m.role.labelEs,
                                style: FletegoTypography.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FletegoStatusBadge(
                          label: m.role.labelEs,
                          tone: FletegoBadgeTone.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

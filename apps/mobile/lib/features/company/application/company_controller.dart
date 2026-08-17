import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/enums/company_enums.dart';
import '../../auth/application/auth_controller.dart';
import '../data/company_repository.dart';
import '../domain/company.dart';
import '../domain/company_permission_service.dart';

final companyRepositoryProvider = Provider<CompanyRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return CompanyRepository(client);
});

class CompanyListState {
  const CompanyListState({
    this.memberships = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CompanyMembership> memberships;
  final bool isLoading;
  final String? error;

  CompanyMembership? get primary =>
      memberships.isEmpty ? null : memberships.first;

  CompanyListState copyWith({
    List<CompanyMembership>? memberships,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CompanyListState(
      memberships: memberships ?? this.memberships,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CompanyListController extends Notifier<CompanyListState> {
  @override
  CompanyListState build() {
    ref.listen<AuthSessionState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        refresh();
      } else if (next.status == AuthStatus.unauthenticated) {
        state = const CompanyListState();
      }
    });

    Future.microtask(refresh);
    return const CompanyListState(isLoading: true);
  }

  CompanyRepository? get _repo => ref.read(companyRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    if (repo == null) {
      state = const CompanyListState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final memberships = await repo.listMyMemberships();
      state = CompanyListState(memberships: memberships);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos cargar tus empresas.',
      );
    }
  }

  Future<Company?> createCompany({
    required String name,
    required CompanyType companyType,
    String? legalName,
    String? nit,
    String? phone,
    String? email,
    String? address,
  }) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(error: 'Supabase no está configurado.');
      return null;
    }

    try {
      final company = await repo.createCompany(
        name: name,
        companyType: companyType,
        legalName: legalName,
        nit: nit,
        phone: phone,
        email: email,
        address: address,
      );
      await refresh();
      return company;
    } on AppFailure catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    }
  }
}

final companyListControllerProvider =
    NotifierProvider<CompanyListController, CompanyListState>(
      CompanyListController.new,
    );

class SelectedCompanyId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedCompanyIdProvider = NotifierProvider<SelectedCompanyId, String?>(
  SelectedCompanyId.new,
);

final activeMembershipProvider = Provider<CompanyMembership?>((ref) {
  final list = ref.watch(companyListControllerProvider);
  final selectedId = ref.watch(selectedCompanyIdProvider);
  if (list.memberships.isEmpty) return null;
  if (selectedId == null) return list.primary;
  for (final m in list.memberships) {
    if (m.company.id == selectedId) return m;
  }
  return list.primary;
});

final canManageMembersProvider = Provider<bool>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  if (membership == null) return false;
  return CompanyPermissionService.can(
    membership.role,
    CompanyPermission.manageMembers,
  );
});

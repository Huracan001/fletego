import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../shared/enums/company_enums.dart';
import '../domain/company.dart';
import '../domain/company_driver.dart';

class CompanyRepository {
  CompanyRepository(this._client);

  final SupabaseClient _client;

  Future<List<CompanyMembership>> listMyMemberships() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthFailure('Debes iniciar sesión.');
    }

    try {
      final rows = await _client
          .from('company_members')
          .select('id, role, company_id, companies(*)')
          .eq('user_id', uid)
          .filter('deleted_at', 'is', null);

      final result = <CompanyMembership>[];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final companyRaw = map['companies'];
        if (companyRaw is! Map) continue;
        final companyMap = Map<String, dynamic>.from(companyRaw);
        if (companyMap['deleted_at'] != null) continue;

        result.add(
          CompanyMembership(
            company: Company.fromJson(companyMap),
            role: CompanyRole.fromDb(
              map['role'] as String? ?? 'company_viewer',
            ),
            memberId: map['id'] as String,
          ),
        );
      }
      return result;
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar tus empresas.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<Company> createCompany({
    required String name,
    required CompanyType companyType,
    String? legalName,
    String? nit,
    String? phone,
    String? email,
    String? address,
    String countryCode = 'BO',
  }) async {
    try {
      final row = await _client.rpc(
        'create_company',
        params: {
          'p_name': name,
          'p_company_type': companyType.dbValue,
          'p_legal_name': legalName,
          'p_nit': nit,
          'p_phone': phone,
          'p_email': email,
          'p_address': address,
          'p_country_code': countryCode,
        },
      );

      if (row is Map) {
        return Company.fromJson(Map<String, dynamic>.from(row));
      }
      if (row is List && row.isNotEmpty && row.first is Map) {
        return Company.fromJson(Map<String, dynamic>.from(row.first as Map));
      }
      throw const UnexpectedFailure('Respuesta inválida al crear la empresa.');
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos crear la empresa.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<CompanyMember>> listMembers(String companyId) async {
    try {
      // Prefer RPC (avoids ambiguous profiles FKs: user_id vs invited_by).
      final rows = await _client.rpc(
        'list_company_members',
        params: {'p_company_id': companyId},
      );

      return (rows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return CompanyMember(
          id: map['id'] as String,
          companyId: map['company_id'] as String,
          userId: map['user_id'] as String,
          role: CompanyRole.fromDb(map['role'] as String? ?? 'company_viewer'),
          fullName:
              (map['full_name'] as String?) ?? (map['display_name'] as String?),
          email: map['email'] as String?,
          joinedAt: map['joined_at'] == null
              ? null
              : DateTime.tryParse(map['joined_at'] as String),
        );
      }).toList();
    } on PostgrestException catch (e) {
      // Fallback if RPC not applied yet: members without profile embed.
      if (e.code == 'PGRST202' ||
          e.message.toLowerCase().contains('list_company_members') ||
          e.message.toLowerCase().contains('could not find')) {
        return _listMembersWithoutProfiles(companyId);
      }
      throw NetworkFailure(
        'No pudimos cargar los miembros.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<CompanyMember>> _listMembersWithoutProfiles(
    String companyId,
  ) async {
    try {
      final rows = await _client
          .from('company_members')
          .select('id, company_id, user_id, role, joined_at')
          .eq('company_id', companyId)
          .filter('deleted_at', 'is', null)
          .order('joined_at');

      return (rows as List)
          .map(
            (row) =>
                CompanyMember.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar los miembros.', e);
    }
  }

  Future<CompanyMember> inviteByEmail({
    required String companyId,
    required String email,
    required CompanyRole role,
  }) async {
    try {
      final row = await _client.rpc(
        'add_company_member_by_email',
        params: {
          'p_company_id': companyId,
          'p_email': email.trim(),
          'p_role': role.dbValue,
        },
      );

      Map<String, dynamic> memberMap;
      if (row is Map) {
        memberMap = Map<String, dynamic>.from(row);
      } else if (row is List && row.isNotEmpty && row.first is Map) {
        memberMap = Map<String, dynamic>.from(row.first as Map);
      } else {
        throw const UnexpectedFailure('No pudimos invitar al usuario.');
      }

      final members = await listMembers(companyId);
      final match = members.where((m) => m.userId == memberMap['user_id']);
      if (match.isNotEmpty) return match.first;

      return CompanyMember.fromJson(memberMap);
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('user_not_found')) {
        throw const NotFoundFailure(
          'No hay una cuenta FLETEGO con ese correo. La persona debe registrarse primero.',
        );
      }
      if (msg.contains('not allowed')) {
        throw const PermissionFailure(
          'Solo un administrador puede invitar miembros.',
        );
      }
      throw NetworkFailure('No pudimos invitar al miembro.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> updateMemberRole({
    required String memberId,
    required CompanyRole role,
  }) async {
    try {
      await _client
          .from('company_members')
          .update({'role': role.dbValue})
          .eq('id', memberId);
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos actualizar el rol.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      await _client
          .from('company_members')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', memberId);
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos quitar al miembro.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<CompanyDriver>> listDrivers(String companyId) async {
    try {
      final rows = await _client.rpc(
        'list_company_drivers',
        params: {'p_company_id': companyId},
      );
      return (rows as List)
          .map(
            (r) => CompanyDriver.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code == 'PGRST202' ||
          msg.contains('list_company_drivers') ||
          msg.contains('could not find')) {
        return const [];
      }
      throw NetworkFailure(
        'No pudimos cargar los conductores.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }
}

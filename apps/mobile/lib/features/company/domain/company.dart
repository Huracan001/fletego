import 'package:equatable/equatable.dart';

import '../../../shared/enums/company_enums.dart';

class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.companyType,
    required this.verificationStatus,
    required this.createdBy,
    required this.countryCode,
    this.legalName,
    this.nit,
    this.phone,
    this.email,
    this.address,
  });

  final String id;
  final String name;
  final String? legalName;
  final String? nit;
  final String countryCode;
  final CompanyType companyType;
  final String? phone;
  final String? email;
  final String? address;
  final VerificationStatus verificationStatus;
  final String createdBy;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      nit: json['nit'] as String?,
      countryCode: json['country_code'] as String? ?? 'BO',
      companyType: CompanyType.fromDb(
        json['company_type'] as String? ?? 'both',
      ),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      verificationStatus: VerificationStatus.fromDb(
        json['verification_status'] as String?,
      ),
      createdBy: json['created_by'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name, companyType, verificationStatus];
}

class CompanyMember extends Equatable {
  const CompanyMember({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    this.fullName,
    this.email,
    this.joinedAt,
  });

  final String id;
  final String companyId;
  final String userId;
  final CompanyRole role;
  final String? fullName;
  final String? email;
  final DateTime? joinedAt;

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    Map<String, dynamic>? profileMap;
    if (profile is Map<String, dynamic>) {
      profileMap = profile;
    }

    return CompanyMember(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      role: CompanyRole.fromDb(json['role'] as String? ?? 'company_viewer'),
      fullName:
          profileMap?['full_name'] as String? ??
          profileMap?['display_name'] as String?,
      email: profileMap?['email'] as String?,
      joinedAt: json['joined_at'] == null
          ? null
          : DateTime.tryParse(json['joined_at'] as String),
    );
  }

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'Usuario';
  }

  @override
  List<Object?> get props => [id, companyId, userId, role];
}

class CompanyMembership extends Equatable {
  const CompanyMembership({
    required this.company,
    required this.role,
    required this.memberId,
  });

  final Company company;
  final CompanyRole role;
  final String memberId;

  @override
  List<Object?> get props => [company.id, role, memberId];
}

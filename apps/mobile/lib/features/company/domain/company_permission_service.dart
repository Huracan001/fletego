import '../../../shared/enums/company_enums.dart';

/// Central permission matrix — never hard-code checks inside random widgets.
enum CompanyPermission {
  viewCompany,
  manageCompany,
  manageMembers,
  manageVehicles,
  manageDrivers,
  manageTrips,
  viewReports,
  manageFinance,
}

abstract final class CompanyPermissionService {
  const CompanyPermissionService._();

  static Set<CompanyPermission> permissionsFor(CompanyRole role) {
    return switch (role) {
      CompanyRole.companyAdmin => CompanyPermission.values.toSet(),
      CompanyRole.companyOperator => {
        CompanyPermission.viewCompany,
        CompanyPermission.manageVehicles,
        CompanyPermission.manageDrivers,
        CompanyPermission.manageTrips,
        CompanyPermission.viewReports,
      },
      CompanyRole.dispatcher => {
        CompanyPermission.viewCompany,
        CompanyPermission.manageTrips,
        CompanyPermission.viewReports,
      },
      CompanyRole.companyFinance => {
        CompanyPermission.viewCompany,
        CompanyPermission.viewReports,
        CompanyPermission.manageFinance,
      },
      CompanyRole.companyViewer => {
        CompanyPermission.viewCompany,
        CompanyPermission.viewReports,
      },
    };
  }

  static bool can(CompanyRole role, CompanyPermission permission) {
    return permissionsFor(role).contains(permission);
  }
}

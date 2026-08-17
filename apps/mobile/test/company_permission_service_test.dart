import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/company/domain/company_permission_service.dart';
import 'package:fletego/shared/enums/company_enums.dart';

void main() {
  test('company_admin has all permissions', () {
    final perms = CompanyPermissionService.permissionsFor(
      CompanyRole.companyAdmin,
    );
    expect(perms, containsAll(CompanyPermission.values));
  });

  test('company_viewer cannot manage members', () {
    expect(
      CompanyPermissionService.can(
        CompanyRole.companyViewer,
        CompanyPermission.manageMembers,
      ),
      isFalse,
    );
  });

  test('dispatcher can manage trips but not members', () {
    expect(
      CompanyPermissionService.can(
        CompanyRole.dispatcher,
        CompanyPermission.manageTrips,
      ),
      isTrue,
    );
    expect(
      CompanyPermissionService.can(
        CompanyRole.dispatcher,
        CompanyPermission.manageMembers,
      ),
      isFalse,
    );
  });

  test('operator can manage vehicles and drivers', () {
    expect(
      CompanyPermissionService.can(
        CompanyRole.companyOperator,
        CompanyPermission.manageVehicles,
      ),
      isTrue,
    );
    expect(
      CompanyPermissionService.can(
        CompanyRole.companyOperator,
        CompanyPermission.manageDrivers,
      ),
      isTrue,
    );
  });

  test('CompanyRole dbValue roundtrip', () {
    for (final role in CompanyRole.values) {
      expect(CompanyRole.fromDb(role.dbValue), role);
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/vehicles/domain/vehicle_models.dart';
import 'package:fletego/shared/enums/vehicle_enums.dart';

void main() {
  test('Vehicle.fromJson maps nested vehicle type', () {
    final vehicle = Vehicle.fromJson({
      'id': 'v1',
      'owner_profile_id': 'u1',
      'vehicle_type_id': 't1',
      'plate': '1234ABC',
      'country_code': 'BO',
      'max_cargo_kg': 25000,
      'verification_status': 'pending',
      'availability_status': 'available',
      'vehicle_types': {
        'id': 't1',
        'code': 'sider',
        'name_es': 'Sider',
        'name_en': 'Curtain sider',
        'typical_max_weight_kg': 25000,
        'supports_container': false,
        'supports_refrigeration': false,
      },
    });

    expect(vehicle.plate, '1234ABC');
    expect(vehicle.availabilityStatus, AvailabilityStatus.available);
    expect(vehicle.vehicleType?.nameEs, 'Sider');
    expect(vehicle.title, 'Sider · 1234ABC');
  });

  test('AvailabilityStatus db roundtrip', () {
    for (final status in AvailabilityStatus.values) {
      expect(AvailabilityStatus.fromDb(status.dbValue), status);
    }
  });
}

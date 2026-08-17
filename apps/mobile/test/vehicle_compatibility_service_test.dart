import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/cargo/domain/vehicle_compatibility_service.dart';
import 'package:fletego/features/vehicles/domain/vehicle_models.dart';
import 'package:fletego/shared/enums/cargo_enums.dart';

VehicleType _type(String code, String name) =>
    VehicleType(id: code, code: code, nameEs: name, nameEn: name);

void main() {
  final types = [
    _type('portacontenedor', 'Portacontenedor'),
    _type('cisterna', 'Cisterna'),
    _type('ciguena', 'Cigüeña'),
    _type('sider', 'Sider'),
    _type('refrigerado', 'Refrigerado'),
    _type('cama_baja', 'Cama baja'),
    _type('semirremolque', 'Semirremolque'),
    _type('camion_rigido', 'Camión rígido'),
  ];

  test('recommends portacontenedor for containers', () {
    final rec = VehicleCompatibilityService.recommend(
      types: types,
      cargoType: CargoType.contenedor,
      containerSize: ContainerSize.ft40,
    );
    expect(rec?.vehicleType.code, 'portacontenedor');
  });

  test('recommends cisterna for liquids', () {
    final rec = VehicleCompatibilityService.recommend(
      types: types,
      cargoType: CargoType.liquidos,
    );
    expect(rec?.vehicleType.code, 'cisterna');
  });

  test('recommends refrigerated when cold chain required', () {
    final rec = VehicleCompatibilityService.recommend(
      types: types,
      cargoType: CargoType.cargaGeneral,
      requiresRefrigeration: true,
    );
    expect(rec?.vehicleType.code, 'refrigerado');
  });

  test('recommends sider for general cargo', () {
    final rec = VehicleCompatibilityService.recommend(
      types: types,
      cargoType: CargoType.cargaGeneral,
      weightKg: 8000,
      requiresTarp: true,
    );
    expect(rec?.vehicleType.code, 'sider');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/offers/domain/matching_service.dart';
import 'package:fletego/features/offers/domain/offer_models.dart';
import 'package:fletego/features/vehicles/domain/vehicle_models.dart';
import 'package:fletego/shared/enums/cargo_enums.dart';
import 'package:fletego/shared/enums/company_enums.dart';
import 'package:fletego/shared/enums/offer_enums.dart';
import 'package:fletego/shared/enums/vehicle_enums.dart';

Vehicle _vehicle({
  required String typeId,
  double? capacityKg,
  bool refrigeration = false,
  bool dg = false,
  bool tarp = false,
}) {
  return Vehicle(
    id: 'v1',
    vehicleTypeId: typeId,
    plate: 'ABC123',
    countryCode: 'BO',
    verificationStatus: VerificationStatus.pending,
    availabilityStatus: AvailabilityStatus.available,
    capacityKg: capacityKg,
    maxCargoKg: capacityKg,
    hasRefrigeration: refrigeration,
    acceptsDangerousGoods: dg,
    hasTarp: tarp,
  );
}

MarketplaceLoad _load({
  String? requestedType,
  double? weight,
  bool cold = false,
  bool dg = false,
  CargoType cargo = CargoType.cargaGeneral,
}) {
  return MarketplaceLoad(
    id: 'r1',
    status: RequestStatus.matching,
    cargoType: cargo,
    originCity: 'Santa Cruz de la Sierra',
    destinationCity: 'Cochabamba',
    createdAt: DateTime(2026, 8, 1),
    originLat: -17.7833,
    originLng: -63.1821,
    totalWeightKg: weight,
    requiresRefrigeration: cold,
    dangerousGoods: dg,
    requestedVehicleTypeId: requestedType,
  );
}

void main() {
  final sider = VehicleType(
    id: 'sider',
    code: 'sider',
    nameEs: 'Sider',
    nameEn: 'Curtain sider',
    typicalMaxWeightKg: 25000,
  );
  final reefer = VehicleType(
    id: 'refrigerado',
    code: 'refrigerado',
    nameEs: 'Refrigerado',
    nameEn: 'Reefer',
    supportsRefrigeration: true,
    typicalMaxWeightKg: 20000,
  );

  test('scores higher when vehicle type matches request', () {
    final match = MatchingService.score(
      vehicle: _vehicle(typeId: 'sider', capacityKg: 20000),
      vehicleType: sider,
      load: _load(requestedType: 'sider', weight: 10000),
    );
    final other = MatchingService.score(
      vehicle: _vehicle(typeId: 'camion_rigido', capacityKg: 20000),
      vehicleType: sider,
      load: _load(requestedType: 'sider', weight: 10000),
    );
    expect(match.eligible, isTrue);
    expect(match.score, greaterThan(other.score));
  });

  test('blocks overweight loads', () {
    final result = MatchingService.score(
      vehicle: _vehicle(typeId: 'sider', capacityKg: 5000),
      vehicleType: sider,
      load: _load(requestedType: 'sider', weight: 12000),
    );
    expect(result.eligible, isFalse);
    expect(result.blockers, isNotEmpty);
  });

  test('requires refrigeration when needed', () {
    final bad = MatchingService.score(
      vehicle: _vehicle(typeId: 'sider', capacityKg: 15000),
      vehicleType: sider,
      load: _load(weight: 5000, cold: true),
    );
    final good = MatchingService.score(
      vehicle: _vehicle(
        typeId: 'refrigerado',
        capacityKg: 15000,
        refrigeration: true,
      ),
      vehicleType: reefer,
      load: _load(weight: 5000, cold: true),
    );
    expect(bad.eligible, isFalse);
    expect(good.eligible, isTrue);
  });

  test('ranks eligible loads by score', () {
    final vehicle = _vehicle(typeId: 'sider', capacityKg: 20000);
    final ranked = MatchingService.rankLoads(
      vehicle: vehicle,
      vehicleType: sider,
      loads: [
        MarketplaceLoad(
          id: 'best',
          status: RequestStatus.matching,
          cargoType: CargoType.cargaGeneral,
          originCity: 'La Paz',
          destinationCity: 'Oruro',
          createdAt: DateTime(2026, 8, 2),
          totalWeightKg: 1000,
          requestedVehicleTypeId: 'sider',
        ),
        MarketplaceLoad(
          id: 'heavy',
          status: RequestStatus.matching,
          cargoType: CargoType.cargaGeneral,
          originCity: 'Sucre',
          destinationCity: 'Potosí',
          createdAt: DateTime(2026, 8, 3),
          totalWeightKg: 50000,
          requestedVehicleTypeId: 'sider',
        ),
      ],
      eligibleOnly: true,
    );
    expect(ranked.map((e) => e.load.id), ['best']);
  });

  test('sorts offers by pending then price', () {
    final offers = MatchingService.sortOffers([
      Offer(
        id: 'a',
        requestId: 'r',
        transporterProfileId: 't',
        vehicleId: 'v',
        priceAmount: 900,
        currency: 'BOB',
        status: OfferStatus.rejected,
        createdAt: DateTime(2026, 1, 1),
      ),
      Offer(
        id: 'b',
        requestId: 'r',
        transporterProfileId: 't',
        vehicleId: 'v',
        priceAmount: 800,
        currency: 'BOB',
        status: OfferStatus.pending,
        createdAt: DateTime(2026, 1, 2),
      ),
      Offer(
        id: 'c',
        requestId: 'r',
        transporterProfileId: 't',
        vehicleId: 'v',
        priceAmount: 700,
        currency: 'BOB',
        status: OfferStatus.pending,
        createdAt: DateTime(2026, 1, 3),
      ),
    ]);
    expect(offers.map((e) => e.id).toList(), ['c', 'b', 'a']);
  });

  test('haversine Santa Cruz to Cochabamba is ~300km class', () {
    final km = MatchingService.haversineKm(
      -17.7833,
      -63.1821,
      -17.3895,
      -66.1568,
    );
    expect(km, greaterThan(250));
    expect(km, lessThan(400));
  });
}

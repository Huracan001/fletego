import 'dart:math' as math;

import '../../../shared/enums/cargo_enums.dart';
import '../../../shared/enums/company_enums.dart';
import '../../../shared/enums/offer_enums.dart';
import '../../../shared/enums/vehicle_enums.dart';
import '../../vehicles/domain/vehicle_models.dart';
import 'offer_models.dart';

class MatchScore {
  const MatchScore({
    required this.score,
    required this.eligible,
    this.reasons = const [],
    this.blockers = const [],
    this.distanceKm,
  });

  final int score;
  final bool eligible;
  final List<String> reasons;
  final List<String> blockers;
  final double? distanceKm;
}

/// Deterministic load ↔ vehicle scoring. Swap/augment with AI later.
abstract final class MatchingService {
  const MatchingService._();

  static MatchScore score({
    required Vehicle vehicle,
    required MarketplaceLoad load,
    VehicleType? vehicleType,
    DriverProfile? driver,
    DriverAvailability? availability,
    double? driverLat,
    double? driverLng,
  }) {
    final type = vehicleType ?? vehicle.vehicleType;
    final reasons = <String>[];
    final blockers = <String>[];
    var points = 0;

    // 1) Vehicle type
    final requested = load.requestedVehicleTypeId;
    final recommended = load.recommendedVehicleTypeId;
    if (requested != null && requested == vehicle.vehicleTypeId) {
      points += 40;
      reasons.add('Tipo solicitado');
    } else if (recommended != null && recommended == vehicle.vehicleTypeId) {
      points += 30;
      reasons.add('Coincide con recomendación');
    } else if (requested == null && recommended == null) {
      points += 15;
    } else {
      points += 5;
    }

    // 2) Weight capacity
    final capacity =
        vehicle.maxCargoKg ??
        vehicle.capacityKg ??
        type?.typicalMaxWeightKg;
    final weight = load.totalWeightKg;
    if (weight != null && capacity != null) {
      if (capacity >= weight) {
        points += 20;
        reasons.add('Capacidad OK');
      } else {
        blockers.add('Peso supera capacidad (${capacity.toStringAsFixed(0)} kg)');
      }
    } else {
      points += 8;
    }

    // 3) Special equipment
    if (load.requiresRefrigeration) {
      final cold =
          vehicle.hasRefrigeration || (type?.supportsRefrigeration ?? false);
      if (cold) {
        points += 15;
        reasons.add('Refrigeración');
      } else {
        blockers.add('Requiere refrigeración');
      }
    }

    if (load.dangerousGoods) {
      if (vehicle.acceptsDangerousGoods) {
        points += 10;
        reasons.add('Carga peligrosa aceptada');
      } else {
        blockers.add('No acepta carga peligrosa');
      }
    }

    if (load.requiresTarp) {
      if (vehicle.hasTarp) {
        points += 5;
        reasons.add('Lona');
      }
    }

    if (load.cargoType == CargoType.contenedor) {
      if (type?.supportsContainer == true) {
        points += 15;
        reasons.add('Soporta contenedor');
      } else {
        blockers.add('No soporta contenedores');
      }
    }

    // 4) Availability
    if (availability?.status == AvailabilityStatus.available) {
      if (availability!.vehicleId == vehicle.id) {
        points += 10;
        reasons.add('Disponible con este camión');
      } else {
        points += 4;
      }
    }

    // 5) Verification
    if (driver?.verificationStatus == VerificationStatus.approved) {
      points += 5;
      reasons.add('Conductor verificado');
    }

    // 6) Proximity / deadhead
    double? distanceKm;
    if (driverLat != null &&
        driverLng != null &&
        load.originLat != null &&
        load.originLng != null) {
      distanceKm = haversineKm(
        driverLat,
        driverLng,
        load.originLat!,
        load.originLng!,
      );
      if (distanceKm <= 50) {
        points += 15;
        reasons.add('Cerca del origen (~${distanceKm.toStringAsFixed(0)} km)');
      } else if (distanceKm <= 150) {
        points += 8;
        reasons.add('Radio medio (~${distanceKm.toStringAsFixed(0)} km)');
      } else if (distanceKm <= 300) {
        points += 3;
      }

      final maxDeadhead = availability?.maxDeadheadKm;
      if (maxDeadhead != null && distanceKm > maxDeadhead) {
        blockers.add('Fuera de tu radio de vacío (${maxDeadhead.toStringAsFixed(0)} km)');
      }
    }

    // 7) Return-load preference (soft)
    if (driver?.acceptsReturnLoads == true &&
        availability?.acceptsReturnCargo == true) {
      points += 2;
    }

    final clamped = points.clamp(0, 100);
    return MatchScore(
      score: clamped,
      eligible: blockers.isEmpty,
      reasons: reasons,
      blockers: blockers,
      distanceKm: distanceKm,
    );
  }

  static List<RankedLoad> rankLoads({
    required List<MarketplaceLoad> loads,
    required Vehicle vehicle,
    VehicleType? vehicleType,
    DriverProfile? driver,
    DriverAvailability? availability,
    double? driverLat,
    double? driverLng,
    bool eligibleOnly = true,
  }) {
    final ranked = <RankedLoad>[];
    for (final load in loads) {
      final result = score(
        vehicle: vehicle,
        load: load,
        vehicleType: vehicleType,
        driver: driver,
        availability: availability,
        driverLat: driverLat,
        driverLng: driverLng,
      );
      if (eligibleOnly && !result.eligible) continue;
      ranked.add(
        RankedLoad(
          load: load,
          score: result.score,
          eligible: result.eligible,
          reasons: result.reasons,
          blockers: result.blockers,
        ),
      );
    }
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.load.createdAt.compareTo(a.load.createdAt);
    });
    return ranked;
  }

  static List<Offer> sortOffers(List<Offer> offers) {
    final copy = List<Offer>.from(offers);
    copy.sort((a, b) {
      final statusRank = _offerRank(a.status).compareTo(_offerRank(b.status));
      if (statusRank != 0) return statusRank;
      final byPrice = a.priceAmount.compareTo(b.priceAmount);
      if (byPrice != 0) return byPrice;
      return a.createdAt.compareTo(b.createdAt);
    });
    return copy;
  }

  static int _offerRank(OfferStatus status) => switch (status) {
    OfferStatus.pending => 0,
    OfferStatus.accepted => 1,
    OfferStatus.rejected => 2,
    OfferStatus.withdrawn => 3,
    OfferStatus.expired => 4,
  };

  /// Great-circle distance in km.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

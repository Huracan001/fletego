import 'package:equatable/equatable.dart';

import '../../../shared/enums/cargo_enums.dart';
import '../../../shared/enums/offer_enums.dart';

class MarketplaceLoad extends Equatable {
  const MarketplaceLoad({
    required this.id,
    required this.status,
    required this.cargoType,
    required this.originCity,
    required this.destinationCity,
    required this.createdAt,
    this.originAdminArea,
    this.destinationAdminArea,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.totalWeightKg,
    this.lengthM,
    this.widthM,
    this.heightM,
    this.requiresTarp = false,
    this.requiresRefrigeration = false,
    this.dangerousGoods = false,
    this.requestedVehicleTypeId,
    this.recommendedVehicleTypeId,
    this.specialInstructions,
    this.scheduleMode,
  });

  final String id;
  final RequestStatus status;
  final CargoType cargoType;
  final String originCity;
  final String destinationCity;
  final String? originAdminArea;
  final String? destinationAdminArea;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime createdAt;
  final double? totalWeightKg;
  final double? lengthM;
  final double? widthM;
  final double? heightM;
  final bool requiresTarp;
  final bool requiresRefrigeration;
  final bool dangerousGoods;
  final String? requestedVehicleTypeId;
  final String? recommendedVehicleTypeId;
  final String? specialInstructions;
  final ScheduleMode? scheduleMode;

  String get routeLabel => '$originCity → $destinationCity';

  factory MarketplaceLoad.fromJson(Map<String, dynamic> json) {
    return MarketplaceLoad(
      id: json['id'] as String,
      status: RequestStatus.fromDb(json['status'] as String?),
      cargoType: CargoType.fromDb(json['cargo_type'] as String?),
      originCity: json['origin_city'] as String? ?? '',
      destinationCity: json['destination_city'] as String? ?? '',
      originAdminArea: json['origin_admin_area'] as String?,
      destinationAdminArea: json['destination_admin_area'] as String?,
      originLat: (json['origin_lat'] as num?)?.toDouble(),
      originLng: (json['origin_lng'] as num?)?.toDouble(),
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble(),
      lengthM: (json['length_m'] as num?)?.toDouble(),
      widthM: (json['width_m'] as num?)?.toDouble(),
      heightM: (json['height_m'] as num?)?.toDouble(),
      requiresTarp: json['requires_tarp'] as bool? ?? false,
      requiresRefrigeration: json['requires_refrigeration'] as bool? ?? false,
      dangerousGoods: json['dangerous_goods'] as bool? ?? false,
      requestedVehicleTypeId: json['requested_vehicle_type_id'] as String?,
      recommendedVehicleTypeId: json['recommended_vehicle_type_id'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      scheduleMode: json['schedule_mode'] == null
          ? null
          : ScheduleMode.fromDb(json['schedule_mode'] as String?),
    );
  }

  @override
  List<Object?> get props => [id, status, originCity, destinationCity];
}

class Offer extends Equatable {
  const Offer({
    required this.id,
    required this.requestId,
    required this.transporterProfileId,
    required this.vehicleId,
    required this.priceAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.companyId,
    this.driverProfileId,
    this.etaPickupAt,
    this.message,
    this.distanceKmEstimate,
  });

  final String id;
  final String requestId;
  final String transporterProfileId;
  final String? companyId;
  final String? driverProfileId;
  final String vehicleId;
  final double priceAmount;
  final String currency;
  final OfferStatus status;
  final DateTime? etaPickupAt;
  final String? message;
  final double? distanceKmEstimate;
  final DateTime createdAt;

  String get priceLabel =>
      '${priceAmount.toStringAsFixed(0)} $currency';

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      transporterProfileId: json['transporter_profile_id'] as String,
      companyId: json['company_id'] as String?,
      driverProfileId: json['driver_profile_id'] as String?,
      vehicleId: json['vehicle_id'] as String,
      priceAmount: (json['price_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'BOB',
      status: OfferStatus.fromDb(json['status'] as String?),
      etaPickupAt: json['eta_pickup_at'] == null
          ? null
          : DateTime.tryParse(json['eta_pickup_at'] as String),
      message: json['message'] as String?,
      distanceKmEstimate: (json['distance_km_estimate'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, requestId, status, priceAmount];
}

class TripBootstrap extends Equatable {
  const TripBootstrap({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.status,
  });

  final String id;
  final String requestId;
  final String offerId;
  final String status;

  factory TripBootstrap.fromJson(Map<String, dynamic> json) {
    return TripBootstrap(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      offerId: json['offer_id'] as String,
      status: json['status'] as String? ?? 'assigned',
    );
  }

  @override
  List<Object?> get props => [id, requestId, offerId];
}

class RankedLoad extends Equatable {
  const RankedLoad({
    required this.load,
    required this.score,
    required this.eligible,
    this.reasons = const [],
    this.blockers = const [],
  });

  final MarketplaceLoad load;
  final int score;
  final bool eligible;
  final List<String> reasons;
  final List<String> blockers;

  @override
  List<Object?> get props => [load.id, score, eligible];
}

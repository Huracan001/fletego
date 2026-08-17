import 'package:equatable/equatable.dart';

import '../../../shared/enums/cargo_enums.dart';
import '../../vehicles/domain/vehicle_models.dart';

class PlaceDraft extends Equatable {
  const PlaceDraft({
    this.countryCode = 'BO',
    this.adminArea,
    this.city = '',
    this.addressLine,
    this.label,
    this.lat,
    this.lng,
    this.instructions,
  });

  final String countryCode;
  final String? adminArea;
  final String city;
  final String? addressLine;
  final String? label;
  final double? lat;
  final double? lng;
  final String? instructions;

  bool get isValid => city.trim().isNotEmpty;

  PlaceDraft copyWith({
    String? countryCode,
    String? adminArea,
    String? city,
    String? addressLine,
    String? label,
    double? lat,
    double? lng,
    String? instructions,
  }) {
    return PlaceDraft(
      countryCode: countryCode ?? this.countryCode,
      adminArea: adminArea ?? this.adminArea,
      city: city ?? this.city,
      addressLine: addressLine ?? this.addressLine,
      label: label ?? this.label,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toPayload(String prefix) {
    return {
      '${prefix}_country_code': countryCode,
      '${prefix}_admin_area': adminArea,
      '${prefix}_city': city.trim(),
      '${prefix}_address_line': addressLine,
      '${prefix}_label': label,
      '${prefix}_lat': lat?.toString(),
      '${prefix}_lng': lng?.toString(),
      '${prefix}_instructions': instructions,
    };
  }

  @override
  List<Object?> get props => [city, lat, lng, addressLine];
}

class ContainerDraft extends Equatable {
  const ContainerDraft({
    this.containerType = ContainerSize.ft40,
    this.containerNumber,
    this.grossWeightKg,
    this.refrigerated = false,
    this.dangerousGoods = false,
    this.bookingRef,
    this.blRef,
    this.shippingLine,
  });

  final ContainerSize containerType;
  final String? containerNumber;
  final double? grossWeightKg;
  final bool refrigerated;
  final bool dangerousGoods;
  final String? bookingRef;
  final String? blRef;
  final String? shippingLine;

  ContainerDraft copyWith({
    ContainerSize? containerType,
    String? containerNumber,
    double? grossWeightKg,
    bool? refrigerated,
    bool? dangerousGoods,
    String? bookingRef,
    String? blRef,
    String? shippingLine,
  }) {
    return ContainerDraft(
      containerType: containerType ?? this.containerType,
      containerNumber: containerNumber ?? this.containerNumber,
      grossWeightKg: grossWeightKg ?? this.grossWeightKg,
      refrigerated: refrigerated ?? this.refrigerated,
      dangerousGoods: dangerousGoods ?? this.dangerousGoods,
      bookingRef: bookingRef ?? this.bookingRef,
      blRef: blRef ?? this.blRef,
      shippingLine: shippingLine ?? this.shippingLine,
    );
  }

  Map<String, dynamic> toJson() => {
    'container_type': containerType.dbValue,
    'container_number': containerNumber,
    'gross_weight_kg': grossWeightKg?.toString(),
    'refrigerated': refrigerated,
    'dangerous_goods': dangerousGoods,
    'booking_ref': bookingRef,
    'bl_ref': blRef,
    'shipping_line': shippingLine,
  };

  @override
  List<Object?> get props => [containerType, containerNumber, grossWeightKg];
}

class CargoRequestDraft extends Equatable {
  const CargoRequestDraft({
    this.cargoType,
    this.origin = const PlaceDraft(),
    this.destination = const PlaceDraft(),
    this.totalWeightKg,
    this.lengthM,
    this.widthM,
    this.heightM,
    this.stackable = true,
    this.requiresTarp = false,
    this.requiresSpecialLoading = false,
    this.requiresRefrigeration = false,
    this.dangerousGoods = false,
    this.specialRequirements = const {},
    this.specialInstructions,
    this.container,
    this.unknownTruck = false,
    this.requestedVehicleTypeId,
    this.recommendedVehicleTypeId,
    this.scheduleMode = ScheduleMode.asap,
    this.pickupAt,
    this.pickupWindowStart,
    this.pickupWindowEnd,
  });

  final CargoType? cargoType;
  final PlaceDraft origin;
  final PlaceDraft destination;
  final double? totalWeightKg;
  final double? lengthM;
  final double? widthM;
  final double? heightM;
  final bool stackable;
  final bool requiresTarp;
  final bool requiresSpecialLoading;
  final bool requiresRefrigeration;
  final bool dangerousGoods;
  final Set<SpecialRequirement> specialRequirements;
  final String? specialInstructions;
  final ContainerDraft? container;
  final bool unknownTruck;
  final String? requestedVehicleTypeId;
  final String? recommendedVehicleTypeId;
  final ScheduleMode scheduleMode;
  final DateTime? pickupAt;
  final String? pickupWindowStart;
  final String? pickupWindowEnd;

  CargoRequestDraft copyWith({
    CargoType? cargoType,
    PlaceDraft? origin,
    PlaceDraft? destination,
    double? totalWeightKg,
    double? lengthM,
    double? widthM,
    double? heightM,
    bool? stackable,
    bool? requiresTarp,
    bool? requiresSpecialLoading,
    bool? requiresRefrigeration,
    bool? dangerousGoods,
    Set<SpecialRequirement>? specialRequirements,
    String? specialInstructions,
    ContainerDraft? container,
    bool? unknownTruck,
    String? requestedVehicleTypeId,
    String? recommendedVehicleTypeId,
    ScheduleMode? scheduleMode,
    DateTime? pickupAt,
    String? pickupWindowStart,
    String? pickupWindowEnd,
    bool clearRequestedVehicle = false,
  }) {
    return CargoRequestDraft(
      cargoType: cargoType ?? this.cargoType,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      lengthM: lengthM ?? this.lengthM,
      widthM: widthM ?? this.widthM,
      heightM: heightM ?? this.heightM,
      stackable: stackable ?? this.stackable,
      requiresTarp: requiresTarp ?? this.requiresTarp,
      requiresSpecialLoading:
          requiresSpecialLoading ?? this.requiresSpecialLoading,
      requiresRefrigeration:
          requiresRefrigeration ?? this.requiresRefrigeration,
      dangerousGoods: dangerousGoods ?? this.dangerousGoods,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      container: container ?? this.container,
      unknownTruck: unknownTruck ?? this.unknownTruck,
      requestedVehicleTypeId: clearRequestedVehicle
          ? null
          : (requestedVehicleTypeId ?? this.requestedVehicleTypeId),
      recommendedVehicleTypeId:
          recommendedVehicleTypeId ?? this.recommendedVehicleTypeId,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      pickupAt: pickupAt ?? this.pickupAt,
      pickupWindowStart: pickupWindowStart ?? this.pickupWindowStart,
      pickupWindowEnd: pickupWindowEnd ?? this.pickupWindowEnd,
    );
  }

  Map<String, dynamic> toSubmitPayload() {
    final reqs = specialRequirements.map((e) => e.dbValue).toList();
    return {
      'cargo_type': cargoType!.dbValue,
      'schedule_mode': scheduleMode.dbValue,
      'pickup_at': pickupAt?.toUtc().toIso8601String(),
      'pickup_window_start': pickupWindowStart,
      'pickup_window_end': pickupWindowEnd,
      ...origin.toPayload('origin'),
      ...destination.toPayload('destination'),
      'total_weight_kg': totalWeightKg?.toString(),
      'length_m': lengthM?.toString(),
      'width_m': widthM?.toString(),
      'height_m': heightM?.toString(),
      'stackable': stackable,
      'requires_tarp':
          requiresTarp || specialRequirements.contains(SpecialRequirement.tarp),
      'requires_special_loading':
          requiresSpecialLoading ||
          specialRequirements.contains(SpecialRequirement.specialLoading),
      'requires_refrigeration':
          requiresRefrigeration ||
          specialRequirements.contains(SpecialRequirement.refrigerated),
      'dangerous_goods':
          dangerousGoods ||
          specialRequirements.contains(SpecialRequirement.dangerousGoods),
      'special_requirements': reqs,
      'special_instructions': specialInstructions,
      'requested_vehicle_type_id': requestedVehicleTypeId,
      'recommended_vehicle_type_id': recommendedVehicleTypeId,
      'user_selected_unknown_truck': unknownTruck,
      'currency': 'BOB',
      'container': cargoType == CargoType.contenedor
          ? (container ?? const ContainerDraft()).toJson()
          : null,
    };
  }

  @override
  List<Object?> get props => [
    cargoType,
    origin,
    destination,
    totalWeightKg,
    requestedVehicleTypeId,
    scheduleMode,
  ];
}

class CargoRequestSummary extends Equatable {
  const CargoRequestSummary({
    required this.id,
    required this.status,
    required this.cargoType,
    required this.originCity,
    required this.destinationCity,
    required this.createdAt,
    this.totalWeightKg,
    this.vehicleTypeName,
  });

  final String id;
  final RequestStatus status;
  final CargoType cargoType;
  final String originCity;
  final String destinationCity;
  final DateTime createdAt;
  final double? totalWeightKg;
  final String? vehicleTypeName;

  factory CargoRequestSummary.fromJson(Map<String, dynamic> json) {
    String? typeName;
    final vt = json['vehicle_types'];
    if (vt is Map) {
      typeName = vt['name_es'] as String?;
    }
    final requested = json['requested_vehicle_type'];
    if (typeName == null && requested is Map) {
      typeName = requested['name_es'] as String?;
    }

    return CargoRequestSummary(
      id: json['id'] as String,
      status: RequestStatus.fromDb(json['status'] as String?),
      cargoType: CargoType.fromDb(json['cargo_type'] as String?),
      originCity: json['origin_city'] as String? ?? '',
      destinationCity: json['destination_city'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble(),
      vehicleTypeName: typeName,
    );
  }

  @override
  List<Object?> get props => [id, status, originCity, destinationCity];
}

/// Quick Bolivia city presets when Maps is not configured.
class BoliviaCity {
  const BoliviaCity(this.name, this.adminArea, this.lat, this.lng);
  final String name;
  final String adminArea;
  final double lat;
  final double lng;

  static const presets = <BoliviaCity>[
    BoliviaCity('Santa Cruz de la Sierra', 'Santa Cruz', -17.7833, -63.1821),
    BoliviaCity('Cochabamba', 'Cochabamba', -17.3895, -66.1568),
    BoliviaCity('La Paz', 'La Paz', -16.5000, -68.1500),
    BoliviaCity('El Alto', 'La Paz', -16.5050, -68.1640),
    BoliviaCity('Oruro', 'Oruro', -17.9833, -67.1500),
    BoliviaCity('Sucre', 'Chuquisaca', -19.0333, -65.2627),
    BoliviaCity('Tarija', 'Tarija', -21.5310, -64.7311),
    BoliviaCity('Potosí', 'Potosí', -19.5836, -65.7531),
    BoliviaCity('Trinidad', 'Beni', -14.8333, -64.9000),
  ];
}

// Keep VehicleType import used by recommendation consumers.
typedef RecommendedTruck = VehicleType;

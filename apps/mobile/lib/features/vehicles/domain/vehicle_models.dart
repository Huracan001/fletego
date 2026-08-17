import 'package:equatable/equatable.dart';

import '../../../shared/enums/company_enums.dart';
import '../../../shared/enums/vehicle_enums.dart';

class VehicleType extends Equatable {
  const VehicleType({
    required this.id,
    required this.code,
    required this.nameEs,
    required this.nameEn,
    this.typicalMaxWeightKg,
    this.supportsContainer = false,
    this.supportsRefrigeration = false,
  });

  final String id;
  final String code;
  final String nameEs;
  final String nameEn;
  final double? typicalMaxWeightKg;
  final bool supportsContainer;
  final bool supportsRefrigeration;

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as String,
      code: json['code'] as String,
      nameEs: json['name_es'] as String,
      nameEn: json['name_en'] as String? ?? json['name_es'] as String,
      typicalMaxWeightKg: (json['typical_max_weight_kg'] as num?)?.toDouble(),
      supportsContainer: json['supports_container'] as bool? ?? false,
      supportsRefrigeration: json['supports_refrigeration'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, code];
}

class DriverProfile extends Equatable {
  const DriverProfile({
    required this.id,
    required this.userId,
    this.licenseNumber,
    this.licenseExpiry,
    this.verificationStatus = VerificationStatus.pending,
    this.yearsExperience,
    this.acceptsReturnLoads = true,
    this.ratingAvg = 0,
    this.completedTrips = 0,
  });

  final String id;
  final String userId;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final VerificationStatus verificationStatus;
  final int? yearsExperience;
  final bool acceptsReturnLoads;
  final double ratingAvg;
  final int completedTrips;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      licenseNumber: json['license_number'] as String?,
      licenseExpiry: json['license_expiry'] == null
          ? null
          : DateTime.tryParse(json['license_expiry'] as String),
      verificationStatus: VerificationStatus.fromDb(
        json['verification_status'] as String?,
      ),
      yearsExperience: json['years_experience'] as int?,
      acceptsReturnLoads: json['accepts_return_loads'] as bool? ?? true,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      completedTrips: json['completed_trips'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, userId, licenseNumber, verificationStatus];
}

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.vehicleTypeId,
    required this.plate,
    required this.countryCode,
    required this.verificationStatus,
    required this.availabilityStatus,
    this.ownerProfileId,
    this.companyId,
    this.brand,
    this.model,
    this.year,
    this.capacityKg,
    this.maxCargoKg,
    this.lengthM,
    this.widthM,
    this.heightM,
    this.hasRefrigeration = false,
    this.hasTarp = false,
    this.acceptsDangerousGoods = false,
    this.vehicleType,
  });

  final String id;
  final String? ownerProfileId;
  final String? companyId;
  final String vehicleTypeId;
  final String plate;
  final String countryCode;
  final String? brand;
  final String? model;
  final int? year;
  final double? capacityKg;
  final double? maxCargoKg;
  final double? lengthM;
  final double? widthM;
  final double? heightM;
  final bool hasRefrigeration;
  final bool hasTarp;
  final bool acceptsDangerousGoods;
  final VerificationStatus verificationStatus;
  final AvailabilityStatus availabilityStatus;
  final VehicleType? vehicleType;

  String get title {
    final typeName = vehicleType?.nameEs;
    if (typeName != null) return '$typeName · $plate';
    return plate;
  }

  String get subtitle {
    final parts = <String>[
      if (brand != null && brand!.isNotEmpty) brand!,
      if (model != null && model!.isNotEmpty) model!,
      if (year != null) '$year',
    ];
    return parts.isEmpty ? 'Sin detalles' : parts.join(' ');
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    VehicleType? type;
    final rawType = json['vehicle_types'];
    if (rawType is Map) {
      type = VehicleType.fromJson(Map<String, dynamic>.from(rawType));
    }

    return Vehicle(
      id: json['id'] as String,
      ownerProfileId: json['owner_profile_id'] as String?,
      companyId: json['company_id'] as String?,
      vehicleTypeId: json['vehicle_type_id'] as String,
      plate: json['plate'] as String,
      countryCode: json['country_code'] as String? ?? 'BO',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      capacityKg: (json['capacity_kg'] as num?)?.toDouble(),
      maxCargoKg: (json['max_cargo_kg'] as num?)?.toDouble(),
      lengthM: (json['length_m'] as num?)?.toDouble(),
      widthM: (json['width_m'] as num?)?.toDouble(),
      heightM: (json['height_m'] as num?)?.toDouble(),
      hasRefrigeration: json['has_refrigeration'] as bool? ?? false,
      hasTarp: json['has_tarp'] as bool? ?? false,
      acceptsDangerousGoods: json['accepts_dangerous_goods'] as bool? ?? false,
      verificationStatus: VerificationStatus.fromDb(
        json['verification_status'] as String?,
      ),
      availabilityStatus: AvailabilityStatus.fromDb(
        json['availability_status'] as String?,
      ),
      vehicleType: type,
    );
  }

  @override
  List<Object?> get props => [id, plate, vehicleTypeId, availabilityStatus];
}

class DriverAvailability extends Equatable {
  const DriverAvailability({
    required this.id,
    required this.driverProfileId,
    required this.vehicleId,
    required this.status,
    this.availableFrom,
    this.availableUntil,
    this.acceptsReturnCargo = true,
    this.maxDeadheadKm,
    this.vehicle,
  });

  final String id;
  final String driverProfileId;
  final String vehicleId;
  final AvailabilityStatus status;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final bool acceptsReturnCargo;
  final double? maxDeadheadKm;
  final Vehicle? vehicle;

  factory DriverAvailability.fromJson(Map<String, dynamic> json) {
    Vehicle? vehicle;
    final raw = json['vehicles'];
    if (raw is Map) {
      vehicle = Vehicle.fromJson(Map<String, dynamic>.from(raw));
    }

    return DriverAvailability(
      id: json['id'] as String,
      driverProfileId: json['driver_profile_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      status: AvailabilityStatus.fromDb(json['status'] as String?),
      availableFrom: json['available_from'] == null
          ? null
          : DateTime.tryParse(json['available_from'] as String),
      availableUntil: json['available_until'] == null
          ? null
          : DateTime.tryParse(json['available_until'] as String),
      acceptsReturnCargo: json['accepts_return_cargo'] as bool? ?? true,
      maxDeadheadKm: (json['max_deadhead_km'] as num?)?.toDouble(),
      vehicle: vehicle,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, status];
}

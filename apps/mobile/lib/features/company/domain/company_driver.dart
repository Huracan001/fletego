import 'package:equatable/equatable.dart';

import '../../../shared/enums/company_enums.dart';

class CompanyDriver extends Equatable {
  const CompanyDriver({
    required this.driverProfileId,
    required this.userId,
    required this.fullName,
    this.email,
    this.licenseNumber,
    this.verificationStatus = VerificationStatus.pending,
    this.ratingAvg = 0,
    this.completedTrips = 0,
    this.vehicleId,
    this.vehiclePlate,
    this.isPrimary = false,
  });

  final String driverProfileId;
  final String userId;
  final String fullName;
  final String? email;
  final String? licenseNumber;
  final VerificationStatus verificationStatus;
  final double ratingAvg;
  final int completedTrips;
  final String? vehicleId;
  final String? vehiclePlate;
  final bool isPrimary;

  String get subtitle {
    final plate = vehiclePlate?.trim();
    if (plate != null && plate.isNotEmpty) {
      return isPrimary ? 'Principal · $plate' : plate;
    }
    return licenseNumber?.trim().isNotEmpty == true
        ? 'Licencia ${licenseNumber!.trim()}'
        : 'Sin vehículo asignado';
  }

  factory CompanyDriver.fromJson(Map<String, dynamic> json) {
    return CompanyDriver(
      driverProfileId: json['driver_profile_id'] as String,
      userId: json['user_id'] as String,
      fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true
          ? (json['full_name'] as String).trim()
          : 'Conductor',
      email: json['email'] as String?,
      licenseNumber: json['license_number'] as String?,
      verificationStatus: VerificationStatus.fromDb(
        json['verification_status'] as String?,
      ),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      completedTrips: (json['completed_trips'] as num?)?.toInt() ?? 0,
      vehicleId: json['vehicle_id'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [driverProfileId, vehicleId];
}

import 'package:equatable/equatable.dart';

import '../../../shared/enums/cargo_enums.dart';
import '../../../shared/enums/trip_status.dart';

class TripSummary extends Equatable {
  const TripSummary({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.customerId,
    required this.driverId,
    required this.vehicleId,
    required this.status,
    required this.assignedAt,
    required this.createdAt,
    this.companyId,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.originCity,
    this.destinationCity,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.currentLat,
    this.currentLng,
    this.cargoType,
  });

  final String id;
  final String requestId;
  final String offerId;
  final String customerId;
  final String driverId;
  final String vehicleId;
  final String? companyId;
  final TripStatus status;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime createdAt;
  final String? originCity;
  final String? destinationCity;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final double? currentLat;
  final double? currentLng;
  final CargoType? cargoType;

  String get routeLabel {
    final o = originCity?.trim();
    final d = destinationCity?.trim();
    if (o != null && o.isNotEmpty && d != null && d.isNotEmpty) {
      return '$o → $d';
    }
    return 'Viaje';
  }

  bool get isDriverRoleFor => false; // resolved in UI via auth uid

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    CargoType? cargo;
    String? origin;
    String? dest;
    double? oLat;
    double? oLng;
    double? dLat;
    double? dLng;
    final request = json['cargo_requests'];
    if (request is Map) {
      origin = request['origin_city'] as String?;
      dest = request['destination_city'] as String?;
      cargo = CargoType.fromDb(request['cargo_type'] as String?);
      oLat = (request['origin_lat'] as num?)?.toDouble();
      oLng = (request['origin_lng'] as num?)?.toDouble();
      dLat = (request['destination_lat'] as num?)?.toDouble();
      dLng = (request['destination_lng'] as num?)?.toDouble();
    }

    return TripSummary(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      offerId: json['offer_id'] as String,
      customerId: json['customer_id'] as String,
      driverId: json['driver_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      companyId: json['company_id'] as String?,
      status: TripStatus.fromDb(json['status'] as String?),
      assignedAt:
          DateTime.tryParse(json['assigned_at'] as String? ?? '') ??
          DateTime.now(),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.tryParse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.tryParse(json['completed_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.tryParse(json['cancelled_at'] as String),
      cancelReason: json['cancel_reason'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      originCity: origin,
      destinationCity: dest,
      originLat: oLat,
      originLng: oLng,
      destinationLat: dLat,
      destinationLng: dLng,
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
      cargoType: cargo,
    );
  }

  TripSummary copyWith({
    TripStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelReason,
    double? currentLat,
    double? currentLng,
  }) {
    return TripSummary(
      id: id,
      requestId: requestId,
      offerId: offerId,
      customerId: customerId,
      driverId: driverId,
      vehicleId: vehicleId,
      companyId: companyId,
      status: status ?? this.status,
      assignedAt: assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt,
      originCity: originCity,
      destinationCity: destinationCity,
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      cargoType: cargoType,
    );
  }

  @override
  List<Object?> get props => [id, status, requestId];
}

class TripHistoryEntry extends Equatable {
  const TripHistoryEntry({
    required this.id,
    required this.tripId,
    required this.toStatus,
    required this.createdAt,
    this.fromStatus,
    this.changedBy,
    this.note,
  });

  final String id;
  final String tripId;
  final TripStatus? fromStatus;
  final TripStatus toStatus;
  final String? changedBy;
  final String? note;
  final DateTime createdAt;

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TripHistoryEntry(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      fromStatus: json['from_status'] == null
          ? null
          : TripStatus.fromDb(json['from_status'] as String?),
      toStatus: TripStatus.fromDb(json['to_status'] as String?),
      changedBy: json['changed_by'] as String?,
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, toStatus, createdAt];
}

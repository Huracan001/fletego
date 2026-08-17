import 'package:equatable/equatable.dart';

class LocationUpdate extends Equatable {
  const LocationUpdate({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.speedMps,
    this.headingDeg,
    this.accuracyM,
  });

  final String id;
  final String tripId;
  final String driverId;
  final double lat;
  final double lng;
  final double? speedMps;
  final double? headingDeg;
  final double? accuracyM;
  final DateTime recordedAt;

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    return LocationUpdate(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      driverId: json['driver_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speedMps: (json['speed_mps'] as num?)?.toDouble(),
      headingDeg: (json['heading_deg'] as num?)?.toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      recordedAt:
          DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, tripId, lat, lng, recordedAt];
}

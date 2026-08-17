import 'package:equatable/equatable.dart';

class PickupEvidence extends Equatable {
  const PickupEvidence({
    required this.id,
    required this.tripId,
    required this.createdBy,
    required this.capturedAt,
    this.notes,
    this.photoPaths = const [],
    this.lat,
    this.lng,
  });

  final String id;
  final String tripId;
  final String? notes;
  final List<String> photoPaths;
  final double? lat;
  final double? lng;
  final DateTime capturedAt;
  final String createdBy;

  factory PickupEvidence.fromJson(Map<String, dynamic> json) {
    final photos = json['photo_paths'];
    return PickupEvidence(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      notes: json['notes'] as String?,
      photoPaths: photos is List
          ? photos.map((e) => e.toString()).toList()
          : const [],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      capturedAt:
          DateTime.tryParse(json['captured_at'] as String? ?? '') ??
          DateTime.now(),
      createdBy: json['created_by'] as String,
    );
  }

  @override
  List<Object?> get props => [id, tripId, capturedAt];
}

class ProofOfDelivery extends Equatable {
  const ProofOfDelivery({
    required this.id,
    required this.tripId,
    required this.recipientName,
    required this.createdBy,
    required this.capturedAt,
    this.recipientIdRef,
    this.signaturePath,
    this.photoPaths = const [],
    this.notes,
    this.lat,
    this.lng,
  });

  final String id;
  final String tripId;
  final String recipientName;
  final String? recipientIdRef;
  final String? signaturePath;
  final List<String> photoPaths;
  final String? notes;
  final double? lat;
  final double? lng;
  final DateTime capturedAt;
  final String createdBy;

  bool get hasSignature =>
      signaturePath != null && signaturePath!.trim().isNotEmpty;

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    final photos = json['photo_paths'];
    return ProofOfDelivery(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      recipientName: json['recipient_name'] as String? ?? '',
      recipientIdRef: json['recipient_id_ref'] as String?,
      signaturePath: json['signature_path'] as String?,
      photoPaths: photos is List
          ? photos.map((e) => e.toString()).toList()
          : const [],
      notes: json['notes'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      capturedAt:
          DateTime.tryParse(json['captured_at'] as String? ?? '') ??
          DateTime.now(),
      createdBy: json['created_by'] as String,
    );
  }

  @override
  List<Object?> get props => [id, tripId, recipientName, capturedAt];
}

import 'package:equatable/equatable.dart';

enum RatingPerspective { customerRatesDriver, driverRatesCustomer }

class RatingDimensions {
  const RatingDimensions._(this.values);

  final Map<String, int> values;

  int? operator [](String key) => values[key];

  Map<String, dynamic> toJson() => {
    for (final e in values.entries) e.key: e.value,
  };

  factory RatingDimensions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RatingDimensions._({});
    final map = <String, int>{};
    for (final e in json.entries) {
      final v = e.value;
      if (v is int) {
        map[e.key] = v;
      } else if (v is num) {
        map[e.key] = v.round();
      }
    }
    return RatingDimensions._(map);
  }

  static List<RatingDimensionDef> defsFor(RatingPerspective perspective) {
    return switch (perspective) {
      RatingPerspective.customerRatesDriver => const [
        RatingDimensionDef('punctuality', 'Puntualidad'),
        RatingDimensionDef('vehicle_condition', 'Estado del vehículo'),
        RatingDimensionDef('driver', 'Conductor'),
        RatingDimensionDef('communication', 'Comunicación'),
      ],
      RatingPerspective.driverRatesCustomer => const [
        RatingDimensionDef('cargo_readiness', 'Carga lista'),
        RatingDimensionDef('info_accuracy', 'Info precisa'),
        RatingDimensionDef('loading_wait', 'Espera de carga'),
        RatingDimensionDef('customer_behavior', 'Trato del cliente'),
      ],
    };
  }
}

class RatingDimensionDef {
  const RatingDimensionDef(this.key, this.labelEs);
  final String key;
  final String labelEs;
}

class TripRating extends Equatable {
  const TripRating({
    required this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.overall,
    required this.createdAt,
    this.dimensions = const RatingDimensions._({}),
    this.comment,
  });

  final String id;
  final String tripId;
  final String fromUserId;
  final String toUserId;
  final int overall;
  final RatingDimensions dimensions;
  final String? comment;
  final DateTime createdAt;

  factory TripRating.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions'];
    return TripRating(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      overall: (json['overall'] as num).round(),
      dimensions: RatingDimensions.fromJson(
        dims is Map ? Map<String, dynamic>.from(dims) : null,
      ),
      comment: json['comment'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, tripId, fromUserId, overall];
}

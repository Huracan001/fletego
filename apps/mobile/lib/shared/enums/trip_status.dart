/// Trip lifecycle — mirror Postgres enum. Invalid transitions rejected by TripStateService.
enum TripStatus {
  requested,
  matching,
  offerReceived,
  assigned,
  driverGoingToPickup,
  arrivedAtPickup,
  cargoPickedUp,
  inTransit,
  arrivedAtDestination,
  delivering,
  delivered,
  completed,
  cancelled,
  disputed,
  failed;

  String get dbValue => switch (this) {
    TripStatus.requested => 'requested',
    TripStatus.matching => 'matching',
    TripStatus.offerReceived => 'offer_received',
    TripStatus.assigned => 'assigned',
    TripStatus.driverGoingToPickup => 'driver_going_to_pickup',
    TripStatus.arrivedAtPickup => 'arrived_at_pickup',
    TripStatus.cargoPickedUp => 'cargo_picked_up',
    TripStatus.inTransit => 'in_transit',
    TripStatus.arrivedAtDestination => 'arrived_at_destination',
    TripStatus.delivering => 'delivering',
    TripStatus.delivered => 'delivered',
    TripStatus.completed => 'completed',
    TripStatus.cancelled => 'cancelled',
    TripStatus.disputed => 'disputed',
    TripStatus.failed => 'failed',
  };

  String get labelEs => switch (this) {
    TripStatus.requested => 'Solicitado',
    TripStatus.matching => 'Buscando',
    TripStatus.offerReceived => 'Con oferta',
    TripStatus.assigned => 'Asignado',
    TripStatus.driverGoingToPickup => 'En camino al origen',
    TripStatus.arrivedAtPickup => 'En el origen',
    TripStatus.cargoPickedUp => 'Carga recogida',
    TripStatus.inTransit => 'En tránsito',
    TripStatus.arrivedAtDestination => 'En destino',
    TripStatus.delivering => 'Entregando',
    TripStatus.delivered => 'Entregado',
    TripStatus.completed => 'Completado',
    TripStatus.cancelled => 'Cancelado',
    TripStatus.disputed => 'En disputa',
    TripStatus.failed => 'Fallido',
  };

  bool get isTerminal =>
      this == TripStatus.completed ||
      this == TripStatus.cancelled ||
      this == TripStatus.failed;

  bool get isActive => !isTerminal && this != TripStatus.disputed;

  static TripStatus fromDb(String? value) {
    for (final s in TripStatus.values) {
      if (s.dbValue == value) return s;
    }
    return TripStatus.assigned;
  }
}

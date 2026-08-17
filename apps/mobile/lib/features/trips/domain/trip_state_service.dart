import '../../../shared/enums/trip_status.dart';

/// Validates trip status transitions. UI must not invent transitions.
class TripStateService {
  const TripStateService();

  static const Map<TripStatus, Set<TripStatus>> _allowed = {
    TripStatus.requested: {TripStatus.matching, TripStatus.cancelled},
    TripStatus.matching: {
      TripStatus.offerReceived,
      TripStatus.assigned,
      TripStatus.cancelled,
    },
    TripStatus.offerReceived: {
      TripStatus.assigned,
      TripStatus.matching,
      TripStatus.cancelled,
    },
    TripStatus.assigned: {
      TripStatus.driverGoingToPickup,
      TripStatus.cancelled,
      TripStatus.disputed,
    },
    TripStatus.driverGoingToPickup: {
      TripStatus.arrivedAtPickup,
      TripStatus.cancelled,
      TripStatus.failed,
    },
    TripStatus.arrivedAtPickup: {
      TripStatus.cargoPickedUp,
      TripStatus.cancelled,
      TripStatus.failed,
    },
    TripStatus.cargoPickedUp: {
      TripStatus.inTransit,
      TripStatus.cancelled,
      TripStatus.failed,
      TripStatus.disputed,
    },
    TripStatus.inTransit: {
      TripStatus.arrivedAtDestination,
      TripStatus.failed,
      TripStatus.disputed,
    },
    TripStatus.arrivedAtDestination: {
      TripStatus.delivering,
      TripStatus.failed,
      TripStatus.disputed,
    },
    TripStatus.delivering: {
      TripStatus.delivered,
      TripStatus.failed,
      TripStatus.disputed,
    },
    TripStatus.delivered: {TripStatus.completed, TripStatus.disputed},
    TripStatus.completed: {},
    TripStatus.cancelled: {},
    TripStatus.disputed: {TripStatus.completed, TripStatus.cancelled},
    TripStatus.failed: {},
  };

  /// Happy-path sequence the driver advances through.
  static const List<TripStatus> driverHappyPath = [
    TripStatus.assigned,
    TripStatus.driverGoingToPickup,
    TripStatus.arrivedAtPickup,
    TripStatus.cargoPickedUp,
    TripStatus.inTransit,
    TripStatus.arrivedAtDestination,
    TripStatus.delivering,
    TripStatus.delivered,
  ];

  bool canTransition(TripStatus from, TripStatus to) {
    return _allowed[from]?.contains(to) ?? false;
  }

  void assertCanTransition(TripStatus from, TripStatus to) {
    if (!canTransition(from, to)) {
      throw StateError('Transición inválida: ${from.dbValue} → ${to.dbValue}');
    }
  }

  Set<TripStatus> allowedFrom(TripStatus from) =>
      _allowed[from] ?? const <TripStatus>{};

  bool canCancel(TripStatus status) =>
      canTransition(status, TripStatus.cancelled);

  /// Next operational step for the driver, if any.
  TripStatus? nextDriverStep(TripStatus current) {
    for (var i = 0; i < driverHappyPath.length - 1; i++) {
      if (driverHappyPath[i] == current) {
        final next = driverHappyPath[i + 1];
        if (canTransition(current, next)) return next;
      }
    }
    return null;
  }

  String actionLabelEs(TripStatus next) => switch (next) {
    TripStatus.driverGoingToPickup => 'Voy al origen',
    TripStatus.arrivedAtPickup => 'Llegué al origen',
    TripStatus.cargoPickedUp => 'Carga recogida',
    TripStatus.inTransit => 'Iniciar tránsito',
    TripStatus.arrivedAtDestination => 'Llegué al destino',
    TripStatus.delivering => 'Empezar entrega',
    TripStatus.delivered => 'Marcar entregado',
    TripStatus.completed => 'Completar viaje',
    TripStatus.cancelled => 'Cancelar',
    _ => 'Avanzar a ${next.labelEs}',
  };
}

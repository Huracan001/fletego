import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/trips/domain/trip_state_service.dart';
import 'package:fletego/shared/enums/trip_status.dart';

void main() {
  const service = TripStateService();

  test('allows assigned → driver_going_to_pickup', () {
    expect(
      service.canTransition(
        TripStatus.assigned,
        TripStatus.driverGoingToPickup,
      ),
      isTrue,
    );
  });

  test('rejects completed → in_transit', () {
    expect(
      service.canTransition(TripStatus.completed, TripStatus.inTransit),
      isFalse,
    );
  });

  test('assertCanTransition throws on invalid path', () {
    expect(
      () => service.assertCanTransition(
        TripStatus.delivered,
        TripStatus.inTransit,
      ),
      throwsStateError,
    );
  });

  test('nextDriverStep follows happy path', () {
    expect(
      service.nextDriverStep(TripStatus.assigned),
      TripStatus.driverGoingToPickup,
    );
    expect(
      service.nextDriverStep(TripStatus.delivering),
      TripStatus.delivered,
    );
    expect(service.nextDriverStep(TripStatus.delivered), isNull);
  });

  test('canCancel only when allowed', () {
    expect(service.canCancel(TripStatus.assigned), isTrue);
    expect(service.canCancel(TripStatus.inTransit), isFalse);
    expect(service.canCancel(TripStatus.completed), isFalse);
  });
}

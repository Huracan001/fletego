import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/ratings/domain/rating_models.dart';

void main() {
  test('customer dimension defs', () {
    final defs = RatingDimensions.defsFor(
      RatingPerspective.customerRatesDriver,
    );
    expect(defs.map((d) => d.key), contains('punctuality'));
    expect(defs.map((d) => d.key), contains('communication'));
  });

  test('driver dimension defs', () {
    final defs = RatingDimensions.defsFor(
      RatingPerspective.driverRatesCustomer,
    );
    expect(defs.map((d) => d.key), contains('cargo_readiness'));
  });

  test('TripRating fromJson', () {
    final r = TripRating.fromJson({
      'id': 'r1',
      'trip_id': 't1',
      'from_user_id': 'u1',
      'to_user_id': 'u2',
      'overall': 4,
      'dimensions': {'punctuality': 5, 'driver': 4},
      'comment': 'Bien',
      'created_at': '2026-08-17T12:00:00Z',
    });
    expect(r.overall, 4);
    expect(r.dimensions['punctuality'], 5);
    expect(r.comment, 'Bien');
  });
}

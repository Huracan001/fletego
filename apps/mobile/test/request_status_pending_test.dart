import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/shared/enums/cargo_enums.dart';

void main() {
  test('isPendingOpen covers pipeline before assignment', () {
    expect(RequestStatus.submitted.isPendingOpen, isTrue);
    expect(RequestStatus.matching.isPendingOpen, isTrue);
    expect(RequestStatus.offered.isPendingOpen, isTrue);
    expect(RequestStatus.assigned.isPendingOpen, isFalse);
    expect(RequestStatus.cancelled.isPendingOpen, isFalse);
    expect(RequestStatus.draft.isPendingOpen, isFalse);
  });
}

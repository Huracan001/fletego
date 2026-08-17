import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/pod/domain/pod_models.dart';

void main() {
  test('ProofOfDelivery parses recipient and signature', () {
    final pod = ProofOfDelivery.fromJson({
      'id': 'p1',
      'trip_id': 't1',
      'recipient_name': 'Juan Pérez',
      'recipient_id_ref': '1234567',
      'signature_path': 'pod-documents/t1/sig.png',
      'photo_paths': ['a.jpg', 'b.jpg'],
      'lat': -17.39,
      'lng': -66.15,
      'captured_at': '2026-08-17T12:00:00Z',
      'created_by': 'u1',
    });
    expect(pod.recipientName, 'Juan Pérez');
    expect(pod.hasSignature, isTrue);
    expect(pod.photoPaths, hasLength(2));
  });

  test('PickupEvidence parses photos', () {
    final pickup = PickupEvidence.fromJson({
      'id': 'e1',
      'trip_id': 't1',
      'notes': 'OK',
      'photo_paths': ['pickup.jpg'],
      'captured_at': '2026-08-17T10:00:00Z',
      'created_by': 'u1',
    });
    expect(pickup.notes, 'OK');
    expect(pickup.photoPaths.single, 'pickup.jpg');
  });
}

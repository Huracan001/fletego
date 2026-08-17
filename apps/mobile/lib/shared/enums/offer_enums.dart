enum OfferStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
  expired;

  String get dbValue => name;

  String get labelEs => switch (this) {
    OfferStatus.pending => 'Pendiente',
    OfferStatus.accepted => 'Aceptada',
    OfferStatus.rejected => 'Rechazada',
    OfferStatus.withdrawn => 'Retirada',
    OfferStatus.expired => 'Expirada',
  };

  static OfferStatus fromDb(String? value) {
    for (final s in OfferStatus.values) {
      if (s.dbValue == value) return s;
    }
    return OfferStatus.pending;
  }
}

import 'company_enums.dart';

enum AvailabilityStatus {
  offline,
  available,
  busy,
  onTrip;

  String get dbValue => switch (this) {
    AvailabilityStatus.offline => 'offline',
    AvailabilityStatus.available => 'available',
    AvailabilityStatus.busy => 'busy',
    AvailabilityStatus.onTrip => 'on_trip',
  };

  String get labelEs => switch (this) {
    AvailabilityStatus.offline => 'No disponible',
    AvailabilityStatus.available => 'Disponible',
    AvailabilityStatus.busy => 'Ocupado',
    AvailabilityStatus.onTrip => 'En viaje',
  };

  static AvailabilityStatus fromDb(String? value) {
    for (final s in AvailabilityStatus.values) {
      if (s.dbValue == value) return s;
    }
    return AvailabilityStatus.offline;
  }
}

enum DocumentKind {
  identity,
  license,
  vehicleRegistration,
  insurance,
  other;

  String get dbValue => switch (this) {
    DocumentKind.identity => 'identity',
    DocumentKind.license => 'license',
    DocumentKind.vehicleRegistration => 'vehicle_registration',
    DocumentKind.insurance => 'insurance',
    DocumentKind.other => 'other',
  };

  String get labelEs => switch (this) {
    DocumentKind.identity => 'Identidad',
    DocumentKind.license => 'Licencia',
    DocumentKind.vehicleRegistration => 'Registro vehicular',
    DocumentKind.insurance => 'Seguro',
    DocumentKind.other => 'Otro',
  };

  static DocumentKind fromDb(String? value) {
    for (final k in DocumentKind.values) {
      if (k.dbValue == value) return k;
    }
    return DocumentKind.other;
  }
}

// Re-export verification for convenience in vehicle feature imports.
typedef VehicleVerificationStatus = VerificationStatus;

enum CargoType {
  contenedor,
  cargaGeneral,
  liquidos,
  vehiculos,
  maquinaria,
  refrigerada,
  cargaPeligrosa,
  otra;

  String get dbValue => switch (this) {
    CargoType.contenedor => 'contenedor',
    CargoType.cargaGeneral => 'carga_general',
    CargoType.liquidos => 'liquidos',
    CargoType.vehiculos => 'vehiculos',
    CargoType.maquinaria => 'maquinaria',
    CargoType.refrigerada => 'refrigerada',
    CargoType.cargaPeligrosa => 'carga_peligrosa',
    CargoType.otra => 'otra',
  };

  String get labelEs => switch (this) {
    CargoType.contenedor => 'Contenedor',
    CargoType.cargaGeneral => 'Carga general',
    CargoType.liquidos => 'Líquidos',
    CargoType.vehiculos => 'Vehículos',
    CargoType.maquinaria => 'Maquinaria',
    CargoType.refrigerada => 'Refrigerada',
    CargoType.cargaPeligrosa => 'Carga peligrosa',
    CargoType.otra => 'Otra',
  };

  static CargoType fromDb(String? value) {
    for (final t in CargoType.values) {
      if (t.dbValue == value) return t;
    }
    return CargoType.cargaGeneral;
  }
}

enum RequestStatus {
  draft,
  submitted,
  matching,
  offered,
  assigned,
  cancelled,
  expired;

  String get dbValue => name == 'draft'
      ? 'draft'
      : switch (this) {
          RequestStatus.draft => 'draft',
          RequestStatus.submitted => 'submitted',
          RequestStatus.matching => 'matching',
          RequestStatus.offered => 'offered',
          RequestStatus.assigned => 'assigned',
          RequestStatus.cancelled => 'cancelled',
          RequestStatus.expired => 'expired',
        };

  String get labelEs => switch (this) {
    RequestStatus.draft => 'Borrador',
    RequestStatus.submitted => 'Enviada',
    RequestStatus.matching => 'Buscando camiones',
    RequestStatus.offered => 'Con ofertas',
    RequestStatus.assigned => 'Asignada',
    RequestStatus.cancelled => 'Cancelada',
    RequestStatus.expired => 'Expirada',
  };

  /// Open pipeline before a trip is assigned.
  bool get isPendingOpen =>
      this == RequestStatus.submitted ||
      this == RequestStatus.matching ||
      this == RequestStatus.offered;

  static RequestStatus fromDb(String? value) {
    for (final s in RequestStatus.values) {
      if (s.dbValue == value) return s;
    }
    return RequestStatus.draft;
  }
}

enum ScheduleMode {
  asap,
  scheduled;

  String get dbValue => name;

  String get labelEs => switch (this) {
    ScheduleMode.asap => 'Lo antes posible',
    ScheduleMode.scheduled => 'Programado',
  };

  static ScheduleMode fromDb(String? value) {
    return value == 'scheduled' ? ScheduleMode.scheduled : ScheduleMode.asap;
  }
}

enum ContainerSize {
  ft20,
  ft40,
  ft40Hc,
  ft45;

  String get dbValue => switch (this) {
    ContainerSize.ft20 => 'ft20',
    ContainerSize.ft40 => 'ft40',
    ContainerSize.ft40Hc => 'ft40_hc',
    ContainerSize.ft45 => 'ft45',
  };

  String get labelEs => switch (this) {
    ContainerSize.ft20 => '20 ft',
    ContainerSize.ft40 => '40 ft',
    ContainerSize.ft40Hc => '40 HC',
    ContainerSize.ft45 => '45 ft',
  };

  static ContainerSize fromDb(String? value) {
    for (final c in ContainerSize.values) {
      if (c.dbValue == value) return c;
    }
    return ContainerSize.ft40;
  }
}

enum SpecialRequirement {
  refrigerated,
  tarp,
  specialLoading,
  dangerousGoods,
  escort,
  specialPermits,
  oversized,
  fragile,
  other;

  String get dbValue => switch (this) {
    SpecialRequirement.refrigerated => 'refrigerated',
    SpecialRequirement.tarp => 'tarp',
    SpecialRequirement.specialLoading => 'special_loading',
    SpecialRequirement.dangerousGoods => 'dangerous_goods',
    SpecialRequirement.escort => 'escort',
    SpecialRequirement.specialPermits => 'special_permits',
    SpecialRequirement.oversized => 'oversized',
    SpecialRequirement.fragile => 'fragile',
    SpecialRequirement.other => 'other',
  };

  String get labelEs => switch (this) {
    SpecialRequirement.refrigerated => 'Refrigerado',
    SpecialRequirement.tarp => 'Carpa / lona',
    SpecialRequirement.specialLoading => 'Carga especial',
    SpecialRequirement.dangerousGoods => 'Carga peligrosa',
    SpecialRequirement.escort => 'Escolta',
    SpecialRequirement.specialPermits => 'Permisos especiales',
    SpecialRequirement.oversized => 'Sobredimensionada',
    SpecialRequirement.fragile => 'Frágil',
    SpecialRequirement.other => 'Otro',
  };

  static SpecialRequirement? fromDb(String value) {
    for (final r in SpecialRequirement.values) {
      if (r.dbValue == value) return r;
    }
    return null;
  }
}

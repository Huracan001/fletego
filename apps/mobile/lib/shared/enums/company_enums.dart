/// Company membership roles — mirror Postgres `company_role`.
enum CompanyRole {
  companyAdmin,
  companyOperator,
  companyFinance,
  companyViewer,
  dispatcher;

  String get dbValue => switch (this) {
    CompanyRole.companyAdmin => 'company_admin',
    CompanyRole.companyOperator => 'company_operator',
    CompanyRole.companyFinance => 'company_finance',
    CompanyRole.companyViewer => 'company_viewer',
    CompanyRole.dispatcher => 'dispatcher',
  };

  String get labelEs => switch (this) {
    CompanyRole.companyAdmin => 'Administrador',
    CompanyRole.companyOperator => 'Operador',
    CompanyRole.companyFinance => 'Finanzas',
    CompanyRole.companyViewer => 'Solo lectura',
    CompanyRole.dispatcher => 'Despachante',
  };

  static CompanyRole fromDb(String value) {
    for (final role in CompanyRole.values) {
      if (role.dbValue == value) return role;
    }
    return CompanyRole.companyViewer;
  }
}

enum CompanyType {
  customer,
  transporter,
  both,
  broker;

  String get dbValue => switch (this) {
    CompanyType.customer => 'customer',
    CompanyType.transporter => 'transporter',
    CompanyType.both => 'both',
    CompanyType.broker => 'broker',
  };

  String get labelEs => switch (this) {
    CompanyType.customer => 'Cliente / carga',
    CompanyType.transporter => 'Transportista',
    CompanyType.both => 'Cliente y transportista',
    CompanyType.broker => 'Broker / operador logístico',
  };

  static CompanyType fromDb(String value) {
    for (final type in CompanyType.values) {
      if (type.dbValue == value) return type;
    }
    return CompanyType.both;
  }
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
  expired;

  String get dbValue => name;

  String get labelEs => switch (this) {
    VerificationStatus.pending => 'Pendiente',
    VerificationStatus.approved => 'Verificada',
    VerificationStatus.rejected => 'Rechazada',
    VerificationStatus.expired => 'Vencida',
  };

  static VerificationStatus fromDb(String? value) {
    for (final status in VerificationStatus.values) {
      if (status.dbValue == value) return status;
    }
    return VerificationStatus.pending;
  }
}

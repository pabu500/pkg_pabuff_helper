enum TenantType {
  cw_nus_internal,
  cw_nus_external,
  cw_nus_retail_dining,
}

enum TenantKey {
  tenant_label,
  sap_wbs,
  location_tag,
  tenant_type,
}

String getTenantTypeTag(TenantType? tenantType) {
  if (tenantType == null) {
    return '';
  }
  switch (tenantType) {
    case TenantType.cw_nus_internal:
      return 'Internal';
    case TenantType.cw_nus_external:
      return 'External';
    case TenantType.cw_nus_retail_dining:
      return 'Retail&Dining';
    default:
      return '';
  }
}

TenantType? getTenantType(String tenantType) {
  switch (tenantType) {
    case 'cw_nus_internal':
      return TenantType.cw_nus_internal;
    case 'cw_nus_external':
      return TenantType.cw_nus_external;
    case 'cw_nus_retail_dining':
      return TenantType.cw_nus_retail_dining;
    default:
      return null;
  }
}

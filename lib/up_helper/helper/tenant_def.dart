enum TenantType {
  cw_nus_internal,
  cw_nus_external,
  cw_nus_retail_dining,
  cw_nus_virtual,
}

enum TenantKey {
  tenant_label,
  sap_wbs,
  location_tag,
  tenant_type,
  alt_name,
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
    case TenantType.cw_nus_virtual:
      return 'Virtual';
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
    case 'cw_nus_virtual':
      return TenantType.cw_nus_virtual;
    default:
      return null;
  }
}

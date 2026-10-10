/// Only allocations through an active tenant consume a meter's capacity.
/// Groups without a tenant and terminated/MFD tenants do not consume it.
bool meterAllocationHasActiveTenant(dynamic tenantInfo) {
  if (tenantInfo is! Map || tenantInfo.isEmpty) return false;
  final status = tenantInfo['lc_status']?.toString().trim().toLowerCase();
  return status != 'terminated' && status != 'mfd';
}

double? meterAllocationPercentage(dynamic value) {
  final percentage = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  return percentage != null && percentage.isFinite ? percentage : null;
}

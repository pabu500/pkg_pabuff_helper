/// Only allocations through an active tenant consume a meter's capacity.
/// Offboarding EMS assignments stop consuming capacity after handover or final
/// bill release. Closing readings alone do not release capacity.
bool meterAllocationHasActiveTenant(dynamic tenantInfo) {
  if (tenantInfo is! Map || tenantInfo.isEmpty) return false;
  final status = tenantInfo['lc_status']?.toString().trim().toLowerCase();
  if (status == 'terminated' || status == 'mfd') return false;
  bool isTrue(dynamic value) =>
      value?.toString().toLowerCase() == 'true' || value == 't';
  return status != 'offb' ||
      !(isTrue(tenantInfo['final_released']) || isTrue(tenantInfo['named']));
}

/// Keep meter-specific handover flags when previewing the same tenant.
Map<String, dynamic>? meterAllocationTenantInfo(
  dynamic assignedTenant,
  Map<String, dynamic>? currentTenant,
) {
  if (currentTenant == null) {
    return assignedTenant == null
        ? null
        : Map<String, dynamic>.from(assignedTenant);
  }
  final sameTenant =
      assignedTenant is Map &&
      assignedTenant['id'] != null &&
      assignedTenant['id'].toString() == currentTenant['id']?.toString();
  return {if (sameTenant) ...assignedTenant, ...currentTenant};
}

double? meterAllocationPercentage(dynamic value) {
  final percentage = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  return percentage != null && percentage.isFinite ? percentage : null;
}

double? getMultiplierFactoredTenantUsage(
  Map<String, dynamic> tenantUsageSummary,
  String meterType,
) {
  double? total;
  final meterGroupUsageList = tenantUsageSummary['meter_group_usage_list'];
  if (meterGroupUsageList is! List) return null;

  for (final meterGroupUsage in meterGroupUsageList) {
    if (meterGroupUsage is! Map ||
        meterGroupUsage['meter_type']?.toString().toUpperCase() !=
            meterType.toUpperCase()) {
      continue;
    }

    final meterUsageList =
        meterGroupUsage['meter_group_usage_summary']?['meter_usage_list'];
    if (meterUsageList is! List) continue;

    for (final meter in meterUsageList) {
      if (meter is! Map) continue;

      final meterUsageSummary = meter['meter_usage_summary'];
      if (meterUsageSummary is! Map) continue;

      final usage = _toDouble(meterUsageSummary['usage']);
      if (usage == null) continue;

      final percentage = _toDouble(meterUsageSummary['percentage']) ?? 100;
      final multiplier = _toDouble(
            meter['multiplier_factor'] ??
                meterUsageSummary['multiplier_factor'],
          ) ??
          1;
      total = (total ?? 0) + usage * percentage / 100 * multiplier;
    }
  }

  return total;
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

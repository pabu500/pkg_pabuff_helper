import 'package:flutter/material.dart';

void populateListItemMeterUsage(Map<String, dynamic> item) {
  if (item['meter_usage_summary'] == null) return;

  var meterUsageSummary = item['meter_usage_summary'];
  final multiplierFactor =
      item['multiplier_factor'] ?? meterUsageSummary['multiplier_factor'];
  item['usage_first_reading_timestamp'] =
      meterUsageSummary['first_reading_timestamp'];
  item['usage_last_reading_timestamp'] =
      meterUsageSummary['last_reading_timestamp'];
  item['usage_first_reading_value'] = meterUsageSummary['first_reading_value'];
  item['usage_last_reading_value'] = meterUsageSummary['last_reading_value'];
  item['usage'] = _applyMeterMultiplier(
    meterUsageSummary['usage'],
    multiplierFactor,
  );
  item['usage_first_reading_value_import'] =
      meterUsageSummary['first_reading_value_import'];
  item['usage_last_reading_value_import'] =
      meterUsageSummary['last_reading_value_import'];
  item['usage_import'] = _applyMeterMultiplier(
    meterUsageSummary['usage_import'],
    multiplierFactor,
  );
  item['usage_first_reading_value_export'] =
      meterUsageSummary['first_reading_value_export'];
  item['usage_last_reading_value_export'] =
      meterUsageSummary['last_reading_value_export'];
  item['usage_export'] = _applyMeterMultiplier(
    meterUsageSummary['usage_export'],
    multiplierFactor,
  );
  item['usage_color'] = Colors.green;
  item['usage_import_color'] = Colors.orange.shade600;
  item['usage_export_color'] = Colors.green;
}

dynamic _applyMeterMultiplier(dynamic usage, dynamic multiplierFactor) {
  if (usage == null) return null;

  final usageValue =
      usage is num ? usage.toDouble() : double.tryParse(usage.toString());
  final multiplierValue = multiplierFactor is num
      ? multiplierFactor.toDouble()
      : double.tryParse(multiplierFactor?.toString() ?? '') ?? 1;

  if (usageValue == null) return usage;

  final factoredUsage = usageValue * multiplierValue;
  return usage is String ? factoredUsage.toString() : factoredUsage;
}

void populateListItemTenantUsage(Map<String, dynamic> item, var meterTypeList) {
  if (item['tenant_usage_summary'] == null) return;

  var tenantUsageSummary = item['tenant_usage_summary'];
  var meterGroupUsageList = tenantUsageSummary['meter_group_usage_list'];
  // var meterTypeList = tenantUsageSummary['meter_type_list'];

  List<Map<String, dynamic>> meterTypeUsageList = [];
  for (String meterType in meterTypeList) {
    Map<String, dynamic> meterTypeUsage = {'meter_type': meterType};
    meterTypeUsageList.add(meterTypeUsage);
  }

  for (var meterGroupUsage in meterGroupUsageList) {
    String meterType = meterGroupUsage['meter_type'];
    Map<String, dynamic> meterGroupUsageSummary =
        meterGroupUsage['meter_group_usage_summary'];
    var meterUsageList = meterGroupUsageSummary['meter_usage_list'];

    for (Map<String, dynamic> meter in meterUsageList) {
      var meterUsageSummary = meter['meter_usage_summary'];
      final multiplierFactor =
          meter['multiplier_factor'] ?? meterUsageSummary['multiplier_factor'];
      final factoredUsage = _applyMeterMultiplier(
        meterUsageSummary['usage'],
        multiplierFactor,
      );
      final meterUsage = factoredUsage is num
          ? factoredUsage.toDouble()
          : double.tryParse(factoredUsage?.toString() ?? '');

      if (meterUsage == null) {
        continue;
      }

      for (var meterTypeUsage in meterTypeUsageList) {
        if (meterTypeUsage['meter_type'] == meterType) {
          double? typeUsage = meterTypeUsage['usage'];
          typeUsage ??= 0;
          typeUsage += meterUsage;
          meterTypeUsage['usage'] = typeUsage;
          break;
        }
      }
    }
  }

  for (var meterTypeUsage in meterTypeUsageList) {
    String meterType = meterTypeUsage['meter_type'];
    dynamic usage = meterTypeUsage['usage'] ?? '';
    item['usage_${meterType.toLowerCase()}'] = usage.toString();
    item['usage_${meterType.toLowerCase()}_color'] = Colors.green;
  }
}

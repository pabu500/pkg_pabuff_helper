import 'package:flutter/material.dart';

void populateListItemMeterUsage(Map<String, dynamic> item) {
  if (item['meter_usage_summary'] != null) {
    var meterUsageSummary = item['meter_usage_summary'];
    item['first_reading_timestamp'] =
        meterUsageSummary['first_reading_timestamp'];
    item['last_reading_timestamp'] =
        meterUsageSummary['last_reading_timestamp'];
    item['first_reading_value'] = meterUsageSummary['first_reading_value'];
    item['last_reading_value'] = meterUsageSummary['last_reading_value'];
    item['usage'] = meterUsageSummary['usage'];
    item['usage_color'] = Colors.green;
  }
}

void populateListItemTenantUsage(Map<String, dynamic> item, var meterTypeList) {
  if (item['tenant_usage_summary'] != null) {
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
        String firstReadingTimestamp =
            meterUsageSummary['first_reading_timestamp'];
        String lastReadingTimestamp =
            meterUsageSummary['last_reading_timestamp'];
        String firstReadingValue = meterUsageSummary['first_reading_value'];
        String lastReadingValue = meterUsageSummary['last_reading_value'];
        String meterUsageStr = meterUsageSummary['usage'];
        double? meterUsage = double.tryParse(meterUsageStr);

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
}

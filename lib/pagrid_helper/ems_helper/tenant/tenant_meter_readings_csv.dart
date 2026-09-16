import 'package:csv/csv.dart';

const tenantMeterReadingsHeaders = [
  'Tenant Name',
  'Meter Group Label',
  'Meter Type',
  'Meter SNo',
  'Meter Status',
  'Alt Name',
  'Building',
  'Level',
  'First Reading Date',
  'First Reading Value',
  'Last Reading Date',
  'Last Reading Value',
  'Usage',
];

const _keys = [
  'tenant_name',
  'meter_group_label',
  'meter_type',
  'meter_sn',
  'meter_status',
  'alt_name',
  'building',
  'level',
  'first_reading_time',
  'first_reading_val',
  'last_reading_time',
  'last_reading_val',
  'usage',
];

String tenantMeterReadingsCsv(List<dynamic> rows) {
  final table = <List<dynamic>>[
    tenantMeterReadingsHeaders,
    for (final row in rows) [for (final key in _keys) _cell(row[key])],
  ];
  return const ListToCsvConverter().convert(table);
}

/// Builds export rows from the usage summary already displayed on screen.
/// This keeps downloads working while the backend export extension is rolling out.
List<Map<String, dynamic>> tenantMeterReadingsFromUsageSummary(
  String tenantName,
  List<Map<String, dynamic>> groups,
) {
  final rows = <Map<String, dynamic>>[];
  for (final group in groups) {
    final summary = group['meter_group_usage_summary'];
    if (summary is! Map) continue;
    final meters = summary['meter_list_usage_summary'];
    if (meters is! List) continue;
    for (final value in meters) {
      if (value is! Map) continue;
      rows.add({
        'tenant_name': tenantName,
        'meter_group_label': group['meter_group_label'] ?? '',
        'meter_type': value['meter_type'] ?? group['meter_type'] ?? '',
        'meter_sn': value['item_sn'] ?? value['meter_sn'] ?? '',
        'meter_status': value['lc_status'] ?? value['status'] ?? '',
        'alt_name': value['alt_name'] ?? '',
        'building': value['loc_building'] ?? value['mms_building'] ?? '',
        'level': value['loc_level'] ?? value['mms_level'] ?? '',
        'first_reading_time': value['first_reading_time'] ?? '',
        'first_reading_val': value['first_reading_val'] ?? '',
        'last_reading_time': value['last_reading_time'] ?? '',
        'last_reading_val': value['last_reading_val'] ?? '',
        'usage': value['usage'] ?? '',
      });
    }
  }
  return rows;
}

/// Combines every loaded tenant into a single page-level export.
List<dynamic> tenantMeterReadingsFromTenants(
  List<Map<String, dynamic>> tenants,
) {
  final rows = <dynamic>[];
  for (final tenant in tenants) {
    final exportRows = tenant['meter_readings_export'];
    if (exportRows is List) {
      rows.addAll(exportRows);
      continue;
    }
    final groups = <Map<String, dynamic>>[];
    final usageSummary = tenant['tenant_usage_summary'];
    if (usageSummary is List) {
      for (final group in usageSummary) {
        if (group is Map<String, dynamic>) groups.add(group);
      }
    }
    final tenantName = (tenant['tenant_label']?.toString().isNotEmpty ?? false)
        ? tenant['tenant_label'].toString()
        : tenant['tenant_name']?.toString() ?? '';
    rows.addAll(tenantMeterReadingsFromUsageSummary(tenantName, groups));
  }
  return rows;
}

Object _cell(dynamic value) {
  if (value == null || value == '-') return '';
  if (value is num) return value;
  final text = value.toString();
  // Preserve numerical readings, including negative usage, while escaping text formulas.
  if (num.tryParse(text) == null && RegExp(r'^\s*[=+@-]').hasMatch(text)) {
    return "'$text";
  }
  return text;
}

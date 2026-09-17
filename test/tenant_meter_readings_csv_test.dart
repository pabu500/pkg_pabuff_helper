import 'package:buff_helper/pagrid_helper/ems_helper/tenant/tenant_meter_readings_csv.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports the requested columns and safely escapes text', () {
    final csv = tenantMeterReadingsCsv([
      {
        'tenant_name': 'Laboratory, "North"',
        'meter_sn': '000123',
        'first_reading_val': '0.000',
        'last_reading_val': '12.345',
        'usage': '-1.250',
        'alt_name': '=1+1',
      },
    ]);
    final table = const CsvToListConverter(shouldParseNumbers: false).convert(csv);
    expect(table.first, tenantMeterReadingsHeaders);
    expect(table.first.length, 13);
    expect(table[1].length, 13);
    expect(table[1][3], '000123');
    expect(table[1][5], "'=1+1");
    expect(table[1][12], '-1.250');
  });

  test('combines backend and displayed usage rows', () {
    final rows = tenantMeterReadingsFromTenants([
      {
        'tenant_name': 'tenant-1',
        'meter_readings_export': [
          {'tenant_name': 'Tenant One', 'meter_sn': 'E1'},
        ],
      },
      {
        'tenant_name': 'tenant-2',
        'tenant_label': 'Tenant Two',
        'tenant_usage_summary': [
          {
            'meter_group_label': 'Water',
            'meter_type': 'W',
            'meter_group_usage_summary': {
              'meter_list_usage_summary': [
                {'item_sn': 'W1', 'usage': '5.000'},
              ],
            },
          },
        ],
      },
    ]);
    expect(rows.length, 2);
    expect(rows[0]['meter_sn'], 'E1');
    expect(rows[1]['tenant_name'], 'Tenant Two');
    expect(rows[1]['meter_sn'], 'W1');
    expect(rows[1]['usage'], '5.000');
  });
}

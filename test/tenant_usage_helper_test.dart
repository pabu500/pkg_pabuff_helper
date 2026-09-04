import 'package:buff_helper/pagrid_helper/ems_helper/tenant/tenant_usage_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getMultiplierFactoredTenantUsage', () {
    test('applies percentage and each meter multiplier before summing', () {
      final summary = <String, dynamic>{
        'meter_group_usage_list': [
          {
            'meter_type': 'E',
            'meter_group_usage_summary': {
              'meter_usage_list': [
                {
                  'multiplier_factor': '10',
                  'meter_usage_summary': {
                    'usage': '5',
                    'percentage': '100',
                  },
                },
                {
                  'meter_usage_summary': {
                    'usage': 3,
                    'percentage': 50,
                    'multiplier_factor': 2,
                  },
                },
              ],
            },
          },
        ],
      };

      expect(getMultiplierFactoredTenantUsage(summary, 'E'), 53);
    });

    test('defaults missing percentages and multipliers', () {
      final summary = <String, dynamic>{
        'meter_group_usage_list': [
          {
            'meter_type': 'W',
            'meter_group_usage_summary': {
              'meter_usage_list': [
                {
                  'meter_usage_summary': {'usage': '4.5'},
                },
              ],
            },
          },
        ],
      };

      expect(getMultiplierFactoredTenantUsage(summary, 'w'), 4.5);
      expect(getMultiplierFactoredTenantUsage(summary, 'E'), isNull);
    });
  });
}

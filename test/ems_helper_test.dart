import 'package:buff_helper/pag_helper/ems/ems_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('populateListItemMeterUsage', () {
    test('applies the meter multiplier to displayed usage values', () {
      final item = <String, dynamic>{
        'multiplier_factor': '10',
        'meter_usage_summary': {
          'usage': '5',
          'usage_import': '3.5',
          'usage_export': 2,
        },
      };

      populateListItemMeterUsage(item);

      expect(item['usage'], '50.0');
      expect(item['usage_import'], '35.0');
      expect(item['usage_export'], 20.0);
    });

    test('defaults the multiplier to one for older responses', () {
      final item = <String, dynamic>{
        'meter_usage_summary': {
          'usage': '5',
          'usage_import': null,
          'usage_export': 'invalid',
        },
      };

      populateListItemMeterUsage(item);

      expect(item['usage'], '5.0');
      expect(item['usage_import'], isNull);
      expect(item['usage_export'], 'invalid');
    });
  });
}

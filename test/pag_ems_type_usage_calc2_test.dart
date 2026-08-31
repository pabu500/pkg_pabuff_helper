import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc2.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc_rl2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PagEmsTypeUsageCalc2', () {
    test('applies each meter multiplier before summing generated usage', () {
      final calc = PagEmsTypeUsageCalc2(
        costDecimals: 2,
        meterType: 'W',
        rate: 2,
        autoUsageSummary: {
          'meter_group_usage_list': [
            {
              'meter_type': 'W',
              'meter_group_usage_summary': {
                'meter_usage_list': [
                  {
                    'meter_usage_summary': {
                      'usage': '5',
                      'percentage': '100',
                      'multiplier_factor': '10',
                    },
                  },
                  {
                    'meter_usage_summary': {
                      'usage': '3',
                      'percentage': '50',
                      'multiplier_factor': '2',
                    },
                  },
                ],
              },
            },
          ],
        },
        manualUsageList: const [
          {'meter_type': 'W', 'usage': 2.0},
        ],
      );

      calc.doSingularCalc();

      expect(calc.getTypeUsage('W')?.usage, 55);
      expect(calc.getTypeUsage('W')?.usageFactored, 55);
      expect(calc.getTypeUsage('W')?.factor, isNull);
      expect(calc.getTypeUsage('W')?.cost, 110);
    });
  });

  group('PagEmsTypeUsageCalcRl2', () {
    test('uses released billed auto usage without a usage factor', () {
      final calc = PagEmsTypeUsageCalcRl2(
        costDecimals: 2,
        meterType: 'E',
        billedAutoUsage: 50,
        billedManualUsage: 4,
        billedRate: 2,
        lineItemList: const [],
      );

      calc.doSingularCalc();

      expect(calc.getTypeUsage('E')?.usage, 54);
      expect(calc.getTypeUsage('E')?.usageFactored, 54);
      expect(calc.getTypeUsage('E')?.factor, isNull);
      expect(calc.getTypeUsage('E')?.cost, 108);
    });
  });
}

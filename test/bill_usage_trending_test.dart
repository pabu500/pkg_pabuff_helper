import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/bill_usage_trending.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/billing_helper2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected bill wins over history and future bills are excluded', () {
    final result = prepBillUsageTrending(
      {
        'cycle_str': '2026-09',
        'billed_usage_trending': [
          {'billed_time_label': '2026-10', 'billed_total_usage_e': 999},
          {'billed_time_label': '2026-09', 'billed_total_usage_e': 888},
          {'billed_time_label': '2026-8', 'billed_total_usage_e': '80.5'},
        ],
      },
      {'E': 100, 'W': null},
    );
    expect(result['E'], [
      {'time': '2026-09', 'label': '2026-09', 'value': 100.0},
      {'time': '2026-08', 'label': '2026-08', 'value': 80.5},
    ]);
    expect(result['W'], isEmpty);
  });

  test('keeps six newest months and respects the bill history start month', () {
    final bill = {
      'cycle_str': '2026-09',
      'billed_usage_trending': [
        for (var month = 1; month <= 8; month++)
          {'billed_time_label': '2026-$month', 'billed_total_usage_e': month},
      ],
    };
    final result = prepBillUsageTrending(bill, {'E': 9});
    expect(result['E']!.map((item) => item['label']), [
      '2026-09',
      '2026-08',
      '2026-07',
      '2026-06',
      '2026-05',
      '2026-04',
    ]);
    bill['bill_bar_from_timestamp'] = '2026-07-01T00:00:00';
    expect(prepBillUsageTrending(bill, {'E': 9})['E']!.length, 2);
  });

  test(
    'uses the bill period midpoint when cycle is unavailable; zero is valid',
    () {
      final result = prepBillUsageTrending(
        {
          'from_timestamp': '2026-08-31T23:59:59',
          'to_timestamp': '2026-09-30T23:59:59',
          'billed_usage_trending': [
            {'billed_time_label': '2026-08', 'billed_total_usage_e': 0},
            {'billed_time_label': '2026-13', 'billed_total_usage_e': 123},
            {'billed_time_label': 'bad', 'billed_total_usage_e': 123},
            {'billed_time_label': '2026-07', 'billed_total_usage_e': 'NaN'},
          ],
        },
        {'E': 0},
      );
      expect(result['E']!.map((item) => item['label']), ['2026-09', '2026-08']);
      expect(result['E']!.map((item) => item['value']), [0, 0]);
    },
  );

  test(
    'Gen3 trend sums tariff slots once and keeps history in display units',
    () {
      final result = prepCalcedBillInfoRl2({
        'from_timestamp': '2026-09-01T00:00:00',
        'to_timestamp': '2026-10-01T00:00:00',
        'cycle_str': '2026-09',
        'billed_usage_trending': [
          {'billed_time_label': '2026-08', 'billed_total_usage_e': 42},
        ],
        'mini_soa_info': <String, dynamic>{},
        'interest_info': <String, dynamic>{},
        'line_item_info': <String, dynamic>{},
        'singular_billing_rec_list': [
          <String, dynamic>{
            'meter_type': 'E',
            'billed_auto_usage': '10',
            'billed_rate': '2',
          },
          <String, dynamic>{
            'meter_type': 'E',
            'billed_auto_usage': '20',
            'manual_usage': '5',
            'billed_rate': '3',
          },
        ],
      });
      expect(result['trendingE'].map((item) => item['value']), [35, 42]);
      expect(result['trendingW'], isNull);
    },
  );
}

import 'dart:io';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/meter_usage_cost_rounding.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc_rl.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc_rl2.dart';
import 'dart:typed_data';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_pdf_bill.dart'
    as gen2;
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_pdf_bill2.dart'
    as gen3;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Keep PDF tests offline and deterministic; standard PDF fonts cover these labels.
class _OfflineCache extends PdfMemoryCache {
  @override
  Future<Uint8List> resolve({
    required String name,
    required Uri uri,
    bool cache = true,
    Map<String, String>? headers,
  }) async {
    final fontDir = Platform.environment['CWP2_PDF_FONT_DIR'];
    if (fontDir != null) {
      return File('$fontDir/$name.ttf').readAsBytes();
    }
    throw StateError('offline test');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalCache = PdfBaseCache.defaultCache;
  setUp(() => PdfBaseCache.defaultCache = _OfflineCache());
  tearDown(() => PdfBaseCache.defaultCache = originalCache);
  test('meter cents reconcile to the billed total including half cents', () {
    final rounding = MeterUsageCostRounding();
    final costs = [for (var i = 0; i < 3; i++) rounding.add(1, 0.335)!];
    expect(costs, [0.34, 0.33, 0.34]);
    expect(costs.reduce((a, b) => a + b), closeTo(1.01, 1e-9));
    expect(MeterUsageCostRounding().add(2.5, 253.87), 634.68);
    expect(MeterUsageCostRounding().add(0, 1), 0);
    expect(MeterUsageCostRounding().add(null, 1), isNull);
    expect(MeterUsageCostRounding().add(1, null), isNull);
    expect(MeterUsageCostRounding().add(-10, 2), -20);
  });
  for (final gen in [2, 3]) {
    test(
      'Gen$gen meter costs render with allocation and billing rate',
      () async {
        final legacyCalc = PagEmsTypeUsageCalcRl(
          costDecimals: 2,
          billedAutoUsageE: 5000.5,
          billedUsageFactorE: 2,
          billedRateE: 0.335,
          lineItemList: const [],
        )..doSingularCalc();
        final calc = PagEmsTypeUsageCalcRl2(
          costDecimals: 2,
          meterType: 'E',
          billedAutoUsage: 10001,
          billedRate: 0.335,
          lineItemList: const [],
        )..doSingularCalc();
        final slot = <String, dynamic>{
          'from_timestamp': '2026-09-01T00:00:00',
          'to_timestamp': '2026-10-01T00:00:00',
          'exclude_auto_usage': 'false',
          'meter_type_rate_info': <String, dynamic>{},
          'usage_calc_rl': legacyCalc,
          'usage_calc_rl2': calc,
          'tenant_usage_summary': {
            'meter_group_usage_list': [
              {
                'meter_type': 'E',
                'meter_group_usage_summary': {
                  'meter_usage_list': [
                    for (final usage in ['10000', '1'])
                      {
                        'meter_usage_summary': {
                          'meter_sn': '20110310-000039',
                          'building_label': 'Tower One',
                          'location_label': '#12-123',
                          'first_reading_timestamp': '2026-09-01T00:00:00',
                          'last_reading_timestamp': '2026-10-01T00:00:00',
                          'first_reading_value': '123456.789',
                          'last_reading_value': '133456.789',
                          'usage': usage,
                          'percentage': '50',
                          'multiplier_factor': '2',
                        },
                      },
                  ],
                },
              },
            ],
          },
        };
        final doc = pw.Document();
        doc.addPage(
          await _invoice(gen, null, singularUsage: [slot]).getPage2(),
        );
        final bytes = await doc.save();
        expect(bytes.length, greaterThan(1000));
        expect(doc.document.pdfPageList.pages.length, 1);
        final output = Platform.environment['CWP2_PDF_PREVIEW_DIR'];
        if (output != null) {
          await File('$output/gen$gen-meter-cost.pdf').writeAsBytes(bytes);
        }
        final multiSlot = pw.Document();
        multiSlot.addPage(
          await _invoice(
            gen,
            null,
            singularUsage: [
              slot,
              {
                ...slot,
                'from_timestamp': '2026-10-01T00:00:00',
                'to_timestamp': '2026-11-01T00:00:00',
              },
            ],
          ).getPage2(),
        );
        final multiSlotBytes = await multiSlot.save();
        expect(multiSlot.document.pdfPageList.pages.length, 1);
        if (output != null) {
          await File(
            '$output/gen$gen-multi-slot.pdf',
          ).writeAsBytes(multiSlotBytes);
        }
      },
    );
    test('Gen$gen charts paginate and leave billing data unchanged', () async {
      final trending = <Map<String, dynamic>>[
        for (var month = 9; month >= 2; month--)
          {'label': '2026-$month', 'value': month * 10.0},
      ];
      final before = trending
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final invoice = _invoice(gen, trending);
      final doc = pw.Document();
      doc.addPage(await invoice.getPage2());
      final bytes = await doc.save();
      expect(bytes.length, greaterThan(1000));
      expect(doc.document.pdfPageList.pages.length, 2);
      expect(trending, before);
      // Bill compilation and single download both use this same page builder.
      final repeated = pw.Document();
      repeated.addPage(await invoice.getPage2());
      expect(await repeated.save(), isNotEmpty);
      expect(trending, before);
      final output = Platform.environment['CWP2_PDF_PREVIEW_DIR'];
      if (output != null)
        await File('$output/gen$gen-trending.pdf').writeAsBytes(bytes);
    });
    test('Gen$gen first bill with zero usage renders a single month', () async {
      final doc = pw.Document();
      doc.addPage(
        await _invoice(gen, [
          {'label': '2026-09', 'value': 0.0},
        ]).getPage2(),
      );
      expect(await doc.save(), isNotEmpty);
      expect(doc.document.pdfPageList.pages.length, 2);
    });
    test('Gen$gen bills without consumption history still render', () async {
      final doc = pw.Document();
      doc.addPage(await _invoice(gen, null).getPage2());
      expect(await doc.save(), isNotEmpty);
      expect(doc.document.pdfPageList.pages.length, 1);
    });
  }
}

dynamic _invoice(
  int gen,
  List<Map<String, dynamic>>? trending, {
  List<Map<String, dynamic>> singularUsage = const [],
}) {
  final constructor = gen == 2
      ? gen2.PagPdfBillCwP2.new
      : gen3.PagPdfBillCwP2Gen3.new;
  return Function.apply(constructor, [], <Symbol, dynamic>{
    #customerName: '',
    #tenantAccountNumber: '',
    #customerCompanyTradingName: '',
    #tenantBillingAddressLine1: '',
    #tenantBillingAddressLine2: '',
    #tenantBillingAddressLine3: '',
    #customerType: '',
    #strDepositAmount: '',
    #paymentMethod: '',
    #gst: null,
    #billingRecName: '',
    #billLabel: '',
    #invoiceNumber: 'CWP2-2026-09-001',
    #strFrom: '',
    #strTo: '',
    #strEffectiveTo: '',
    #strBillDate: '',
    #strBillTimeRange: '',
    #subTotalAmount: null,
    #gstAmount: null,
    #totalAmount: null,
    #cycleTotalAmount: null,
    #totalUsageCost: null,
    #typeRateE: null,
    #typeRateW: null,
    #typeRateB: null,
    #typeRateN: null,
    #typeRateG: null,
    #typeRateSE1: null,
    #typeUsageE: null,
    #typeUsageW: null,
    #typeUsageB: null,
    #typeUsageN: null,
    #typeUsageG: null,
    #typeUsageSE1: null,
    #typeCostE: null,
    #typeCostW: null,
    #typeCostB: null,
    #typeCostN: null,
    #typeCostG: null,
    #typeCostSE1: null,
    #trendingE: trending,
    #trendingW: trending,
    #trendingB: trending,
    #trendingN: trending,
    #trendingG: trending,
    #trendingSE1: trending,
    #tax: 0.0,
    #paymentInfo: '',
    #interestInfo: null,
    #lineItemLabel1: null,
    #lineItemValue1: null,
    #lineItemLabel2: null,
    #lineItemValue2: null,
    #lineItemLabel3: null,
    #lineItemValue3: null,
    #billedBciInfoList: null,
    #payableAmount: null,
    #strDueDate: '',
    #baseColor: PdfColors.blueGrey,
    #accentColor: PdfColors.blueGrey,
    #assetFolder: null,
    #tenantSingularUsageInfoList: List<Map<String, dynamic>>.of(singularUsage),
    #miniSoaInfo: null,
    #billedAmgrCompanyTradingName: null,
    #billedAmgrCompanyRegNumber: null,
    #billedAmgrGstRegNumber: null,
    #amgrAddressLine1: null,
    #amgrAddressLine2: null,
    #amgrAddressLine3: null,
    #amgrBankAccountName: null,
    #amgrBankAccountNumber: null,
    #amgrBankLabel: null,
    #amgrBankCode: null,
    #amgrBankBranchCode: null,
    #amgrBankSwiftCode: null,
    #amgrBankPayNow: null,
    #strCollectionStartDate: '',
    #strCollectionEndDate: '',
  });
}

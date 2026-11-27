@TestOn('browser')
library;

import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_bill.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_bill_lc_status_op2.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view2.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/wgt_pag_invoice_details.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/wgt_pag_tenant_composite_usage_summary.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/wgt_pag_tenant_composite_usage_summary_rl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

const _generatedCaption = 'Current values — frozen when moved to PV';
const _giroNote =
    'If invoice due date falls on a non-business day, GIRO deduction (if applicable) will be processed on the next business day.';

Future<void> _pumpPanel(WidgetTester tester, Map<String, dynamic> info) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WgtPagInvoiceDetails(billInfo: info),
          ),
        ),
      ),
    );

void main() {
  testWidgets('stacks invoice sections and every tariff slot on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpPanel(tester, {
      'lc_status': 'generated',
      'customer_company_trading_name': 'Example Tenant Pte Ltd',
      'tenant_account_number': 'TEN-01',
      'tenant_label': 'Tenant 1',
      'tenant_billing_address_line_1': 'Example Billing Road',
      'tenant_building_address_line_1': 'Example Premises Road',
      'tenant_building_address_line_2': 'Block A',
      'tenant_location_label': '#01-02',
      'tenant_building_address_line_3': 'Singapore 123456',
      'billed_amgr_company_trading_name': 'Example AMGR',
      'billed_amgr_company_reg_number': 'AMGR-01',
      'billed_amgr_gst_reg_number': 'GST-01',
      'billed_amgr_uen': 'UEN-01',
      'amgr_address_line_1': 'Example Biller Road',
      'amgr_bank_label': 'Example Bank',
      'amgr_bank_account_name': 'Example Account',
      'amgr_bank_account_number': '01234',
      'amgr_bank_code': '010',
      'amgr_bank_branch_code': '020',
      'amgr_bank_swift_code': 'SWIFT001',
      'amgr_bank_paynow': 'PAYNOW-01',
      'deposit_amount': 1200,
      'payment_method': 'giro',
      'singular_billing_rec_list': [
        {
          'meter_type': 'E',
          'from_timestamp': '2026-09-01T00:00:00',
          'to_timestamp': '2026-09-16T00:00:00',
          'billed_tp_note': 'Package one',
          'billed_tp_note2': 'Package two',
          'billed_tpt_rate_note': 'Rate note one',
          'billed_tpt_cycle_note': 'Cycle note one',
        },
        {
          'meter_type': 'E',
          'from_timestamp': '2026-09-16T00:00:00',
          'to_timestamp': '2026-10-01T00:00:00',
          'billed_tpt_rate_note': 'Rate note two',
        },
        {
          'tariff_rate_id_w': '4',
          'tariff_rate_id_e': null,
          'billed_tp_note': 'Water tariff',
        },
      ],
    });

    for (final value in [
      'Invoice details',
      _generatedCaption,
      'Example Tenant Pte Ltd',
      'TEN-01',
      'Tenant 1',
      'Example Billing Road',
      'Example Premises Road, Block A, #01-02, Singapore 123456',
      'Example AMGR',
      'AMGR-01',
      'GST-01',
      'UEN-01',
      'Example Biller Road',
      'Example Bank',
      'Example Account',
      '01234',
      '010',
      '020',
      'SWIFT001',
      'PAYNOW-01',
      r'$1,200',
      'GIRO',
      'Note for GIRO tenants:',
      _giroNote,
      'Electricity (01 Sep 2026 – 15 Sep 2026)',
      'Electricity (16 Sep 2026 – 30 Sep 2026)',
      'Package one',
      'Package two',
      'Rate note one',
      'Cycle note one',
      'Rate note two',
      'Water',
      'Water tariff',
    ]) {
      expect(find.text(value), findsOneWidget);
    }
    final headings = [
      'Invoice details',
      'Payer',
      'Premises',
      'Biller (AMGR)',
      'Remittance',
      'Payment',
      'Tariff notes',
      'Electricity (01 Sep 2026 – 15 Sep 2026)',
      'Electricity (16 Sep 2026 – 30 Sep 2026)',
      'Water',
    ].map((title) => tester.getTopLeft(find.text(title))).toList();
    for (var i = 1; i < headings.length; i++) {
      expect(headings[i].dx, headings.first.dx);
      expect(headings[i].dy, greaterThan(headings[i - 1].dy));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows visible dashes on narrow screens without a GIRO note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpPanel(tester, {
      'lc_status': 'pv',
      'tenant_billing_address_line_1': '   ',
      'payment_method': 'non_giro',
      'deposit_amount': 0,
      'landlord_logo_png_base64': '*invalid*',
    });
    expect(find.text(_generatedCaption), findsNothing);
    expect(find.text('Non-Giro'), findsOneWidget);
    expect(find.text(r'$0'), findsOneWidget);
    expect(find.text(_giroNote), findsNothing);
    for (final label in [
      'Billing address line 1',
      'Principal address',
      'UEN',
      'Landlord logo',
    ]) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: row, matching: find.text('—')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reloads invoice fields and keeps them inside the totals block in both views',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Keep the fixed-width bill header from overflowing with the test font.
      tester.platformDispatcher.textScaleFactorTestValue = 0.45;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final user = MdlPagUser(id: 1, username: 'tester')
        ..selectedScope = MdlPagScopeProfile(
          projectProfile: MdlPagProjectProfile(
            id: 1,
            name: 'cw_p2',
            label: 'CW',
            timezone: 8,
            assetFolder: 'assets',
            portalProjectScope: PagPortalProjectScope.values.first,
            appContextConfigList: [],
          ),
        );
      final config = MdlPagAppConfig(
        portalType: PagPortalType.pagConsole,
        lazyLoadScope: '',
        loadDashboard: false,
        userSvcEnv: 'dev',
        oreSvcEnv: 'dev',
        activePortalPagProjectScopeList: [],
      );
      var status = PagBillingLcStatus.generated;
      var payer = 'Live payer';
      final loads = <String>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: WgtPagCompositeBillView2(
                  appConfig: config,
                  loggedInUser: user,
                  billingRecIndexStr: '77',
                  defaultBillLcStatusStr: 'generated',
                  listContextType: PagListContextType.info,
                  isBillMode: true,
                  genTypes: const ['generated'],
                  modes: const ['wgt'],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final panel = find.byType(WgtPagInvoiceDetails);
          final generatedSummary = find.byType(
            WgtPagTenantCompositeUsageSummary,
          );
          final releasedSummary = find.byType(
            WgtPagTenantCompositeUsageSummaryRl,
          );
          final statusControl = find.byType(WgtPagBillLcStatusOp2);

          void expectDetailsInTotals(Finder summary) {
            final payable = find.descendant(
              of: summary,
              matching: find.text('Total Payable'),
            );
            expect(payable, findsOneWidget);
            final primary = Theme.of(tester.element(payable))
                .colorScheme
                .primary;
            final totals = find.ancestor(
              of: payable,
              matching: find.byWidgetPredicate((widget) {
                if (widget is! Container) return false;
                final decoration = widget.decoration;
                return decoration is BoxDecoration &&
                    decoration.border?.top.color == primary;
              }),
            );
            expect(totals, findsOneWidget);
            expect(
              find.descendant(of: totals, matching: panel),
              findsOneWidget,
            );
            TextStyle? styleOf(String text) =>
                tester.widget<Text>(find.text(text)).style;
            expect(styleOf('Invoice details'), styleOf('Cycle Total'));
            expect(styleOf('Tariff notes'), styleOf('Cycle Total'));
            for (final heading in [
              'Payer',
              'Premises',
              'Biller (AMGR)',
              'Remittance',
              'Payment',
            ]) {
              expect(styleOf(heading), styleOf('Interest'));
            }
            final payableBottom = tester.getBottomLeft(payable).dy;
            final detailsTop = tester.getTopLeft(panel).dy;
            expect(detailsTop, greaterThan(payableBottom));
            final dividers = find.descendant(
              of: totals,
              matching: find.byType(Divider),
            );
            final dividerPositions = [
              for (var i = 0; i < dividers.evaluate().length; i++)
                tester.getCenter(dividers.at(i)).dy,
            ];
            expect(
              dividerPositions,
              contains(inInclusiveRange(payableBottom, detailsTop)),
            );
          }

          expect(find.text(_generatedCaption), findsOneWidget);
          expect(find.text('Live payer'), findsOneWidget);
          expectDetailsInTotals(generatedSummary);

          status = PagBillingLcStatus.pv;
          payer = 'Frozen payer';
          tester.widget<WgtPagBillLcStatusOp2>(statusControl).onCommitted!(
            status,
          );
          await tester.pumpAndSettle();
          expect(loads, hasLength(2));
          expect(find.text('Frozen payer'), findsOneWidget);
          expect(find.text('Live payer'), findsNothing);
          expect(find.text(_generatedCaption), findsNothing);

          await tester.tap(find.byType(Switch).first);
          await tester.pumpAndSettle();
          expectDetailsInTotals(releasedSummary);
          expect(find.text('Frozen payer'), findsOneWidget);

          status = PagBillingLcStatus.generated;
          payer = 'New live payer';
          tester.widget<WgtPagBillLcStatusOp2>(statusControl).onCommitted!(
            status,
          );
          await tester.pumpAndSettle();
          expect(find.text(_generatedCaption), findsOneWidget);
          expect(find.text('New live payer'), findsOneWidget);
          expect(find.text('Frozen payer'), findsNothing);
          expect(loads, hasLength(4));

          status = PagBillingLcStatus.pv;
          payer = 'Second frozen payer';
          tester.widget<WgtPagBillLcStatusOp2>(statusControl).onCommitted!(
            status,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(Switch).first);
          await tester.pumpAndSettle();
          status = PagBillingLcStatus.released;
          tester.widget<WgtPagBillLcStatusOp2>(statusControl).onCommitted!(
            status,
          );
          await tester.pumpAndSettle();
          expect(loads, hasLength(7));
          expect(loads, everyElement(endsWith('/get_bill')));
          expectDetailsInTotals(releasedSummary);
          expect(find.text('Second frozen payer'), findsOneWidget);
          expect(find.text(_generatedCaption), findsNothing);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          loads.add(request.url.path);
          return http.Response(
            jsonEncode({
              'data': {
                'result_key': 'composite_bill_info',
                'result': {
                  'composite_bill_info': {
                    'billing_rec_id': '77',
                    'lc_status': status.value,
                    'gen_type': 'monthly',
                    'tenant_name': 'tenant',
                    'tenant_label': 'Test tenant',
                    'cycle_str': '2026-09',
                    'from_timestamp': '2026-09-01T00:00:00',
                    'to_timestamp': '2026-10-01T00:00:00',
                    'bill_date_timestamp': '2026-10-02T00:00:00',
                    'billed_due_date_timestamp': '2026-10-15T00:00:00',
                    'billed_gst': '9',
                    'billed_payable_amount': '604.38',
                    'customer_company_trading_name': payer,
                    'mini_soa_info': {},
                    'interest_info': {
                      'total_interest_amount': '0.00',
                      'outstanding_bill_info_list': [],
                    },
                  },
                },
              },
            }),
            200,
          );
        }),
      );
    },
  );
}

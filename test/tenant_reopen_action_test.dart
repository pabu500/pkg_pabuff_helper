import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_lc_status_op.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'tenant_mfd_test.dart' as support;

void main() {
  Future<void> mountPanel(WidgetTester tester, {bool enableEdit = true}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WgtPagTenantLcStatusOp(
              appConfig: support.config,
              loggedInUser: support.user(),
              tenantInfo: const {'id': '1', 'name': 'T1'},
              initialStatus: PagTenantLcStatus.terminated,
              enableEdit: enableEdit,
            ),
          ),
        ),
      );
  for (final admin in [false, true]) {
    testWidgets(
      'offb tag selects reopen and commits with authentication, admin=$admin',
      (tester) async {
        Map<String, dynamic>? written;
        PagTenantLcStatus? committed;
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: WgtPagTenantLcStatusOp(
                    appConfig: support.config,
                    loggedInUser: support.user(),
                    tenantInfo: const {'id': '1', 'name': 'T1'},
                    initialStatus: PagTenantLcStatus.terminated,
                    enableEdit: true,
                    onCommitted: (PagTenantLcStatus status) =>
                        committed = status,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Reopen (back to Offboarding)'), findsNothing);
            await tester.tap(find.text('norm'));
            await tester.pumpAndSettle();
            expect(find.text('Commit'), findsNothing);
            await tester.tap(find.text('offb'));
            await tester.pumpAndSettle();
            expect(find.text('Commit'), admin ? findsOneWidget : findsNothing);
            if (admin) {
              await tester.tap(find.text('Commit'));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));
              expect(find.text('Reopen Confirmation'), findsOneWidget);
              await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
              await tester.pumpAndSettle();
              expect(written, isNull);
              expect(committed, isNull);
              await tester.tap(find.text('Commit'));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));
              await tester.enterText(
                find.byType(TextField),
                ' Correct mistaken termination ',
              );
              await tester.pump();
              await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
              await tester.pumpAndSettle();
              expect(written?['termination_token'], '41');
              expect(written?['reason'], 'Correct mistaken termination');
              expect(written?['tenant_id'], '1');
              expect(written?['scope']['project_name'], 'cw_p2');
              expect(written!.containsKey('group_status_choices'), isFalse);
              expect(committed, PagTenantLcStatus.offboarding);
            } else {
              expect(
                find.text('Return to Offboarding unavailable'),
                findsOneWidget,
              );
              await tester.tap(find.text('Return to Offboarding unavailable'));
              await tester.pumpAndSettle();
              expect(
                find.textContaining('Reopening requires a Project Admin'),
                findsOneWidget,
              );
            }
            await tester.pumpWidget(const SizedBox.shrink());
          },
          () => MockClient((req) async {
            expect(req.headers['Authorization'], startsWith('Bearer '));
            if (req.url.path.endsWith('/reopen_tenant')) {
              written = Map<String, dynamic>.from(
                jsonDecode(req.body)['request'],
              );
              return support.response({'lc_status': 'offb'});
            }
            return support.response({
              'targets': {
                'mfd': {'eligible': false, 'reasons': []},
                if (admin)
                  'offb': {
                    'eligible': true,
                    'reasons': [],
                    'termination_token': '41',
                  },
              },
            });
          }),
        );
      },
    );
  }
  testWidgets('blocked reopen shows all reasons and cannot select offb', (
    tester,
  ) async {
    int writes = 0;
    await http.runWithClient(
      () async {
        await mountPanel(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('offb'));
        await tester.pumpAndSettle();
        expect(find.text('Commit'), findsNothing);
        expect(find.text('Return to Offboarding unavailable'), findsOneWidget);
        expect(find.text('2 reasons'), findsOneWidget);
        await tester.tap(find.text('Return to Offboarding unavailable'));
        await tester.pumpAndSettle();
        expect(find.text('Closing readings are incomplete'), findsOneWidget);
        expect(find.text('Meter M1 would exceed capacity'), findsOneWidget);
        expect(writes, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((req) async {
        if (!req.url.path.endsWith('get_tenant_lc_transition_check')) writes++;
        return support.response({
          'targets': {
            'offb': {
              'eligible': false,
              'reasons': [
                'Closing readings are incomplete',
                'Meter M1 would exceed capacity',
              ],
            },
          },
        });
      }),
    );
  });
  testWidgets(
    'commit rechecks eligibility before opening reopen confirmation',
    (tester) async {
      int previews = 0, writes = 0;
      await http.runWithClient(
        () async {
          await mountPanel(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.text('offb'));
          await tester.pumpAndSettle();
          expect(find.text('Commit'), findsOneWidget);
          await tester.tap(find.text('Commit'));
          await tester.pumpAndSettle();
          expect(previews, 2);
          expect(writes, 0);
          expect(find.byType(TextField), findsNothing);
          expect(
            find.text('Return to Offboarding unavailable'),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient((req) async {
          if (!req.url.path.endsWith('get_tenant_lc_transition_check')) {
            writes++;
          }
          previews++;
          return support.response({
            'targets': {
              'offb': {
                'eligible': previews == 1,
                'reasons': previews == 1
                    ? []
                    : ['Tenant is not terminated; reload'],
                'termination_token': '41',
              },
            },
          });
        }),
      );
    },
  );
  testWidgets(
    'refresh discards offb selection and restores term without committing',
    (tester) async {
      int previews = 0, writes = 0;
      await http.runWithClient(
        () async {
          await mountPanel(tester);
          await tester.pumpAndSettle();
          await tester.tap(find.text('offb'));
          await tester.pumpAndSettle();
          expect(find.text('Commit'), findsOneWidget);
          expect(tester.widget<Text>(find.text('offb')).style?.fontSize, 25);
          await tester.tap(find.byTooltip('Refresh eligibility'));
          await tester.pumpAndSettle();
          expect(find.text('Commit'), findsNothing);
          expect(tester.widget<Text>(find.text('term')).style?.fontSize, 25);
          expect(
            tester.widget<Text>(find.text('offb')).style?.fontSize,
            isNot(25),
          );
          expect(previews, 2);
          expect(writes, 0);
          // The selection can be made again after refreshing.
          await tester.tap(find.text('offb'));
          await tester.pumpAndSettle();
          expect(find.text('Commit'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient((req) async {
          if (req.url.path.endsWith('get_tenant_lc_transition_check')) {
            previews++;
          } else {
            writes++;
          }
          return support.response({
            'current_lc_status': 'terminated',
            'targets': {
              'offb': {
                'eligible': true,
                'reasons': [],
                'termination_token': '41',
              },
            },
          });
        }),
      );
    },
  );
  testWidgets('read-only tenant cannot select offb or request reopen', (
    tester,
  ) async {
    int requests = 0;
    await http.runWithClient(
      () async {
        await mountPanel(tester, enableEdit: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('offb'));
        await tester.pumpAndSettle();
        expect(find.text('Commit'), findsNothing);
        expect(requests, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((req) async {
        requests++;
        return support.response({});
      }),
    );
  });
}

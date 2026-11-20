import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_lc_status_op.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_item_info_edit_panel2.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/tenant_lifecycle_changes.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_delete_op.dart';

MdlPagUser user() => MdlPagUser(id: 1, username: 'tester')
  ..loginToken = 'e30.eyJzdWIiOiJ0ZXN0ZXIiLCJleHAiOjQxMDI0NDQ4MDB9.signature'
  ..selectedScope = MdlPagScopeProfile(
    projectProfile: MdlPagProjectProfile(
      id: 1,
      name: 'cw_p2',
      label: 'CW',
      timezone: 8,
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
http.Response response(Map<String, dynamic> result) => http.Response(
  jsonEncode({
    'data': {
      'result_key': 'result',
      'result': {'result': result},
    },
  }),
  200,
);
void main() {
  for (final status in [
    PagTenantLcStatus.onboarding,
    PagTenantLcStatus.terminated,
  ]) {
    testWidgets(
      '${status.value} previews, confirms and commits MFD with verified claim',
      (tester) async {
        int previews = 0, writes = 0;
        PagTenantLcStatus? committed;
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: WgtPagTenantLcStatusOp(
                    appConfig: config,
                    loggedInUser: user(),
                    tenantInfo: const {'id': '1', 'name': 'Tenant'},
                    initialStatus: status,
                    enableEdit: true,
                    onCommitted: (s) => committed = s,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(previews, 1);
            await tester.tap(find.text('mfd'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Commit'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            expect(previews, 2);
            if (status == PagTenantLcStatus.terminated) {
              expect(find.text('• Group 10'), findsOneWidget);
              expect(
                find.textContaining(
                  'Bills, payments, readings and history are kept.',
                ),
                findsOneWidget,
              );
            } else {
              expect(
                find.text('Saved first readings are kept for audit.'),
                findsOneWidget,
              );
            }
            await tester.enterText(find.byType(TextField), 'Reason');
            await tester.tap(
              find.text(
                status == PagTenantLcStatus.onboarding
                    ? 'Cancel tenant'
                    : 'Mark MFD',
              ),
            );
            await tester.pumpAndSettle();
            expect(writes, 1);
            expect(committed, PagTenantLcStatus.mfd);
            expect(find.text('Commit'), findsNothing);
            expect(tester.takeException(), isNull);
          },
          () => MockClient((req) async {
            if (req.url.path.endsWith('get_tenant_lc_transition_check')) {
              previews++;
              return response({
                'targets': {
                  'mfd': {
                    'eligible': true,
                    'reasons': [],
                    'kind': status == PagTenantLcStatus.onboarding
                        ? 'cancel_onboarding'
                        : 'mark_terminated',
                    'first_readings_saved': true,
                    'assigned_meter_groups': [
                      {'id': '10', 'name': 'Group 10'},
                    ],
                  },
                },
              });
            }
            writes++;
            final data = jsonDecode(req.body) as Map;
            expect(data.toString(), contains('tester'));
            expect(req.headers['Authorization'], startsWith('Bearer '));
            // Audit values are never accepted from the UI body.
            expect(req.body, contains('mfd_remark'));
            expect(req.body, isNot(contains('mfd_by')));
            expect(req.body, isNot(contains('op_username')));
            return response({'lc_status': 'mfd'});
          }),
        );
      },
    );
  }
  testWidgets('removing final group refreshes an open lifecycle panel', (
    tester,
  ) async {
    bool blocked = true;
    int previews = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WgtPagTenantLcStatusOp(
                appConfig: config,
                loggedInUser: user(),
                tenantInfo: const {'id': '1', 'name': 'Tenant'},
                initialStatus: PagTenantLcStatus.onboarding,
                enableEdit: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Mark for deletion unavailable'),
          findsOneWidget,
        );
        await tester.tap(find.text('mfd'));
        await tester.pumpAndSettle();
        expect(find.text('Commit'), findsNothing);
        blocked = false;
        TenantLifecycleChanges.groupsSaved('cw_p2', '1');
        await tester.pumpAndSettle();
        expect(previews, 2);
        await tester.tap(find.text('mfd'));
        await tester.pumpAndSettle();
        expect(find.text('Commit'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((req) async {
        previews++;
        return response({
          'targets': {
            'mfd': {
              'eligible': !blocked,
              'reasons': blocked
                  ? [
                      'Remove meter group(s) Group 10 from the tenant before marking it mfd',
                    ]
                  : [],
              'kind': 'cancel_onboarding',
            },
          },
        });
      }),
    );
  });
  testWidgets('offboarding cannot select MFD', (tester) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WgtPagTenantLcStatusOp(
                appConfig: config,
                loggedInUser: user(),
                tenantInfo: const {'id': '1'},
                initialStatus: PagTenantLcStatus.offboarding,
                enableEdit: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('mfd'));
        await tester.pumpAndSettle();
        expect(find.text('Commit'), findsNothing);
      },
      () => MockClient(
        (req) async => response({
          'targets': {
            'mfd': {'eligible': true},
          },
        }),
      ),
    );
  });
  testWidgets('preview error disables MFD and remains visible', (tester) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WgtPagTenantLcStatusOp(
                appConfig: config,
                loggedInUser: user(),
                tenantInfo: const {'id': '1'},
                initialStatus: PagTenantLcStatus.onboarding,
                enableEdit: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('mfd'));
        await tester.pumpAndSettle();
        expect(find.text('Commit'), findsNothing);
        expect(find.textContaining('preview unavailable'), findsOneWidget);
      },
      () => MockClient(
        (req) async => http.Response(
          jsonEncode({
            'error': {'message': 'm:preview unavailable'},
          }),
          500,
        ),
      ),
    );
  });
  testWidgets('MFD tenant properties contain no Delete widget', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: PagUserProvider()..setCurrentUser(user()),
          child: MaterialApp(
            home: Scaffold(
              body: WgtPagItemInfoEditPanel2(
                appConfig: config,
                itemKind: PagItemKind.tenant,
                strItemIndex: '1',
                itemDisplayName: 'Tenant',
                itemInfoMap: const {
                  'id': '1',
                  'name': 'Tenant',
                  'lc_status': 'mfd',
                },
                fieldList: const [
                  {
                    'col_key': 'name',
                    'value': 'Tenant',
                    'show_edit_panel': false,
                  },
                  {'col_key': 'lc_status', 'value': 'mfd', 'label': 'Status'},
                ],
                isEditableByAcl: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WgtItemDeleteOp), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => MockClient((req) async => response({})));
  });
}

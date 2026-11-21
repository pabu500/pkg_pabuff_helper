import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_item_info_edit_panel2.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

const tenantName = 'tejhl-g-260803-224';
final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

Future<void> openEditor(
  WidgetTester tester, {
  String status = 'mfd',
  bool editable = true,
  bool admin = true,
  bool projectScope = true,
  bool statusOptionMissing = false,
  bool includeStatusField = true,
  VoidCallback? onUpdate,
}) async {
  final user = MdlPagUser(id: 1, username: 'tester')
    ..loginToken = 'e30.eyJzdWIiOiJ0ZXN0ZXIiLCJleHAiOjQxMDI0NDQ4MDB9.signature'
    ..selectedRole = MdlPagRole(
      id: 2,
      name: 'project-admin',
      label: admin ? 'Project Admin' : 'Viewer',
    )
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
  if (!projectScope) {
    user.selectedScope.buildingProfile = MdlPagBuildingProfile(
      id: 2,
      name: 'Building',
      label: 'Building',
    );
  }
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: PagUserProvider()..setCurrentUser(user),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => WgtPagItemInfoEditPanel2(
                  appConfig: config,
                  strItemIndex: '1',
                  itemKind: PagItemKind.tenant,
                  itemDisplayName: tenantName,
                  itemInfoMap: {
                    'id': '1',
                    'name': tenantName,
                    'lc_status': status,
                  },
                  fieldList: [
                    const {
                      'col_key': 'name',
                      'value': tenantName,
                      'show_edit_panel': false,
                    },
                    if (includeStatusField)
                      {
                        'col_key': 'lc_status',
                        'value': statusOptionMissing ? null : status,
                        'show_edit_panel': false,
                      },
                  ],
                  isEditableByAcl: editable,
                  onUpdate: onUpdate,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> confirmDeletion(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Delete tenant'));
  await tester.pumpAndSettle();
  final confirm = find.widgetWithText(TextButton, 'Confirm');
  final dialog = find.byType(AlertDialog);
  expect(
    find.descendant(of: dialog, matching: find.byType(TextField)),
    findsNothing,
  );
  expect(
    find.descendant(of: dialog, matching: find.textContaining(tenantName)),
    findsOneWidget,
  );
  expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'MFD record shows Delete when dropdown has no matching status option',
    (tester) async {
      await openEditor(tester, statusOptionMissing: true);
      expect(find.text('mfd'), findsOneWidget);
      expect(find.byTooltip('Delete tenant'), findsOneWidget);
    },
  );
  testWidgets(
    'MFD record shows Delete when status is absent from editor fields',
    (tester) async {
      await openEditor(tester, includeStatusField: false);
      expect(find.text('mfd'), findsOneWidget);
      expect(find.byTooltip('Delete tenant'), findsOneWidget);
    },
  );
  for (final status in ['onb', 'normal', 'offb', 'terminated']) {
    testWidgets('delete is hidden for $status tenants', (tester) async {
      await openEditor(tester, status: status);
      expect(find.byTooltip('Delete tenant'), findsNothing);
    });
  }
  for (final admin in [true, false]) {
    testWidgets('delete respects editor and admin permissions ($admin)', (
      tester,
    ) async {
      await openEditor(tester, admin: admin, editable: !admin);
      expect(find.byTooltip('Delete tenant'), findsNothing);
    });
  }
  testWidgets('delete is hidden below project scope', (tester) async {
    await openEditor(tester, projectScope: false);
    expect(find.byTooltip('Delete tenant'), findsNothing);
  });
  testWidgets('Cancel sends no delete and keeps properties open', (
    tester,
  ) async {
    var calls = 0;
    await http.runWithClient(
      () async {
        await openEditor(tester);
        await tester.tap(find.byTooltip('Delete tenant'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(calls, 0);
        expect(find.byType(WgtPagItemInfoEditPanel2), findsOneWidget);
      },
      () => MockClient((request) async {
        if (request.url.path == '/item/delete_item') calls++;
        return http.Response('{}', 500);
      }),
    );
  });
  testWidgets('confirmed deletion uses delete_item, refreshes and closes', (
    tester,
  ) async {
    int refreshed = 0;
    http.Request? sent;
    await http.runWithClient(
      () async {
        await openEditor(tester, onUpdate: () => refreshed++);
        await confirmDeletion(tester);
        expect(refreshed, 1);
        expect(find.byType(WgtPagItemInfoEditPanel2), findsNothing);
        expect(sent!.url.path, '/item/delete_item');
        expect(sent!.headers['Authorization'], startsWith('Bearer e30.'));
        final payload = jsonDecode(sent!.body) as Map;
        expect(payload['request'], containsPair('item_kind', 'tenant'));
        expect(payload['request'], containsPair('item_id_value', '1'));
        expect(payload['request'], containsPair('item_name', tenantName));
        expect(payload.toString(), contains('delete'));
      },
      () => MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'result_key': 'delete_result',
              'result': {
                'delete_result': {'id': '1', 'name': tenantName},
              },
            },
          }),
          200,
        );
      }),
    );
  });
  testWidgets('marking MFD exposes Delete without reopening properties', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await openEditor(tester, status: 'onb');
        expect(find.byTooltip('Delete tenant'), findsNothing);
        await tester.tap(find.text('mfd'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Commit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.enterText(find.byType(TextField).at(0), 'mfd');
        await tester.enterText(find.byType(TextField).at(1), tenantName);
        await tester.pump();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Delete tenant'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        final result =
            request.url.path.endsWith('get_tenant_lc_transition_check')
            ? {
                'targets': {
                  'mfd': {
                    'eligible': true,
                    'reasons': [],
                    'kind': 'cancel_onboarding',
                  },
                },
              }
            : request.url.path.endsWith('update_item_lc_status')
            ? {'lc_status': 'mfd'}
            : {};
        return http.Response(
          jsonEncode({
            'data': {
              'result_key': 'result',
              'result': {'result': result},
            },
          }),
          200,
        );
      }),
    );
  });
  for (final blocked in [true, false]) {
    testWidgets(
      'rejected or unconfirmed deletion keeps editor open ($blocked)',
      (tester) async {
        int refreshed = 0;
        await http.runWithClient(
          () async {
            await openEditor(tester, onUpdate: () => refreshed++);
            await confirmDeletion(tester);
            expect(refreshed, 0);
            expect(find.byType(WgtPagItemInfoEditPanel2), findsOneWidget);
            expect(
              find.textContaining(
                blocked ? 'has bills' : 'could not be confirmed',
              ),
              findsOneWidget,
            );
          },
          () => MockClient(
            (_) async => http.Response(
              jsonEncode(
                blocked
                    ? {
                        'error': {
                          'message':
                              'm:Cannot delete tenant because it has bills',
                        },
                      }
                    : {
                        'success': true,
                        'data': {
                          'result_key': 'delete_result',
                          'result': {'delete_result': {}},
                        },
                      },
              ),
              200,
            ),
          ),
        );
      },
    );
  }
}

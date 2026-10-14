import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_item_info_edit_panel2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

const groupName = 'mg-e-261013-72548';
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
  String service = 'ems',
  bool editable = true,
  bool admin = true,
  VoidCallback? onUpdate,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final user = MdlPagUser(id: 1, username: 'tester');
  user.selectedRole = MdlPagRole(
    id: 2,
    name: 'project-admin',
    label: admin ? 'Project Admin' : 'Viewer',
  );
  user.selectedScope = MdlPagScopeProfile(
    projectProfile: MdlPagProjectProfile(
      id: 1,
      name: 'cw_p2',
      label: 'CW',
      portalProjectScope: PagPortalProjectScope.values.first,
      timezone: 8,
      appContextConfigList: [],
    ),
  );
  final provider = PagUserProvider()..setCurrentUser(user);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => WgtPagItemInfoEditPanel2(
                    appConfig: config,
                    strItemIndex: '2674',
                    itemKind: PagItemKind.meterGroup,
                    itemDisplayName: groupName,
                    itemInfoMap: {'service_type': service},
                    fieldList: [
                      const {
                        'col_key': 'name',
                        'value': groupName,
                        'show_edit_panel': false,
                      },
                      {
                        'col_key': 'service_type',
                        'value': service,
                        'show_edit_panel': false,
                      },
                    ],
                    isEditableByAcl: editable,
                    onUpdate: onUpdate,
                  ),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> confirmDeletion(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Delete meter group'));
  await tester.pumpAndSettle();
  var confirm = tester.widget<TextButton>(
    find.widgetWithText(TextButton, 'Confirm'),
  );
  expect(confirm.onPressed, isNull);
  await tester.enterText(find.byType(TextField).at(0), 'delete');
  await tester.pump();
  confirm = tester.widget<TextButton>(
    find.widgetWithText(TextButton, 'Confirm'),
  );
  expect(confirm.onPressed, isNull);
  await tester.enterText(find.byType(TextField).at(1), groupName);
  await tester.pump();
  confirm = tester.widget<TextButton>(
    find.widgetWithText(TextButton, 'Confirm'),
  );
  expect(confirm.onPressed, isNotNull);
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('delete is available for EMS group without MFD status', (
    tester,
  ) async {
    await openEditor(tester);
    expect(find.byTooltip('Delete meter group'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete meter group'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Meter Group'), findsOneWidget);
    expect(
      find.textContaining('onboarding/offboarding readings'),
      findsOneWidget,
    );
  });

  for (final service in ['comm', 'evs']) {
    testWidgets('delete is hidden for $service groups', (tester) async {
      await openEditor(tester, service: service);
      expect(find.byTooltip('Delete meter group'), findsNothing);
    });
  }
  testWidgets('delete respects editor permission and admin role', (
    tester,
  ) async {
    await openEditor(tester, editable: false);
    expect(find.byTooltip('Delete meter group'), findsNothing);
  });

  testWidgets('delete is hidden for non-admin roles', (tester) async {
    await openEditor(tester, admin: false);
    expect(find.byTooltip('Delete meter group'), findsNothing);
  });

  testWidgets('bill rejection keeps editor open and does not refresh list', (
    tester,
  ) async {
    int refreshed = 0;
    await http.runWithClient(
      () async {
        await openEditor(tester, onUpdate: () => refreshed++);
        await confirmDeletion(tester);
        expect(find.byType(WgtPagItemInfoEditPanel2), findsOneWidget);
        expect(find.textContaining('used in a bill'), findsOneWidget);
        expect(refreshed, 0);
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'message':
                  'm:Cannot delete meter group because it is used in a bill',
            },
          }),
          200,
        ),
      ),
    );
  });

  testWidgets(
    'confirmed deletion sends group identity, refreshes and closes editor',
    (tester) async {
      int refreshed = 0;
      http.Request? sent;
      await http.runWithClient(
        () async {
          await openEditor(tester, onUpdate: () => refreshed++);
          await confirmDeletion(tester);
          expect(refreshed, 1);
          expect(find.byType(WgtPagItemInfoEditPanel2), findsNothing);
          expect(sent!.url.path, '/ems/meter_group/delete_meter_group');
          final payload = jsonDecode(sent!.body) as Map;
          expect(payload.toString(), contains('2674'));
          expect(payload.toString(), contains(groupName));
          expect(
            payload.toString(),
            contains('emsMeterGroup'),
          );
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
                  'delete_result': {'id': '2674', 'name': groupName},
                },
              },
            }),
            200,
          );
        }),
      );
    },
  );

  testWidgets('unconfirmed response does not close editor or report success', (
    tester,
  ) async {
    int refreshed = 0;
    await http.runWithClient(
      () async {
        await openEditor(tester, onUpdate: () => refreshed++);
        await confirmDeletion(tester);
        expect(find.byType(WgtPagItemInfoEditPanel2), findsOneWidget);
        expect(find.textContaining('could not be confirmed'), findsOneWidget);
        expect(refreshed, 0);
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'result_key': 'delete_result',
              'result': {'delete_result': {}},
            },
          }),
          200,
        ),
      ),
    );
  });
}

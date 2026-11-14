import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_meter_group_assignment.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_assignment_op.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

void main() {
  for (final level in [
    'location',
    'location_group',
    'building',
    'site',
    'site_group',
    'project',
    'mismatch',
  ]) {
    testWidgets('expanded $level scope shows its label and can collapse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mismatch = level == 'mismatch';
      final row = {
        'id': '42',
        'name': 'MG 42',
        'label': 'Group',
        'project_id': '1',
        'project_name': 'cw_p2',
        if (level != 'project') ...{
          '${mismatch ? 'mg_scope_location' : level}_id': '7',
          '${mismatch ? 'mg_scope_location' : level}_name': 'Scope name',
          '${mismatch ? 'mg_scope_location' : level}_label': 'Scope label',
        },
      };
      await http.runWithClient(
        () async {
          final provider = PagUserProvider()..setCurrentUser(MdlPagUser());
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: provider,
              child: MaterialApp(
                home: Scaffold(
                  body: WgtTenantMeterGroupAssignment(
                    appConfig: config,
                    appContext: MdlPagAppContext(
                      name: 'ems',
                      label: 'EMS',
                      shortLabel: 'EMS',
                      route: '/ems',
                      appContextType: PagAppContextType.ems,
                    ),
                    strItemGroupIndex: '9',
                    itemName: 'Tenant',
                    itemLabel: '',
                    itemScope: MdlPagScope.fromJson({
                      'project_id': '1',
                      'project_name': 'cw_p2',
                    }),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('MG 42'), findsOneWidget);
          await tester.tap(find.byTooltip('Show/Hide Scope'));
          await tester.pumpAndSettle();
          expect(find.byIcon(Symbols.expand_less), findsOneWidget);
          // Project labels are normally hidden by getScopeLabel.
          expect(
            find.text(level == 'project' ? 'cw_p2' : 'Scope label'),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Show/Hide Scope'));
          await tester.pumpAndSettle();
          expect(find.byIcon(Symbols.expand_less), findsNothing);
          expect(
            find.text(level == 'project' ? 'cw_p2' : 'Scope label'),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'result_key': 'groups',
                'result': {
                  'groups': {
                    'item_group_scope_matching_item_list': mismatch
                        ? []
                        : [row],
                    'scope_mismatch_item_list': mismatch ? [row] : [],
                  },
                },
              },
            }),
            200,
          ),
        ),
      );
    });
  }

  testWidgets('handover bar fills only after new group has an active tenant', (
    tester,
  ) async {
    for (final state in ['unattached', 'current', 'other']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WgtMeterAssignmentOp(
              key: ValueKey(state),
              appConfig: config,
              strMeterGroupId: state == 'other' ? '6' : '5',
              meterInfo: {
                'assignment': [
                  const {
                    'meter_group_id': '4',
                    'percentage': '100',
                    'tenant_info': {'id': '1', 'lc_status': 'terminated'},
                  },
                  {
                    'meter_group_id': '5',
                    'percentage': '100',
                    if (state != 'unattached')
                      'tenant_info': {'id': '2', 'lc_status': 'onb'},
                  },
                ],
              },
              onPercentageChanged: (_, __) {},
            ),
          ),
        ),
      );
      final blue = find.byWidgetPredicate(
        (w) => w is Container && w.color == Colors.blue,
      );
      final grey = find.byWidgetPredicate(
        (w) => w is Container && w.color == Colors.grey.shade700,
      );
      expect(blue, state == 'current' ? findsOneWidget : findsNothing);
      expect(grey, state == 'other' ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}

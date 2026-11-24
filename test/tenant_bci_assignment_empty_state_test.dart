import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_bci_assignment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const emptyMessage = 'No Billing Cost Items are available for this location.';
  const errorMessage = 'Error fetching item group data';

  for (final (name, status, result, showsEmptyState) in [
    (
      'shows the empty state for an empty list',
      200,
      {'item_group_scope_matching_item_list': []},
      true,
    ),
    (
      'shows an error when the result lacks a list',
      200,
      <String, dynamic>{},
      false,
    ),
    ('shows an error when the request fails', 500, <String, dynamic>{}, false),
  ]) {
    testWidgets(name, (tester) async {
      final appConfig = MdlPagAppConfig(
        portalType: PagPortalType.pagConsole,
        lazyLoadScope: '',
        loadDashboard: false,
        userSvcEnv: 'dev',
        oreSvcEnv: 'dev',
        activePortalPagProjectScopeList: [],
      );
      final user = MdlPagUser(id: 1, username: 'tester');
      user.selectedScope.projectProfile = MdlPagProjectProfile(
        id: 1,
        name: 'cw_p2',
        label: 'CW',
        timezone: 8,
        portalProjectScope: PagPortalProjectScope.values.first,
        appContextConfigList: [],
      );

      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: WgtTenantBciAssignment(
                  appConfig: appConfig,
                  loggedInUser: user,
                  strItemGroupIndex: '1143',
                  itemName: 'Tenant',
                  itemLabel: 'Preschool',
                  itemScope: MdlPagScope(
                    projectName: 'cw_p2',
                    projectId: '1',
                    locationId: '1637',
                    locationLabel: '#01-02',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(emptyMessage),
            showsEmptyState ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(errorMessage),
            showsEmptyState ? findsNothing : findsOneWidget,
          );
          expect(
            tester.widget<TextField>(find.byType(TextField)).readOnly,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          expect(
            request.url.path,
            endsWith('/ems/tenant/get_tenant_scope_bci_list'),
          );
          return http.Response(
            jsonEncode({
              'data': {
                'result_key': 'tenant_scope_bci_list',
                'result': {'tenant_scope_bci_list': result},
              },
            }),
            status,
          );
        }),
      );
    });
  }
}

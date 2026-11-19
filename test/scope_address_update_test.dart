import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_item_info_edit_panel2.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_view_edit_field.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('building address saves do not reload the portal', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({'pag_user_token': 'e30.eyJzdWIiOiJ0ZXN0ZXIiLCJleHAiOjQxMDI0NDQ4MDB9.signature'});
    addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));
    final user = MdlPagUser(id: 1, username: 'tester')
        ..loginToken = 'e30.eyJzdWIiOiJ0ZXN0ZXIiLCJleHAiOjQxMDI0NDQ4MDB9.signature'
      ..selectedScope = MdlPagScopeProfile(
        projectProfile: MdlPagProjectProfile(
          id: 1,
          name: 'cw_p2',
          label: 'CW P2',
          portalProjectScope: PagPortalProjectScope.values.first,
          timezone: 8,
          appContextConfigList: [],
        ),
      );
    final appConfig = MdlPagAppConfig(
      portalType: PagPortalType.pagConsole,
      lazyLoadScope: '',
      loadDashboard: false,
      userSvcEnv: 'dev',
      oreSvcEnv: 'dev',
      activePortalPagProjectScopeList: [],
    );
    const fieldTitles = {
      'address_line_1': 'Address Line 1',
      'address_line_2': 'Address Line 2',
      'address_line_3': 'Address Line 3',
      'label': 'Label',
    };
    final savedValues = <String, String>{};
    int updates = 0;
    int portalReloads = 0;

    WgtViewEditField field(String title) => tester
        .widgetList<WgtViewEditField>(find.byType(WgtViewEditField))
        .singleWhere((field) => field.labelText == title);

    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => PagUserProvider()..setCurrentUser(user),
            child: MaterialApp(
              home: Scaffold(
                body: WgtPagItemInfoEditPanel2(
                  appConfig: appConfig,
                  strItemIndex: '42',
                  itemKind: PagItemKind.scope,
                  itemTypeEnum: PagScopeType.building,
                  itemDisplayName: 'Example Building',
                  fieldList: [
                    for (final entry in fieldTitles.entries)
                      {
                        'col_key': entry.key,
                        'label': entry.value,
                        'editable': true,
                      },
                  ],
                  isEditableByAcl: true,
                  onUpdate: () => updates++,
                  onScopeTreeUpdate: () => portalReloads++,
                ),
              ),
            ),
          ),
        );

        for (final title in [
          'Address Line 1',
          'Address Line 2',
          'Address Line 3',
        ]) {
          final value = 'New $title';
          await field(title).onSetValue(value);
          await tester.pump();
          expect(field(title).originalValue, value);
          expect(portalReloads, 0);
        }
        expect(updates, 3);

        await field('Label').onSetValue('Renamed Building');
        expect(updates, 4);
        expect(portalReloads, 1);
        expect(savedValues, {
          'address_line_1': 'New Address Line 1',
          'address_line_2': 'New Address Line 2',
          'address_line_3': 'New Address Line 3',
          'label': 'Renamed Building',
        });
      },
      () => MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/key_val_update/do_op_key_val_update'),
        );
        final query = jsonDecode(request.body)['request'];
        final key = query['update_key_str'] as String;
        savedValues[key] = query['op_list'][0][key] as String;
        return http.Response(
          jsonEncode({
            'data': {
              'result_key': 'result',
              'result': {
                'result': [
                  {'status': 'success'},
                ],
              },
            },
          }),
          200,
        );
      }),
    );
  });
}

import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_item_info_edit_panel2.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'clear is below replace and removes the saved logo only on success',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'pag_user_token': 'e30.eyJzdWIiOiJ0ZXN0ZXIiLCJleHAiOjQxMDI0NDQ4MDB9.signature',
      });
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
      var stored = true;
      var reject = true;
      var writes = 0;
      Future<void> openPanel({bool editable = true}) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => PagUserProvider()..setCurrentUser(user),
            child: MaterialApp(
              home: Scaffold(
                body: WgtPagItemInfoEditPanel2(
                  key: UniqueKey(),
                  appConfig: appConfig,
                  strItemIndex: '2',
                  itemKind: PagItemKind.org,
                  itemTypeEnum: PagOrgType.landlord,
                  itemDisplayName: 'AIMS',
                  fieldList: const [],
                  isEditableByAcl: editable,
                  itemInfoMap: {'has_landlord_logo': stored},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      final clear = find.byTooltip('Clear logo');
      final replace = find.byTooltip(
        'Replace PNG\nUp to 256 KB and 1024 × 1024 pixels',
      );
      await http.runWithClient(
        () async {
          await openPanel(editable: false);
          expect(clear, findsNothing);
          await openPanel();
          expect(tester.getCenter(clear).dx, tester.getCenter(replace).dx);
          expect(
            tester.getTopLeft(clear).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(replace).dy),
          );
          await tester.tap(clear);
          await tester.pumpAndSettle();
          expect(clear, findsOneWidget);
          expect(replace, findsOneWidget);
          reject = false;
          await tester.tap(clear);
          await tester.pumpAndSettle();
          expect(find.text('No logo uploaded'), findsOneWidget);
          expect(clear, findsNothing);
          await openPanel();
          expect(find.text('No logo uploaded'), findsOneWidget);
          expect(clear, findsNothing);
          expect(writes, 2);
        },
        () => MockClient((req) async {
          final query = jsonDecode(req.body)['request'];
          expect(query['item_id_value'], '2');
          expect(query['item_type'], 'landlord');
          expect(query['update_key_str'], 'logo_png_base64');
          expect(query['op_list'][0]['logo_png_base64'], '');
          writes++;
          if (!reject) stored = false;
          return http.Response(
            jsonEncode({
              'data': {
                'result_key': 'result',
                'result': {
                  'result': [
                    if (reject)
                      {
                        'error': {'status': 'Save failed'},
                      }
                    else
                      {'status': 'success'},
                  ],
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

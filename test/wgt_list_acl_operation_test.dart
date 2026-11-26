@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_page_route.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_soa_correction.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_soa2.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_ls_item_flexi.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_edit_commit_list.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:buff_helper/up_helper/enum/enum_acl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MdlPagUser _testUser() => MdlPagUser(id: 1, username: 'tester')
  ..selectedRole = MdlPagRole(id: 2, name: 'ops', label: 'Ops')
  ..selectedScope = MdlPagScopeProfile(
    projectProfile: MdlPagProjectProfile(
      id: 1,
      name: 'test_project',
      label: 'Test Project',
      timezone: 8,
      portalProjectScope: PagPortalProjectScope.values.first,
      appContextConfigList: [],
    ),
  );

MdlPagAppConfig _testConfig() => MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await iniSharedPref();
  });

  testWidgets('list ACL is carried through search, refresh, sort and paging', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const label = 'ems.tenantManager.tenantSoA.landlordOpsView';
    final provider = PagUserProvider()..setCurrentUser(_testUser());
    final controller = MdlPagListController(
      itemTypeEnum: PagFinanceType.tenantSoa,
      listColControllerList: [
        MdlListColController(colKey: 'entry_type', colTitle: 'Type'),
        MdlListColController(colKey: 'entry_timestamp', colTitle: 'Entry Time'),
        MdlListColController(colKey: 'payment_id', colTitle: 'Payment ID'),
        MdlListColController(colKey: 'tenant_name', colTitle: 'Tenant'),
      ],
    );
    final config = _testConfig();
    final requests = <Map<String, dynamic>>[];

    Future<void> mount(Key refreshKey) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: WgtListSearchItemFlexi(
                appConfig: config,
                pagAppContext: appCtxEms,
                itemKind: PagItemKind.finance,
                prefKey: 'test',
                listContextType: PagListContextType.soa,
                listController: controller,
                aclResLabel: label,
                aclListOperation: AclOperation.list,
                soaView: PageSectionView.landlordOpsView,
                initialFilterMap: const {'tenant_name': 'test_tenant'},
                loadOnInit: true,
                refreshCurrentSearchKey: refreshKey,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    WgtPagEditCommitList list() =>
        tester.widget(find.byType(WgtPagEditCommitList));

    await http.runWithClient(
      () async {
        await mount(const ValueKey(0));
        expect(requests, hasLength(1));
        expect(list().selectShowColumn, isFalse);
        expect(
          controller.listColControllerList
              .where((column) => column.showColumn)
              .map((column) => column.colKey),
          ['entry_type'],
        );
        expect(
          requests.first['request']['filter_value_info']['tenant_name'],
          'test_tenant',
        );
        await mount(const ValueKey(1));
        expect(requests, hasLength(2));
        await list().onSort!('entry_type', 'asc');
        await tester.pumpAndSettle();
        expect(requests[2]['request']['sort_by'], 'entry_type');
        await list().onNextPage!();
        await tester.pumpAndSettle();
        expect(requests[3]['request']['current_page'], '2');
        expect(requests, hasLength(4));
        for (final request in requests) {
          expect(request['svcClaimDto']['perm_request_list'], [
            {'res_label': label, 'operation': 'list'},
          ]);
        }
      },
      () => MockClient((request) async {
        if (!request.url.path.endsWith(PagUrlBase.eptGetItemList2)) {
          return http.Response('{}', 404);
        }
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'data': {
              'result_key': 'items',
              'result': {
                'items': {
                  'count': 21,
                  'list_config': [],
                  'item_list': [
                    {'id': '1', 'entry_type': 'bill'},
                  ],
                },
              },
            },
          }),
          200,
        );
      }),
    );
  });

  testWidgets('landlord statement omits all three full-view buttons', (
    tester,
  ) async {
    final user = _testUser();
    final config = _testConfig();
    final provider = PagUserProvider()..setCurrentUser(user);
    final requestedPaths = <String>[];
    final pendingResponse = Completer<http.Response>();

    Future<void> showStatement(PageSectionView? view) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: WgtTenantSoA2(
                key: ValueKey(view),
                appConfig: config,
                loggedInUser: user,
                pagAppContext: appCtxEms,
                tenantInfo: const {
                  'id': 1,
                  'name': 'test_tenant',
                  'label': 'Test Tenant',
                },
                view: view,
              ),
            ),
          ),
        ),
      );
    }

    const actionLabels = [
      'Check SoA Entry',
      'History / balances',
      'Check reversible entry',
    ];
    await http.runWithClient(
      () async {
        await showStatement(PageSectionView.landlordOpsView);
        expect(find.text('Statement of Account'), findsOneWidget);
        for (final label in actionLabels) {
          expect(find.text(label), findsNothing);
        }
        expect(find.byType(WgtSoaCorrection), findsNothing);
        expect(
          requestedPaths.any((path) => path.contains('/soa_correction/')),
          isFalse,
        );

        await showStatement(null);
        for (final label in actionLabels) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.byType(WgtSoaCorrection), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      // The buttons must already be correct while the statement is loading.
      () => MockClient((request) {
        requestedPaths.add(request.url.path);
        return pendingResponse.future;
      }),
    );
  });
}

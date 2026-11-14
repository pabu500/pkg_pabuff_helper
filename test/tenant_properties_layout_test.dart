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
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_lc_status_op.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_item_info_edit_panel2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

const tenantName = 'apl-aims-250108-529';
const handover =
    'Meter e-85202266 was handed over to Avitron 002v2 on '
    '2026-11-14 06:55:29; the tenant can no longer return to normal';

void main() {
  for (final width in [520.0, 360.0]) {
    for (final eligible in [false, true]) {
      testWidgets('tenant properties fit $width pixels with eligibility $eligible', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final user = MdlPagUser(id: 1, username: 'tester')
          ..loginToken = 'test-token'
          ..selectedRole = MdlPagRole(
            id: 2,
            name: 'project-admin',
            label: 'Admin',
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
        final config = MdlPagAppConfig(
          portalType: PagPortalType.pagConsole,
          lazyLoadScope: '',
          loadDashboard: false,
          userSvcEnv: 'dev',
          oreSvcEnv: 'dev',
          activePortalPagProjectScopeList: [],
        );
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              ChangeNotifierProvider.value(
                value: PagUserProvider()..setCurrentUser(user),
                child: MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: WgtPagItemInfoEditPanel2(
                        appConfig: config,
                        strItemIndex: '699',
                        itemKind: PagItemKind.tenant,
                        itemDisplayName: tenantName,
                        itemInfoMap: Map<String, dynamic>.of(const {
                          'id': '699',
                          'name': tenantName,
                          'lc_status': 'offb',
                        }),
                        fieldList: const [
                          {
                            'col_key': 'name',
                            'value': tenantName,
                            'show_edit_panel': false,
                          },
                          {
                            'col_key': 'lc_status',
                            'value': 'offb',
                            'show_edit_panel': false,
                          },
                        ],
                        isEditableByAcl: true,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final lifecycle = find.byType(WgtPagTenantLcStatusOp);
            final titleRect = tester.getRect(find.text(tenantName).first);
            final lifecycleRect = tester.getRect(lifecycle);
            expect(titleRect.bottom, lessThanOrEqualTo(lifecycleRect.top));
            expect(
              tester
                  .getRect(find.byTooltip('Close properties'))
                  .overlaps(titleRect),
              isFalse,
            );
            expect(find.text('Termination unavailable'), findsOneWidget);
            if (!eligible) {
              expect(find.text('Return to Normal unavailable'), findsOneWidget);

              // Blocker panels start collapsed, showing only a reason count.
              expect(find.text('2 reasons'), findsOneWidget);
              expect(find.text('4 reasons'), findsOneWidget);
              expect(find.text(handover), findsNothing);
              expect(find.text('Tenant has 1 pending bill(s)'), findsNothing);

              // Expanding one panel reveals its reasons, wrapped in bounds.
              await tester.tap(find.text('Return to Normal unavailable'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.text('2 reasons'), findsNothing);
              expect(find.text('Tenant has 1 pending bill(s)'), findsNothing);
              final reasonRect = tester.getRect(find.text(handover));
              expect(reasonRect.left, greaterThanOrEqualTo(lifecycleRect.left));
              expect(reasonRect.right, lessThanOrEqualTo(lifecycleRect.right));
              expect(reasonRect.height, greaterThan(30));

              // The other panel expands independently, and collapses again.
              await tester.tap(find.text('Termination unavailable'));
              await tester.pumpAndSettle();
              expect(find.text('Tenant has 1 pending bill(s)'), findsOneWidget);
              expect(find.text('4 reasons'), findsNothing);
              await tester.tap(find.text('Termination unavailable'));
              await tester.pumpAndSettle();
              expect(find.text('Tenant has 1 pending bill(s)'), findsNothing);
              expect(find.text(handover), findsOneWidget);
              expect(tester.takeException(), isNull);
            } else {
              await tester.tap(
                find.descendant(of: lifecycle, matching: find.text('norm')),
              );
              await tester.pumpAndSettle();
              expect(find.text('Commit'), findsOneWidget);
              expect(tester.takeException(), isNull);
            }
          },
          () => MockClient((request) async {
            expect(request.url.path, isNot(contains('update')));
            final isCheck = request.url.path.endsWith(
              'get_tenant_lc_transition_check',
            );
            return http.Response(
              jsonEncode({
                'data': {
                  'result_key': 'test_result',
                  'result': {
                    'test_result': isCheck
                        ? {
                            'targets': {
                              'normal': {
                                'eligible': eligible,
                                'reasons': eligible
                                    ? []
                                    : [
                                        handover,
                                        'Tenant has a final bill; it can no longer return to normal',
                                      ],
                              },
                              'terminated': {
                                'eligible': false,
                                'reasons': [
                                  "Release the tenant's final bill before terminating",
                                  'Tenant has 1 pending bill(s)',
                                  'Bill INI-BILL-A5240002 has an unpaid balance of 50.00',
                                  'Bill 8TA20-2026-04-00010 has an unpaid balance of 44046.67',
                                ],
                              },
                            },
                          }
                        : [],
                  },
                },
              }),
              200,
            );
          }),
        );
      });
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_ems_meter_group_assignment.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

const loadError = 'Unable to load meter assignments. Please try again.';

http.Response success(String key, dynamic value) => http.Response(
  jsonEncode({
    'success': true,
    'data': {
      'result_key': key,
      'result': {key: value},
    },
  }),
  200,
);

http.Response failure() => http.Response(
  jsonEncode({
    'success': false,
    'error': {
      'code': 'RESULT_GENERIC_ERROR',
      'message':
          'm:OQG R2x Error: Failed to extract table name from SQL statement',
    },
  }),
  200,
);

Future<void> openAssignments(WidgetTester tester, {int meterCount = 1}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final provider = PagUserProvider()..setCurrentUser(MdlPagUser());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: WgtEmsMeterGroupAssignment(
            appContext: MdlPagAppContext(
              name: 'ems',
              label: 'EMS',
              shortLabel: 'EMS',
              route: '/ems',
              appContextType: PagAppContextType.ems,
            ),
            appConfig: MdlPagAppConfig(
              portalType: PagPortalType.pagConsole,
              lazyLoadScope: '',
              loadDashboard: false,
              userSvcEnv: 'dev',
              oreSvcEnv: 'dev',
              activePortalPagProjectScopeList: [],
            ),
            strItemGroupIndex: '742',
            itemName: 'MG',
            itemLabel: '',
            meterType: 'E',
            itemScope: MdlPagScope.fromJson({
              'project_name': 'cw_p2',
              'project_id': '1',
            }),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

http.Response scopeMeters(int count) => success('scope_meters', {
  'item_group_scope_matching_item_list': [
    for (int i = 0; i < count; i++)
      {
        'item_id': '${620 + i}',
        'item_name': 'Meter $i',
        'meter_sn': 'SN$i',
        'meter_type': 'E',
        'project_name': 'cw_p2',
        'project_id': '1',
      },
  ],
  'scope_mismatch_item_list': [],
});

void main() {
  testWidgets('single failure is visible and retry shows the assignment', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var attempts = 0;
    await http.runWithClient(
      () async {
        await openAssignments(tester);
        await tester.tap(find.text('Check Assignment'));
        await tester.pump();
        final loading = tester.widget<WgtCommButton>(
          find.byWidgetPredicate(
            (w) => w is WgtCommButton && w.label == 'Check Assignment',
          ),
        );
        expect(loading.enabled, isFalse);
        expect(loading.inComm, isTrue);
        pending.complete(failure());
        await tester.pumpAndSettle();
        expect(find.text(loadError), findsOneWidget);
        expect(find.text('Retry Assignment'), findsOneWidget);
        expect(find.textContaining('OQG'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Retry Assignment'));
        await tester.pumpAndSettle();
        expect(attempts, 2);
        expect(find.text(loadError), findsNothing);
        expect(find.text('mg-e-57209384'), findsOneWidget);
        expect(find.text('Donald Mcarthy Trading Pte. Ltd.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        if (!request.url.path.endsWith('get_meter_tenant_assignment')) {
          return scopeMeters(1);
        }
        attempts++;
        return attempts == 1
            ? pending.future
            : success('meter_tenant_assignment', [
                {
                  'meter_group_id': '742',
                  'meter_group_name': 'mg-e-57209384',
                  'percentage': '100.00',
                  'tenant_info': {
                    'id': '701',
                    'name': 'Donald Mcarthy Trading Pte. Ltd.',
                    'lc_status': 'mfd',
                    'final_released': 'true',
                    'named': 'false',
                  },
                },
              ]);
      }),
    );
  });

  testWidgets('check all shows row errors and retries only failed meters', (
    tester,
  ) async {
    final attempts = <String, int>{};
    await http.runWithClient(
      () async {
        await openAssignments(tester, meterCount: 2);
        await tester.tap(find.text('Check All Assignments'));
        await tester.pumpAndSettle();
        expect(find.text(loadError), findsOneWidget);
        expect(find.text('Retry Assignment'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Check All Assignments'));
        await tester.pumpAndSettle();
        expect(attempts, {'620': 2, '621': 1});
        expect(find.text(loadError), findsNothing);
        expect(
          find.text('This meter has not been assigned to any meter group'),
          findsNWidgets(2),
        );
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        if (!request.url.path.endsWith('get_meter_tenant_assignment')) {
          return scopeMeters(2);
        }
        final id = jsonDecode(request.body)['request']['meter_id'] as String;
        attempts[id] = (attempts[id] ?? 0) + 1;
        return id == '620' && attempts[id] == 1
            ? failure()
            : success('meter_tenant_assignment', []);
      }),
    );
  });

  testWidgets(
    'leaving while an assignment request fails causes no state error',
    (tester) async {
      final pending = Completer<http.Response>();
      await http.runWithClient(
        () async {
          await openAssignments(tester);
          await tester.tap(find.text('Check Assignment'));
          await tester.pump();
          await tester.pumpWidget(const SizedBox());
          pending.complete(failure());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          return request.url.path.endsWith('get_meter_tenant_assignment')
              ? pending.future
              : scopeMeters(1);
        }),
      );
    },
  );
}

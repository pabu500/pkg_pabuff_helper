import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_assignment_op.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_allocation_warning.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_meter_group_assignment.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'wgt_meter_allocation_test.dart' as fixtures;
import 'wgt_meter_assignment_fetch_test.dart' show success;

Future<void> dialog(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final user = MdlPagUser(username: 'tester')..loginToken = 'e30.eyJzdWIiOiJ0ZXN0ZXIiLCJleHAiOjQxMDI0NDQ4MDB9.signature';
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: PagUserProvider()..setCurrentUser(user),
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: WgtTenantMeterGroupAssignment(
            appConfig: fixtures.config,
            appContext: MdlPagAppContext(
              name: 'ems',
              label: 'EMS',
              shortLabel: 'EMS',
              route: '/ems',
              appContextType: PagAppContextType.ems,
            ),
            strItemGroupIndex: '1300',
            itemName: 'Receiving tenant',
            itemLabel: 'Test',
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

http.Response scope() => success('scope_groups', {
  'item_group_scope_matching_item_list': [
    {
      'id': '447',
      'name': 'mg-e-35700730',
      'label': 'No tenant group',
      'project_name': 'cw_p2',
      'project_id': '1',
    },
  ],
  'scope_mismatch_item_list': [],
});
http.Response meters() => http.Response(
  jsonEncode({
    'data': {
      'item_group_item_list': [
        for (final id in ['620', '621'])
          {
            'meter_id': id,
            'name': 'Meter $id',
            'meter_sn': 'SN$id',
            'percentage': '100',
          },
      ],
    },
  }),
  200,
);
http.Response allocations([String status = 'onb', String amount = '100']) =>
    success('meter_tenant_assignment', [
      {'meter_group_id': '447', 'percentage': '100'},
      {
        'meter_group_id': '1012',
        'percentage': amount,
        'tenant_info': {'id': '1293', 'lc_status': status},
      },
    ]);
const refusal =
    'Meter Meter 620 (SN620) is already 100% allocated to active tenants (other group → Donald V2). Assigning mg-e-35700730 would make it 200%.\nMeter Meter 621 (SN621) is already 100% allocated to active tenants (other group → Donald V2). Assigning mg-e-35700730 would make it 200%.';

void main() {
  testWidgets('server-authorized handover clears the advisory after saving', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await dialog(tester, Brightness.light);
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(find.byType(WgtMeterAllocationWarning), findsOneWidget);
        await tester.tap(find.byIcon(Icons.cloud_upload));
        await tester.pumpAndSettle();
        expect(find.text('✓ Committed'), findsOneWidget);
        expect(find.byType(WgtMeterAllocationWarning), findsNothing);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('get_tenant_scope_meter_group_list')) {
          return scope();
        }
        if (request.url.path.endsWith('get_meter_group_meter_list')) {
          return meters();
        }
        if (request.url.path.endsWith('get_meter_tenant_assignment')) {
          return allocations('offb');
        }
        return http.Response(
          jsonEncode({
            'data': {'success': true},
          }),
          200,
        );
      }),
    );
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'tenantless warning remains editable and clears at zero in $brightness',
      (tester) async {
        var changed = -1.0;
        var error = 'unset';
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: Center(
                child: WgtMeterAssignmentOp(
                  appConfig: fixtures.config,
                  strMeterGroupId: '447',
                  currentTenantInfo: const {},
                  meterInfo: const {
                    'assignment': [
                      {'meter_group_id': '447', 'percentage': '100'},
                      {
                        'meter_group_id': '1012',
                        'percentage': '100',
                        'tenant_info': {'lc_status': 'onb'},
                      },
                    ],
                  },
                  onPercentageChanged: (value, message) {
                    changed = value;
                    error = message;
                  },
                ),
              ),
            ),
          ),
        );
        expect(find.byType(WgtMeterAllocationWarning), findsOneWidget);
        expect(
          tester.widget<WgtTextField>(find.byType(WgtTextField)).enabled,
          isTrue,
        );
        await tester.enterText(find.byType(TextField), '50');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(changed, 50);
        expect(error, isEmpty);
        expect(find.byType(WgtMeterAllocationWarning), findsOneWidget);
        await tester.enterText(find.byType(TextField), '0');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.byType(WgtMeterAllocationWarning), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'selected group lists all conflicts and full refusal in $brightness',
      (tester) async {
        await http.runWithClient(
          () async {
            await dialog(tester, brightness);
            await tester.tap(find.byType(Checkbox));
            await tester.pumpAndSettle();
            expect(find.textContaining('SN620: 200'), findsNothing);
            expect(
              find.textContaining('Meter 620 (SN620): 200.00%'),
              findsOneWidget,
            );
            expect(
              find.textContaining('Meter 621 (SN621): 200.00%'),
              findsOneWidget,
            );
            await tester.tap(find.byIcon(Icons.cloud_upload));
            await tester.pumpAndSettle();
            expect(
              find.text(refusal),
              findsOneWidget,
              reason: tester
                  .widgetList<SelectableText>(find.byType(SelectableText))
                  .map((w) => w.data)
                  .join('\n'),
            );
            expect(find.text('✓ Committed'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byType(Checkbox));
            await tester.pumpAndSettle();
            expect(find.byType(WgtMeterAllocationWarning), findsNothing);
          },
          () => MockClient((request) async {
            if (request.url.path.endsWith(
              'get_tenant_scope_meter_group_list',
            )) {
              return scope();
            }
            if (request.url.path.endsWith('get_meter_group_meter_list')) {
              return meters();
            }
            if (request.url.path.endsWith('get_meter_tenant_assignment')) {
              return allocations();
            }
            if (request.url.path.endsWith('update_tenant_meter_group_list')) {
              return http.Response(
                jsonEncode({
                  'error': {'message': 'm:$refusal'},
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            throw StateError('Unexpected ${request.url.path}');
          }),
        );
      },
    );
  }
  testWidgets(
    'untick ignores a late response and fetching failure can be retried',
    (tester) async {
      final pending = Completer<http.Response>();
      var attempts = 0;
      await http.runWithClient(
        () async {
          await dialog(tester, Brightness.light);
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          pending.complete(meters());
          await tester.pumpAndSettle();
          expect(find.byType(WgtMeterAllocationWarning), findsNothing);
          await tester.tap(find.byType(Checkbox));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Unable to check meter allocations'),
            findsOneWidget,
          );
          await tester.tap(find.byType(Checkbox));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(Checkbox));
          await tester.pumpAndSettle();
          expect(find.byType(WgtMeterAllocationWarning), findsNothing);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('get_tenant_scope_meter_group_list')) {
            return scope();
          }
          if (request.url.path.endsWith('get_meter_group_meter_list')) {
            attempts++;
            if (attempts == 1) return pending.future;
            if (attempts == 2) throw Exception('offline');
            return meters();
          }
          return allocations('terminated');
        }),
      );
    },
  );
}

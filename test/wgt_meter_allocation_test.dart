import 'package:buff_helper/pag_helper/def_helper/dh_ems_meter_allocation.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_assignment_op.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_group_assignment_item.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);
Map<String, dynamic> tenant(String status) => {
  'id': '9',
  'name': 'Tenant',
  'lc_status': status,
};
Map<String, dynamic> allocation(
  String id,
  double percentage, [
  String? status,
]) => {
  'meter_group_id': id,
  'meter_group_name': 'MG $id',
  'percentage': percentage.toString(),
  if (status != null) 'tenant_info': tenant(status),
};
Future<void> showEditor(
  WidgetTester tester,
  List<Map<String, dynamic>> rows, {
  String? currentStatus,
  bool readOnly = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: WgtMeterAssignmentOp(
            appConfig: config,
            strMeterGroupId: '5',
            meterInfo: {'assignment': rows},
            currentTenantInfo: currentStatus == null
                ? <String, dynamic>{}
                : tenant(currentStatus),
            readOnly: readOnly,
            onPercentageChanged: (_, __) {},
          ),
        ),
      ),
    ),
  );
}

bool editable(WidgetTester tester) =>
    tester.widget<WgtTextField>(find.byType(WgtTextField)).enabled;

void main() {
  test('only existing active tenants consume capacity', () {
    for (final status in ['onb', 'normal', 'offb', '']) {
      expect(meterAllocationHasActiveTenant(tenant(status)), isTrue);
    }
    for (final status in ['terminated', 'mfd', 'MFD', ' Terminated ']) {
      expect(meterAllocationHasActiveTenant(tenant(status)), isFalse);
    }
    expect(meterAllocationHasActiveTenant(null), isFalse);
    expect(meterAllocationHasActiveTenant({}), isFalse);
  });

  test('offboarding capacity follows handover and final-release flags', () {
    for (final flag in ['named', 'final_released']) {
      for (final value in [true, 'true', 'TRUE', 't']) {
        expect(
          meterAllocationHasActiveTenant({...tenant('offb'), flag: value}),
          isFalse,
        );
        // Flags never release capacity while the tenant is active again.
        expect(
          meterAllocationHasActiveTenant({...tenant('normal'), flag: value}),
          isTrue,
        );
      }
      for (final value in [false, 'false', 'f', null]) {
        expect(
          meterAllocationHasActiveTenant({...tenant('offb'), flag: value}),
          isTrue,
        );
      }
    }
    expect(
      meterAllocationHasActiveTenant({
        ...tenant('offb'),
        'last_reading_timestamp': '2026-11-14',
        'last_reading_value': '100',
      }),
      isTrue,
    );
  });

  test('preview keeps handover flags only for the same tenant', () {
    final historical = {...tenant('offb'), 'named': true};
    expect(
      meterAllocationHasActiveTenant(
        meterAllocationTenantInfo(historical, tenant('offb')),
      ),
      isFalse,
    );
    final replacement = meterAllocationTenantInfo(historical, {
      ...tenant('offb'),
      'id': '10',
    });
    expect(replacement!.containsKey('named'), isFalse);
    expect(meterAllocationHasActiveTenant(replacement), isTrue);
    expect(meterAllocationTenantInfo(historical, {}), isEmpty);
  });

  for (final flag in ['named', 'final_released']) {
    testWidgets(
      'historical offboarding $flag does not trigger over-allocation',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final rows = [
          {
            ...allocation('8', 100, 'offb'),
            'tenant_info': {...tenant('offb'), flag: 't'},
          },
          allocation('5', 100, 'onb'),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: WgtMeterGroupAssignmentItem(
                  appConfig: config,
                  loggedInUser: MdlPagUser(),
                  strItemGroupIndex: '5',
                  currentTenantInfo: tenant('onb'),
                  itemInfo: {
                    'project_name': 'cw_p2',
                    'project_id': '1',
                    'item_id': '618',
                    'item_name': 'e-85202266',
                    'meter_sn': '1042310300527',
                    'assignment': rows,
                    'info_fetched': true,
                  },
                  getMeterAssignment: (_) async {},
                ),
              ),
            ),
          ),
        );
        expect(find.textContaining('exceeds 100%'), findsNothing);
        expect(find.text('MG 8'), findsOneWidget);
        expect(
          find.byTooltip(
            'Total percentage assigned to active tenants exceeds 100%',
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        // Viewing the old group's read-only bar must also retain its flags.
        await showEditor(
          tester,
          [
            {...rows.first, 'meter_group_id': '5'},
            allocation('8', 100, 'onb'),
          ],
          currentStatus: 'offb',
          readOnly: true,
        );
        expect(
          find.byTooltip(
            'Total percentage assigned to active tenants exceeds 100%',
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unassigned 100% group does not block a new active allocation', (
    tester,
  ) async {
    await showEditor(tester, [allocation('8', 100)], currentStatus: 'normal');
    expect(editable(tester), isTrue);
  });

  for (final status in ['onb', 'normal', 'offb']) {
    testWidgets('$status consumes 100% and blocks another active allocation', (
      tester,
    ) async {
      await showEditor(tester, [
        allocation('8', 100, status),
      ], currentStatus: 'onb');
      expect(editable(tester), isFalse);
    });
  }

  for (final status in ['terminated', 'mfd']) {
    testWidgets('$status allocation becomes available again', (tester) async {
      await showEditor(tester, [
        allocation('8', 100, status),
      ], currentStatus: 'onb');
      expect(editable(tester), isTrue);
    });
  }

  testWidgets('inactive group remains editable when active tenants use 100%', (
    tester,
  ) async {
    await showEditor(tester, [
      allocation('8', 100, 'normal'),
      allocation('5', 100),
    ]);
    expect(editable(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'existing active percentage can be reduced regardless of row order',
    (tester) async {
      await showEditor(tester, [
        allocation('5', 60, 'normal'),
        allocation('8', 40, 'normal'),
      ], currentStatus: 'normal');
      expect(editable(tester), isTrue);
    },
  );

  testWidgets('immutable assignment remains read-only', (tester) async {
    await showEditor(tester, [allocation('8', 100)], readOnly: true);
    expect(editable(tester), isFalse);
  });

  testWidgets('new group preview and reset leave fetched allocations unchanged', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = [allocation('8', 100)];
    final info = <String, dynamic>{
      'project_name': 'cw_p2',
      'project_id': '1',
      'item_id': '7',
      'item_name': 'Meter',
      'meter_sn': '1042310300077',
      'assignment': original,
      'info_fetched': true,
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WgtMeterGroupAssignmentItem(
              appConfig: config,
              loggedInUser: MdlPagUser(),
              itemInfo: info,
              strItemGroupIndex: '5',
              currentTenantInfo: tenant('normal'),
              getMeterAssignment: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '100');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      info['updated_meter_assignment_to_this_meter_group']['percentage'],
      '100.0',
    );
    expect(
      info['updated_meter_assignment_to_this_meter_group']['tenant_info']['lc_status'],
      'normal',
    );
    expect(original, [allocation('8', 100)]);
    expect(info['assignment_error_message'], isEmpty);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '0.000',
    );
    expect(
      info.containsKey('updated_meter_assignment_to_this_meter_group'),
      isFalse,
    );
    expect(original, [allocation('8', 100)]);
  });
}

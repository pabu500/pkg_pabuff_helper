import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_group_assignment_item.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

Map<String, dynamic> allocation(String id, {Map<String, dynamic>? tenant}) => {
  'meter_group_id': id,
  'meter_group_name': id == '447' ? 'mg-e-35700730' : 'mg-e-57209384',
  'percentage': '100.00',
  if (tenant != null) 'tenant_info': tenant,
};

Future<void> showAssignments(
  WidgetTester tester,
  ThemeData theme,
  List<Map<String, dynamic>> rows, {
  Map<String, dynamic>? pending,
  String error = '',
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: WgtMeterGroupAssignmentItem(
            appConfig: config,
            loggedInUser: MdlPagUser(),
            strItemGroupIndex: '447',
            itemInfo: {
              'project_name': 'cw_p2',
              'project_id': '1',
              'item_id': '620',
              'item_name': 'e-76969172',
              'meter_sn': '2310600554',
              'assignment': rows,
              'info_fetched': true,
              if (pending != null)
                'updated_meter_assignment_to_this_meter_group': pending,
              'assignment_error_message': error,
            },
            getMeterAssignment: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const countingRule =
    'Only allocations to active tenants count toward the 100% limit.';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('excluded allocations and pending zero in $brightness', (
      tester,
    ) async {
      final theme = ThemeData(brightness: brightness);
      await showAssignments(tester, theme, [
        allocation('447'),
        allocation(
          '742',
          tenant: {
            'id': '701',
            'name': 'dmtpl-aims-250108-665',
            'label': 'Donald Mcarthy Trading Pte. Ltd.',
            'lc_status': 'terminated',
          },
        ),
      ]);

      expect(find.text('No active-tenant allocation'), findsOneWidget);
      expect(
        find.byTooltip('Active tenants: 0.00% of 100%\n$countingRule'),
        findsOneWidget,
      );
      expect(find.text('No tenant'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('No tenant')).style!.color,
        theme.hintColor,
      );
      for (final reason in ['no tenant', 'tenant Terminated']) {
        final percentage = find.descendant(
          of: find.byTooltip('Not counted: $reason'),
          matching: find.text('100.00%'),
        );
        expect(percentage, findsOneWidget);
        expect(
          tester.widget<Text>(percentage).style!.color,
          theme.hintColor.withAlpha(120),
        );
      }
      expect(
        find.text('Only allocations to active tenants count toward 100%'),
        findsOneWidget,
      );
      await tester.longPress(find.byTooltip('Not counted: no tenant'));
      await tester.pumpAndSettle();
      expect(find.text('Not counted: no tenant'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      await tester.enterText(find.byType(TextField), '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('0.00%')).style!.color,
        commitColor.withAlpha(210),
      );
      expect(find.text('100.00%'), findsOneWidget);
      expect(find.text('No active-tenant allocation'), findsOneWidget);
      expect(find.byTooltip('Not counted: no tenant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bar total excludes MFD and released offboarding allocations', (
    tester,
  ) async {
    await showAssignments(tester, ThemeData(), [
      {
        ...allocation('447', tenant: {'name': 'Active', 'lc_status': 'normal'}),
        'percentage': '40',
      },
      allocation('742', tenant: {'name': 'MFD tenant', 'lc_status': 'mfd'}),
      for (final flag in ['named', 'final_released'])
        allocation(
          flag,
          tenant: {'name': 'Offboarding $flag', 'lc_status': 'offb', flag: 't'},
        ),
    ]);
    expect(find.text('No active-tenant allocation'), findsNothing);
    expect(
      find.byTooltip('Active tenants: 40.00% of 100%\n$countingRule'),
      findsOneWidget,
    );
    expect(find.byTooltip('Not counted: tenant MFD'), findsOneWidget);
    expect(
      find.byTooltip('Not counted: tenant Offboarding (allocation released)'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'zero active allocation shows label without an exclusion footnote',
    (tester) async {
      await showAssignments(tester, ThemeData(), [
        {
          ...allocation(
            '447',
            tenant: {'name': 'Active', 'lc_status': 'normal'},
          ),
          'percentage': '0',
        },
      ]);
      expect(find.text('No active-tenant allocation'), findsOneWidget);
      expect(find.byTooltip('Not counted: tenant Normal'), findsNothing);
      expect(
        find.text('Only allocations to active tenants count toward 100%'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending error colour takes priority over excluded-row muting', (
    tester,
  ) async {
    final theme = ThemeData();
    await showAssignments(
      tester,
      theme,
      [allocation('447')],
      pending: {...allocation('447'), 'percentage': '0'},
      error: 'Assignment error',
    );
    expect(
      tester.widget<Text>(find.text('0.00%')).style!.color,
      theme.colorScheme.error,
    );
    expect(find.byTooltip('Not counted: no tenant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

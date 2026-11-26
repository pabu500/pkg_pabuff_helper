import 'dart:convert';
import 'dart:io';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_bci_tenant_assignment.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tariff_package_assignment.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Ahem's wide glyphs overflow the date pickers beside the BCI numbers.
    final sdk = Platform.environment['FLUTTER_ROOT'];
    final roboto = File(
      '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    await (FontLoader(
      'AssignmentTestRoboto',
    )..addFont(roboto.readAsBytes().then(ByteData.sublistView))).load();
  });

  for (final isBci in [true, false]) {
    final scenario = isBci
        ? 'BCI shows row numbers and tariff tags, filters and orders tenants'
        : 'TP shows full row numbers on one line';
    testWidgets(scenario, (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(
        isBci ? const Size(1024, 900) : const Size(1400, 900),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      final scope = MdlPagScope(projectName: 'cw_p2', projectId: '1');
      final dialog = isBci
          ? WgtBciTenantAssignment(
              appConfig: appConfig,
              loggedInUser: user,
              itemGroupIndexStr: '1',
              itemName: 'bci',
              itemLabel: 'Fee',
              itemScope: scope,
              itemInfo: const {},
            )
          : WgtTariffPackageAssignment(
              appConfig: appConfig,
              loggedInUser: user,
              itemGroupIndexStr: '1',
              itemName: 'tp',
              itemLabel: 'Tariff',
              itemScope: scope,
              meterType: 'E',
              itemInfo: const {},
            );

      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'AssignmentTestRoboto'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.1)),
              child: child!,
            ),
            home: Scaffold(body: dialog),
          ),
        );
        await tester.pumpAndSettle();

        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scroll.position.jumpTo(95 * 35.0);
        await tester.pumpAndSettle();
        for (final label in ['99', '100', '101']) {
          expectFullNumber(tester, label);
        }

        if (isBci) {
          final tenant = find.text('tenant-0100');
          final row = find.ancestor(of: tenant, matching: find.byType(Row)).first;
          final checkbox = find.descendant(
            of: row,
            matching: find.byType(Checkbox),
          );
          final offset = scroll.position.pixels;
          final rowPosition = tester.getTopLeft(tenant);
          expect(tester.widget<Checkbox>(checkbox).value, isFalse);
          for (final checked in [true, false]) {
            await tester.tap(checkbox);
            await tester.pumpAndSettle();
            expect(scroll.mounted, isTrue);
            expect(scroll.position.pixels, offset);
            expect(tester.getTopLeft(tenant), rowPosition);
            expect(tester.widget<Checkbox>(checkbox).value, checked);
          }
        }

        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        for (final label in ['999', '1000', '1001']) {
          expectFullNumber(tester, label);
        }

        await tester.enterText(find.byType(TextField).first, 'tenant-1001');
        await tester.pumpAndSettle();
        expectFullNumber(tester, isBci ? '1001' : '1');
        if (isBci) {
          await verifyBciAccountSearchAndOrdering(tester);
        }
        expect(tester.takeException(), isNull);
      }, () => MockClient((_) async => assignmentResponse(isBci)));
    });
  }
}

Future<void> verifyBciAccountSearchAndOrdering(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, '');
  await tester.pumpAndSettle();

  final firstTenant = find.text('tenant-0001');
  final accountTenant = find.text('tenant-0002');
  final assignedTenant = find.text('tenant-0003');
  final account = find.text('ABC-0002');
  final electricityTariffTag = find.text('E: FTF');
  final combinedTariffTag = find.text('E: SP LT Cycle, W: SP');
  expect(account, findsOneWidget);
  expect(electricityTariffTag, findsOneWidget);
  expect(combinedTariffTag, findsOneWidget);
  expect(find.text('W: SP'), findsOneWidget);
  expect(
    tester.getSize(find.byTooltip('E: SP LT Cycle, W: SP')).width,
    160,
  );
  expect(
    tester.renderObject<RenderParagraph>(combinedTariffTag).didExceedMaxLines,
    isFalse,
  );
  final assignedTenantRow = find
      .ancestor(of: assignedTenant, matching: find.byType(Row))
      .first;
  final assignedCheckbox = find.descendant(
    of: assignedTenantRow,
    matching: find.byType(Checkbox),
  );
  expect(
    tester.getTopRight(combinedTariffTag).dx,
    lessThan(tester.getTopLeft(assignedCheckbox).dx),
  );
  expect(
    tester.getTopLeft(assignedTenant).dy,
    lessThan(tester.getTopLeft(firstTenant).dy),
  );

  final accountTenantRow = find
      .ancestor(of: accountTenant, matching: find.byType(Row))
      .first;
  final effectiveFromDate = find.descendant(
    of: accountTenantRow,
    matching: find.text('Eff. From Date'),
  );
  expect(
    tester.getTopRight(account).dx,
    lessThan(tester.getTopLeft(electricityTariffTag).dx),
  );
  expect(
    tester.getTopRight(electricityTariffTag).dx,
    lessThan(tester.getTopLeft(effectiveFromDate).dx),
  );
  final checkbox = find.descendant(
    of: accountTenantRow,
    matching: find.byType(Checkbox),
  );
  final accountTenantPosition = tester.getTopLeft(accountTenant);
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
  expect(tester.getTopLeft(accountTenant), accountTenantPosition);

  final accountFilter = find.widgetWithText(TextField, 'Tenant Account No.');
  await tester.enterText(accountFilter, '  bc-0002 ');
  await tester.pumpAndSettle();
  expect(account, findsOneWidget);
  expect(firstTenant, findsNothing);
  expect(assignedTenant, findsNothing);
  expect(tester.widget<Checkbox>(checkbox).value, isTrue);

  final tariffTypeFilter = find.widgetWithText(TextField, 'TPT');
  await tester.enterText(tariffTypeFilter, '  w: sP  ');
  await tester.pumpAndSettle();
  expect(accountTenant, findsNothing);
  expect(assignedTenant, findsNothing);

  await tester.enterText(accountFilter, '');
  await tester.pumpAndSettle();
  expect(assignedTenant, findsOneWidget);
  expect(find.text('W: SP'), findsOneWidget);
  expect(firstTenant, findsNothing);
  expect(accountTenant, findsNothing);

  await tester.enterText(tariffTypeFilter, 'ftf');
  await tester.pumpAndSettle();
  expect(accountTenant, findsOneWidget);
  expect(assignedTenant, findsNothing);
  expect(find.text('W: SP'), findsNothing);

  await tester.enterText(tariffTypeFilter, '');
  await tester.pumpAndSettle();
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
  expect(
    tester.getTopLeft(assignedTenant).dy,
    lessThan(tester.getTopLeft(firstTenant).dy),
  );
  expect(
    tester.getTopLeft(firstTenant).dy,
    lessThan(tester.getTopLeft(accountTenant).dy),
  );
}

void expectFullNumber(WidgetTester tester, String label) {
  final number = find.text(label);
  expect(number, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(number);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: label.length),
  );
  expect(boxes, hasLength(1), reason: 'Row $label must fit on one line');
  final column = find
      .ancestor(of: number, matching: find.byType(SizedBox))
      .first;
  expect(
    tester.getTopLeft(number).dx + boxes.single.right,
    lessThanOrEqualTo(tester.getTopRight(column).dx + 0.5),
  );
}

http.Response assignmentResponse(bool isBci) {
  final tenants = [
    for (var i = 1; i <= 1001; i++)
      {
        (isBci ? 'tenant_name' : 'name'):
            'tenant-${i.toString().padLeft(4, '0')}',
        (isBci ? 'tenant_label' : 'label'):
            'Tenant ${i.toString().padLeft(4, '0')}',
        if (isBci && i == 2) 'account_number': 'ABC-0002',
        if (isBci && i == 3) 'is_assigned_to_this_bci': 'true',
        if (isBci && i == 2) 'tpt_label_e': 'FTF',
        if (isBci && i == 3) 'tpt_label_e': 'SP LT Cycle',
        if (isBci && (i == 3 || i == 4)) 'tpt_label_w': 'SP',
        if (!isBci) 'tpt_label_e': 'Tariff type',
      },
  ];
  return http.Response(
    jsonEncode({
      'data': isBci
          ? {
              'result_key': 'bci_assignment',
              'result': {
                'bci_assignment': {'bci_scope_matching_tenant_list': tenants},
              },
            }
          : {
              'tariff_package_assignment': {
                'tariff_package_scope_matching_tenant_list': tenants,
              },
            },
    }),
    200,
  );
}

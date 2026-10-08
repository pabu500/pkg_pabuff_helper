import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_soa_correction.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_edit_commit_list.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final rows = <Map<String, dynamic>>[
  {'id': 200, 'entry_type': 'bill', 'entry_timestamp': '2026-05-27'},
  {
    'id': 199,
    'entry_type': 'pya',
    'entry_timestamp': '2026-05-26',
    'payment_id': 45,
    'payment_apply_id': 67,
    'change_interest': -4.47,
  },
];
const operation = {'op_type': 'remove_payment_apply', 'target_soa_id': 199};
Map<String, dynamic> rootPreview() => {
  'top_soa_id': 200,
  'max_soa_id': 200,
  'allowed': false,
  'actions': [operation],
  'reasons': ['Remove the application first.'],
};
Map<String, dynamic> targetPreview() => {
  ...rootPreview(),
  'allowed': true,
  'op_type': 'remove_payment_apply',
  'target': rows[1],
  'reasons': <String>[],
  'source': {'id': 67, 'principal': 247.28, 'interest': 4.47},
};
Map<String, dynamic> listResult({
  int page = 1,
  String order = 'desc',
  List<Map<String, dynamic>>? items,
}) => {
  'item_list': items ?? rows,
  'current_page': page,
  'query_map': {
    'sort_by': 'entry_timestamp',
    'sort_order': order,
    'current_page': page,
  },
};

class Host extends StatefulWidget {
  const Host({super.key, required this.request});
  final Future<dynamic> Function(String, Map<String, dynamic>) request;
  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
  final correction = GlobalKey<WgtSoaCorrectionState>();
  Map<String, Map<String, dynamic>> actions = {};
  int changes = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        WgtSoaCorrection(
          key: correction,
          appConfig: MdlPagAppConfig(
            portalType: PagPortalType.pagConsole,
            lazyLoadScope: '',
            loadDashboard: false,
            userSvcEnv: 'dev',
            oreSvcEnv: 'dev',
            activePortalPagProjectScopeList: [],
          ),
          user: MdlPagUser(id: 1, username: 'tester'),
          tenantId: '1154',
          request: widget.request,
          onChanged: () => changes++,
          onActionsChanged: (value) => setState(() => actions = value),
        ),
        WgtPagEditCommitList(
          itemKind: PagItemKind.finance,
          listPrefix: 'tenant_soa',
          listController: MdlPagListController(
            itemTypeEnum: PagFinanceType.tenantSoa,
            listColControllerList: [
              MdlListColController(
                colKey: 'entry_type',
                colTitle: 'Type',
                colWidth: 140,
                isMutable: false,
              ),
            ],
          ),
          listItems: rows,
          showCommit: false,
          rowLeadingBuilder: (row) => actions[row['id'].toString()] == null
              ? const SizedBox.shrink()
              : IconButton(
                  key: ValueKey('reverse-${row['id']}'),
                  icon: const Icon(Icons.undo),
                  onPressed: () => correction.currentState!.openEntry(
                    actions[row['id'].toString()]!,
                    row,
                  ),
                ),
        ),
      ],
    ),
  );
}

Future<HostState> mount(
  WidgetTester tester,
  Future<dynamic> Function(String, Map<String, dynamic>) request, {
  Size size = const Size(1100, 900),
  ThemeData? theme,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<HostState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      // Scale the modal route while keeping unrelated list controls unchanged.
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: Host(key: key, request: request),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

Future<dynamic> normalRequest(String action, Map<String, dynamic> body) async =>
    action == 'history'
    ? []
    : body['target_soa_id'] != null
    ? targetPreview()
    : rootPreview();
bool checkEnabled(WidgetTester tester) => tester
    .widget<WgtCommButton>(
      find.widgetWithText(WgtCommButton, 'Check reversible entry'),
    )
    .enabled;
Future<void> check(WidgetTester tester, HostState host) async {
  await host.correction.currentState!.updateList(listResult());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check reversible entry'));
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, HostState host) async {
  await check(tester, host);
  await tester.tap(find.byKey(const ValueKey('reverse-199')));
  await tester.pumpAndSettle();
}

Future<void> confirm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Wrong application');
  await tester.ensureVisible(
    find.widgetWithText(WgtCommButton, 'Remove application'),
  );
  await tester.tap(find.widgetWithText(WgtCommButton, 'Remove application'));
  await tester.pumpAndSettle();
  expect(find.byType(WgtConfirmBox), findsOneWidget);
  await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'sheet keeps actions visible with a phone keyboard in $brightness',
      (tester) async {
        final host = await mount(
          tester,
          normalRequest,
          size: const Size(390, 844),
          theme: ThemeData(brightness: brightness),
        );
        await open(tester, host);
        expect(tester.takeException(), isNull);
        expect(find.text('Payment Apply · #199'), findsOneWidget);
        expect(find.text('26 May 2026'), findsOneWidget);
        expect(find.text('No reversals recorded'), findsOneWidget);
        final primary = find.widgetWithText(
          WgtCommButton,
          'Remove application',
        );
        final initialPosition = tester.getRect(primary);
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(primary), initialPosition);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        final reasonHeight = tester.getSize(find.byType(TextField)).height;
        final longReason = List.filled(
          8,
          'Correct an incorrect application with a detailed explanation.',
        ).join(' ');
        await tester.enterText(find.byType(TextField), longReason);
        await tester.ensureVisible(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(TextField)).height, reasonHeight);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          longReason,
        );
        expect(tester.getRect(primary).bottom, lessThanOrEqualTo(544));
        expect(
          tester.getRect(find.widgetWithText(TextButton, 'Done')).bottom,
          lessThanOrEqualTo(544),
        );
        expect(
          tester.getRect(find.byType(TextField)).bottom,
          lessThan(tester.getRect(primary).top),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(TextButton, 'Done'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      },
    );
  }

  testWidgets('sheet supports enlarged text and readable source details', (
    tester,
  ) async {
    final host = await mount(
      tester,
      normalRequest,
      size: const Size(360, 800),
      textScale: 1.5,
    );
    await open(tester, host);
    final source = find.text('Source details');
    await tester.ensureVisible(source);
    await tester.tap(source);
    await tester.pumpAndSettle();
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('247.28'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getRect(find.widgetWithText(WgtCommButton, 'Remove application'))
          .bottom,
      lessThanOrEqualTo(800),
    );
  });

  testWidgets('check requires page one, newest order and actual account head', (
    tester,
  ) async {
    final host = await mount(tester, normalRequest);
    expect(checkEnabled(tester), false);
    for (final result in [
      listResult(page: 2),
      listResult(order: 'asc'),
      listResult(items: [rows[1]]),
    ]) {
      await host.correction.currentState!.updateList(result);
      await tester.pumpAndSettle();
      expect(checkEnabled(tester), false);
    }
    await host.correction.currentState!.updateList(listResult());
    await tester.pumpAndSettle();
    expect(checkEnabled(tester), true);
    expect(
      host.actions,
      isEmpty,
    ); // Loading the list never exposes reverse icons.
    host.correction.currentState!.invalidateList();
    await tester.pumpAndSettle();
    expect(checkEnabled(tester), false);
  });

  testWidgets(
    'server marks PYA below bill and opens sheet with details and reason',
    (tester) async {
      final host = await mount(tester, normalRequest);
      await check(tester, host);
      expect(host.actions.keys, ['199']);
      expect(find.byKey(const ValueKey('reverse-200')), findsNothing);
      final icon = find.byKey(const ValueKey('reverse-199'));
      expect(
        tester.getCenter(icon).dx,
        lessThan(tester.getCenter(find.text('2')).dx),
      );
      await tester.tap(icon);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Reverse SOA entry'), findsOneWidget);
      expect(find.text('Interest movement'), findsOneWidget);
      expect(find.text('-4.47'), findsOneWidget);
      expect(find.text('Reason (required)'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blocked reversal check uses the shared dialog and clears after dismissal',
    (tester) async {
      var blocked = true;
      final host = await mount(
        tester,
        (action, body) async => blocked
            ? {
                ...rootPreview(),
                'actions': [],
                'reasons': ['Regenerate or remove the later draft bill first'],
              }
            : await normalRequest(action, body),
      );
      await check(tester, host);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cannot reverse entry'), findsOneWidget);
      expect(
        find.text(
          'Delete the un-released or draft bill before reversing further.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Regenerate or remove the later draft bill first'),
        findsNothing,
      );
      expect(host.actions, isEmpty);
      expect(host.changes, 0);
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Delete the un-released'), findsNothing);
      blocked = false;
      expect(checkEnabled(tester), isTrue);
      await tester.tap(find.text('Check reversible entry'));
      await tester.pumpAndSettle();
      expect(host.actions.keys, ['199']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reversal check dialog retains additional blocking reasons', (
    tester,
  ) async {
    final host = await mount(
      tester,
      (action, body) async => {
        ...rootPreview(),
        'actions': [],
        'reasons': [
          'Regenerate or remove the later draft bill first',
          'Closed periods are protected',
        ],
      },
    );
    await check(tester, host);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text(
        'Delete the un-released or draft bill before reversing further.\nClosed periods are protected',
      ),
      findsOneWidget,
    );
    expect(host.actions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed reversal check shows a dismissible dialog instead of inline error',
    (tester) async {
      var fail = false;
      final host = await mount(tester, (action, body) async {
        if (fail) throw Exception('Check unavailable. Try again.');
        return normalRequest(action, body);
      });
      await host.correction.currentState!.updateList(listResult());
      await tester.pumpAndSettle();
      fail = true;
      await tester.tap(find.text('Check reversible entry'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Check unavailable. Try again.'),
        findsOneWidget,
      );
      expect(host.actions, isEmpty);
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Check unavailable. Try again.'),
        findsNothing,
      );
      expect(checkEnabled(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changed list discards late check response and clears marked rows',
    (tester) async {
      Completer<dynamic>? delayed;
      final host = await mount(
        tester,
        (action, body) => delayed?.future ?? normalRequest(action, body),
      );
      await host.correction.currentState!.updateList(listResult());
      await tester.pumpAndSettle();
      delayed = Completer<dynamic>();
      await tester.tap(find.text('Check reversible entry'));
      await tester.pump();
      host.correction.currentState!.invalidateList();
      delayed.complete({
        ...rootPreview(),
        'actions': [],
        'reasons': ['Regenerate or remove the later draft bill first'],
      });
      await tester.pumpAndSettle();
      expect(host.actions, isEmpty);
      expect(checkEnabled(tester), false);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('rechecks selected entry before opening sheet', (tester) async {
    final host = await mount(
      tester,
      (action, body) async => body['target_soa_id'] != null
          ? {...targetPreview(), 'max_soa_id': 201}
          : await normalRequest(action, body),
    );
    await open(tester, host);
    expect(find.byType(BottomSheet), findsNothing);
    expect(host.actions, isEmpty);
    expect(find.textContaining('no longer reversible'), findsOneWidget);
  });

  testWidgets(
    'commit sends selected PYA and checked snapshot; rejection clears icons',
    (tester) async {
      final commits = <Map<String, dynamic>>[];
      final host = await mount(tester, (action, body) async {
        if (action == 'commit') {
          commits.add(Map.from(body));
          return {'rejected': true, 'message': 'Account changed. Check again.'};
        }
        return normalRequest(action, body);
      });
      await open(tester, host);
      await confirm(tester);
      expect(commits.single['target_soa_id'], 199);
      expect(commits.single['expected_top_soa_id'], 200);
      expect(commits.single['expected_max_soa_id'], 200);
      expect(commits.single['reason'], 'Wrong application');
      expect(host.actions, isEmpty);
      expect(host.changes, 0);
      expect(find.textContaining('Account changed'), findsOneWidget);
      expect(
        find.widgetWithText(WgtCommButton, 'Retry operation'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reconciliation rejection shows readable issues and attempted balances',
    (tester) async {
      final report = {
        'total': -276.00,
        'issues': [
          {
            'id': 2651,
            'table': 'billing_rec',
            'message': 'Invoice remaining amount differs',
          },
        ],
        'passed': false,
        'interest': null,
        'principal': null,
        'unapplied': 257.65,
      };
      final host = await mount(tester, (action, body) async {
        if (action == 'commit') {
          return {
            'rejected': true,
            'message': 'Reconciliation failed: ${jsonEncode(report)}',
          };
        }
        if (action == 'reconcile') {
          return {...report, 'total': 0, 'unapplied': 533.65};
        }
        return normalRequest(action, body);
      });
      await open(tester, host);
      await confirm(tester);
      expect(
        find.textContaining('Bill #2651: Remaining amount does not match'),
        findsWidgets,
      );
      expect(find.textContaining('"issues"'), findsNothing);
      expect(
        find.text('Attempted operation balance check: Needs attention'),
        findsOneWidget,
      );
      expect(find.textContaining('no changes were saved'), findsOneWidget);
      expect(host.changes, 0);
      expect(host.actions, isEmpty);
      expect(
        find.widgetWithText(WgtCommButton, 'Retry operation'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Check balances'));
      await tester.pumpAndSettle();
      expect(find.text('Balance check: Needs attention'), findsOneWidget);
      expect(
        find.text('Attempted operation balance check: Needs attention'),
        findsNothing,
      );
      expect(find.text('533.65'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('balance check formats issue records and clears an earlier error', (
    tester,
  ) async {
    var checks = 0;
    final host = await mount(tester, (action, body) async {
      if (action == 'reconcile') {
        if (checks++ == 0) {
          throw Exception('Reconciliation failed: invalid payload');
        }
        return {
          'passed': false,
          'total': 0,
          'unapplied': 533.65,
          'issues': [
            {
              'table': 'billing_rec',
              'id': 2651,
              'message': 'Invoice remaining amount differs',
            },
          ],
        };
      }
      return normalRequest(action, body);
    });
    await open(tester, host);
    final checkBalances = find.widgetWithText(TextButton, 'Check balances');
    await tester.tap(checkBalances);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Refresh the account and check balances'),
      findsOneWidget,
    );
    expect(find.textContaining('invalid payload'), findsNothing);
    await tester.tap(checkBalances);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Refresh the account and check balances'),
      findsNothing,
    );
    expect(
      find.text(
        'Bill #2651: Remaining amount does not match the bill total minus applied payments.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uncertain commit retry preserves operation ID and payload', (
    tester,
  ) async {
    final commits = <Map<String, dynamic>>[];
    final host = await mount(tester, (action, body) async {
      if (action == 'commit') {
        commits.add(Map.from(body));
        throw Exception('Connection lost');
      }
      return normalRequest(action, body);
    });
    await open(tester, host);
    await confirm(tester);
    await tester.ensureVisible(
      find.widgetWithText(WgtCommButton, 'Retry operation'),
    );
    await tester.tap(find.widgetWithText(WgtCommButton, 'Retry operation'));
    await tester.pumpAndSettle();
    expect(commits, hasLength(2));
    expect(commits[1], commits[0]);
    expect(host.changes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared confirmation cancel keeps reason and does not commit', (
    tester,
  ) async {
    var commits = 0;
    final host = await mount(tester, (action, body) async {
      if (action == 'commit') commits++;
      return normalRequest(action, body);
    });
    await open(tester, host);
    await tester.enterText(find.byType(TextField), 'Wrong application');
    final reverse = find.widgetWithText(WgtCommButton, 'Remove application');
    await tester.tap(reverse);
    await tester.pumpAndSettle();
    expect(find.byType(WgtConfirmBox), findsOneWidget);
    expect(find.textContaining('Reason: Wrong application'), findsOneWidget);
    expect(commits, 0);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(WgtConfirmBox), findsNothing);
    expect(commits, 0);
    expect(tester.widget<WgtCommButton>(reverse).enabled, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Wrong application',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing reason cannot call commit', (tester) async {
    var commits = 0;
    final host = await mount(tester, (action, body) async {
      if (action == 'commit') commits++;
      return normalRequest(action, body);
    });
    await open(tester, host);
    await tester.ensureVisible(
      find.widgetWithText(WgtCommButton, 'Remove application'),
    );
    await tester.tap(find.widgetWithText(WgtCommButton, 'Remove application'));
    await tester.pumpAndSettle();
    expect(commits, 0);
    expect(find.textContaining('Enter a reason'), findsOneWidget);
  });
  testWidgets(
    'successful commit refreshes the account without querying the archived entry',
    (tester) async {
      var committed = false;
      final refreshBodies = <Map<String, dynamic>>[];
      final host = await mount(tester, (action, body) async {
        if (action == 'commit') {
          committed = true;
          return {
            'correction_op_id': 'correction-1',
            'reconciliation': {'passed': true},
          };
        }
        if (committed && action == 'history') return [];
        if (committed) {
          refreshBodies.add(Map<String, dynamic>.from(body));
          if (body['target_soa_id'] != null) {
            return {
              ...rootPreview(),
              'correction_op_id': 'correction-1',
              'actions': [],
              'reasons': ['SOA entry not found'],
            };
          }
          return {
            ...rootPreview(),
            // Even if another entry can be reversed, the old action is complete.
            'allowed': true,
            'actions': [
              {'op_type': 'unrelease_bill', 'target_soa_id': 200},
            ],
            'correction_op_id': 'correction-1',
            'reasons': [],
          };
        }
        return normalRequest(action, body);
      });
      await open(tester, host);
      await confirm(tester);
      expect(host.changes, 1);
      expect(host.actions, isEmpty);
      expect(refreshBodies, [<String, dynamic>{}]);
      expect(find.text('SOA entry not found'), findsNothing);
      expect(find.text('Operation completed.'), findsOneWidget);
      expect(
        find.widgetWithText(WgtCommButton, 'Remove application'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Refresh'));
      await tester.pumpAndSettle();
      expect(refreshBodies, [<String, dynamic>{}, <String, dynamic>{}]);
      expect(find.text('SOA entry not found'), findsNothing);
      expect(
        find.widgetWithText(WgtCommButton, 'Remove application'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.text('Manage correction'), findsNothing);
      await tester.tap(find.text('History / balances'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(WgtCommButton, 'Close correction'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completed bill keeps its snapshot and excludes the next entry restrictions',
    (tester) async {
      var committed = false;
      const billOperation = {'op_type': 'unrelease_bill', 'target_soa_id': 200};
      const restrictions = [
        'The bill un-release has ended this correction chain. Complete source actions and close the correction.',
        'Regenerate or remove the later draft bill first',
      ];
      final host = await mount(tester, (action, body) async {
        if (action == 'history') return [];
        if (action == 'commit') {
          committed = true;
          return {
            'op_type': 'unrelease_bill',
            'correction_op_id': 'bill-correction',
            'reconciliation': {'passed': true},
          };
        }
        if (action == 'reconcile') {
          return {
            'passed': false,
            'issues': [
              {
                'table': 'billing_rec',
                'id': 2651,
                'message': 'Invoice remaining amount differs',
              },
            ],
          };
        }
        if (committed) {
          expect(body.containsKey('target_soa_id'), isFalse);
          return {
            ...rootPreview(),
            'correction_op_id': 'bill-correction',
            'actions': [],
            'target': {
              'id': 198,
              'entry_type': 'payment',
              'entry_timestamp': '2026-05-26',
              'payment_id': 366,
            },
            'source': {'id': 366, 'lc_status': 'released'},
            'reasons': restrictions,
            'applications': [
              {'payment_apply_id': 999, 'principal': 12, 'interest': 0},
            ],
          };
        }
        return {
          ...rootPreview(),
          'allowed': true,
          'op_type': 'unrelease_bill',
          'actions': [billOperation],
          'reasons': [],
          if (body.containsKey('target_soa_id')) ...{
            'target': {...rows[0], 'billing_rec_id': 2646},
            'source': {'id': 2646, 'lc_status': 'released'},
          },
        };
      });
      await check(tester, host);
      await tester.tap(find.byKey(const ValueKey('reverse-200')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Correct the bill');
      await tester.tap(find.widgetWithText(WgtCommButton, 'Un-release bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(host.changes, 1);
      expect(find.text('Bill · #200'), findsOneWidget);
      expect(find.text('27 May 2026'), findsOneWidget);
      expect(find.text('Payment · #198'), findsNothing);
      expect(find.text('Operation completed.'), findsOneWidget);
      expect(find.textContaining('Correction in progress.'), findsNothing);
      for (final restriction in restrictions) {
        expect(find.text(restriction), findsNothing);
      }
      expect(find.textContaining('Application 999:'), findsNothing);
      expect(
        find.widgetWithText(WgtCommButton, 'Un-release bill'),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Source details'));
      await tester.tap(find.text('Source details'));
      await tester.pumpAndSettle();
      // Both the selected-entry card and its source retain the original bill ID.
      expect(find.text('2646'), findsNWidgets(2));
      expect(find.text('366'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Bill · #200'), findsOneWidget);
      expect(find.text('Operation completed.'), findsOneWidget);
      for (final restriction in restrictions) {
        expect(find.text(restriction), findsNothing);
      }
      // A real reconciliation problem still appears after the reversal succeeds.
      await tester.tap(find.widgetWithText(TextButton, 'Check balances'));
      await tester.pumpAndSettle();
      expect(find.text('Balance check: Needs attention'), findsOneWidget);
      expect(
        find.textContaining('Bill #2651: Remaining amount does not match'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Operation completed.'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('History / balances'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(WgtCommButton, 'Close correction'),
        findsNothing,
      );
      for (final restriction in restrictions) {
        expect(find.text(restriction), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final operationType in [
    'unrelease_payment',
    'unrelease_bill',
    'remove_payment_apply',
  ]) {
    testWidgets(
      'completed $operationType clears correction management and pause notices',
      (tester) async {
        var committed = false;
        final refreshBodies = <Map<String, dynamic>>[];
        final isBill = operationType == 'unrelease_bill';
        final targetId = isBill ? 200 : 199;
        final operationLabel = switch (operationType) {
          'unrelease_bill' => 'Un-release bill',
          'remove_payment_apply' => 'Remove application',
          _ => 'Un-release payment',
        };
        final completedAction = switch (operationType) {
          'unrelease_bill' => 'Bill un-released',
          'remove_payment_apply' => 'Payment Apply removed',
          _ => 'Payment un-released',
        };
        final completedOperation = {
          'op_type': operationType,
          'target_soa_id': targetId,
        };
        final host = await mount(tester, (action, body) async {
          if (action == 'history') return [];
          if (action == 'commit') {
            committed = true;
            return {
              'op_type': operationType,
              'outcome': 'completed',
              'correction_op_id': 'finished-correction',
              'reconciliation': {'passed': true},
            };
          }
          if (committed) {
            refreshBodies.add(Map<String, dynamic>.from(body));
            return {
              ...rootPreview(),
              'correction_op_id': null,
              'actions': [],
              'reasons': [],
            };
          }
          return {
            ...body.containsKey('target_soa_id')
                ? targetPreview()
                : rootPreview(),
            'op_type': operationType,
            'actions': [completedOperation],
            if (body.containsKey('target_soa_id'))
              'target': rows[isBill ? 0 : 1],
          };
        });
        await check(tester, host);
        await tester.tap(find.byKey(ValueKey('reverse-$targetId')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Undo this entry');
        await tester.tap(find.widgetWithText(WgtCommButton, operationLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
        await tester.pumpAndSettle();
        expect(host.changes, 1);
        expect(refreshBodies, [<String, dynamic>{}]);
        expect(
          find.text('Operation completed. $completedAction.'),
          findsOneWidget,
        );
        expect(find.textContaining('correction'), findsNothing);
        expect(find.textContaining('Correction in progress'), findsNothing);
        expect(find.text('Correction outcome'), findsNothing);
        expect(
          find.widgetWithText(WgtCommButton, operationLabel),
          findsNothing,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Done'));
        await tester.pumpAndSettle();
        expect(find.text('Manage correction'), findsNothing);
        expect(find.textContaining('Correction in progress'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'confirmed commit still refreshes list when follow-up preview fails',
    (tester) async {
      var committed = false;
      final host = await mount(tester, (action, body) async {
        if (action == 'commit') {
          committed = true;
          return {
            'correction_op_id': 'correction-1',
            'reconciliation': {'passed': true},
          };
        }
        if (committed) throw Exception('Refresh unavailable');
        return normalRequest(action, body);
      });
      await open(tester, host);
      await confirm(tester);
      expect(host.changes, 1);
      expect(host.actions, isEmpty);
      expect(
        find.textContaining('Operation completed. Could not refresh details'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(WgtCommButton, 'Retry operation'),
        findsNothing,
      );
      expect(
        find.widgetWithText(WgtCommButton, 'Remove application'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'history and balances remain read-only with legacy close records',
    (tester) async {
      final calls = <String>[];
      await mount(tester, (action, body) async {
        calls.add(action);
        if (action == 'history') {
          return [
            {
              'op_type': 'close_correction',
              'op_timestamp': '2026-05-26T12:00:00',
              'op_username': 'tester',
              'reason': 'Legacy completion',
              'outcome': 'completed',
              'details': <String, dynamic>{},
            },
          ];
        }
        if (action == 'reconcile') return {'passed': true, 'issues': []};
        return {...rootPreview(), 'actions': [], 'reasons': []};
      });
      await tester.tap(find.text('History / balances'));
      await tester.pumpAndSettle();
      expect(find.text('Reversal history'), findsWidgets);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Correction outcome'), findsNothing);
      expect(find.text('Close correction'), findsNothing);
      expect(find.text('Manage correction'), findsNothing);
      await tester.tap(find.text('Reversal history').last);
      await tester.pumpAndSettle();
      expect(find.text('Legacy workflow completed'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Check balances'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Balance check: Passed'), findsOneWidget);
      expect(calls, containsAll(['preview', 'history', 'reconcile']));
      expect(calls, isNot(contains('commit')));
      expect(calls, isNot(contains('apply')));
      expect(tester.takeException(), isNull);
    },
  );
}

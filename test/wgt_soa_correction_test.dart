import 'dart:async';

import 'package:buff_helper/pkg_buff_helper.dart';
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
          onHoldChanged: (_) {},
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
  Future<dynamic> Function(String, Map<String, dynamic>) request,
) async {
  tester.view.physicalSize = const Size(1100, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<HostState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Host(key: key, request: request),
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
bool checkEnabled(WidgetTester tester) =>
    tester.widget<WgtCommButton>(find.byType(WgtCommButton)).enabled;
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
    find.widgetWithText(FilledButton, 'Remove application'),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Remove application'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
  await tester.pumpAndSettle();
}

void main() {
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
      expect(find.text('Interest movement: -4.47'), findsOneWidget);
      expect(find.text('Reason (required)'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
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
      delayed.complete(rootPreview());
      await tester.pumpAndSettle();
      expect(host.actions, isEmpty);
      expect(checkEnabled(tester), false);
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
        find.widgetWithText(FilledButton, 'Retry operation'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
      find.widgetWithText(FilledButton, 'Retry operation'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Retry operation'));
    await tester.pumpAndSettle();
    expect(commits, hasLength(2));
    expect(commits[1], commits[0]);
    expect(host.changes, 0);
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
      find.widgetWithText(FilledButton, 'Remove application'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Remove application'));
    await tester.pumpAndSettle();
    expect(commits, 0);
    expect(find.textContaining('Enter a reason'), findsOneWidget);
  });
  testWidgets(
    'successful commit refreshes list and keeps correction management available',
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
        if (committed && action == 'history') return [];
        if (committed) {
          return {
            ...rootPreview(),
            'allowed': false,
            'actions': [],
            'correction_op_id': 'correction-1',
            'reasons': ['SOA entry not found'],
          };
        }
        return normalRequest(action, body);
      });
      await open(tester, host);
      await confirm(tester);
      expect(host.changes, 1);
      expect(host.actions, isEmpty);
      expect(
        find.widgetWithText(FilledButton, 'Remove application'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.text('Manage correction'), findsOneWidget);
      await tester.tap(find.text('Manage correction'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Close correction'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
        find.widgetWithText(FilledButton, 'Retry operation'),
        findsNothing,
      );
      expect(
        find.widgetWithText(FilledButton, 'Remove application'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

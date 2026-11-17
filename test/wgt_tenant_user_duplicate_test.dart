import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_new_edit_tenant_user.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

const username = 'wineconnection-plq';
const duplicateMessage = 'User already belongs to this tenant';
final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

Future<void> openEditor(
  WidgetTester tester, {
  List<Map<String, dynamic>> rows = const [],
  Map<String, dynamic>? initialValue,
  Function? onInsert,
  Function? onUpdate,
}) async {
  final user = MdlPagUser(id: 1, username: 'tester');
  user.selectedScope = MdlPagScopeProfile(
    projectProfile: MdlPagProjectProfile(
      id: 1,
      name: 'cw_p2',
      label: 'CW',
      portalProjectScope: PagPortalProjectScope.values.first,
      timezone: 8,
      appContextConfigList: [],
    ),
  );
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: PagUserProvider()..setCurrentUser(user),
      child: MaterialApp(
        home: Scaffold(
          body: WgtNewEditTenantUser(
            appConfig: config,
            loggedInUser: user,
            strItemGroupId: '1707',
            groupItemList: rows,
            initialValueMap: initialValue,
            onInsert: onInsert,
            onUpdate: onUpdate,
          ),
        ),
      ),
    ),
  );
}

WgtTextField field(WidgetTester tester) =>
    tester.widget<WgtTextField>(find.byType(WgtTextField));
Future<void> changeName(WidgetTester tester, String name) async {
  field(tester).onChanged(name);
  field(tester).onValidate!(null);
  await tester.pump();
}

Future<void> lookup(WidgetTester tester, String name) async {
  await changeName(tester, name);
  await field(tester).onEditingComplete!();
  await tester.pump();
}

bool addEnabled(WidgetTester tester) =>
    tester
        .widget<InkWell>(
          find.ancestor(of: find.text('Add'), matching: find.byType(InkWell)),
        )
        .onTap !=
    null;
http.Response foundUser([Object? id = '284']) => http.Response(
  jsonEncode({
    'data': {
      'item_info': {'id': id, 'username': username},
    },
  }),
  200,
);

void main() {
  testWidgets('production username shape blocks duplicate before lookup', (
    tester,
  ) async {
    int requests = 0;
    int inserts = 0;
    await http.runWithClient(
      () async {
        await openEditor(
          tester,
          rows: [
            {'id': '284', 'user_id': '284', 'username': username},
          ],
          onInsert: (_) => inserts++,
        );
        await lookup(tester, ' $username ');
        expect(find.text(duplicateMessage), findsOneWidget);
        expect(addEnabled(tester), isFalse);
        expect(requests, 0);
        expect(inserts, 0);
      },
      () => MockClient((_) async {
        requests++;
        return foundUser();
      }),
    );
  });
  testWidgets('resolved ID catches duplicate with a different displayed name', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await openEditor(
        tester,
        rows: [
          {'user_id': 284, 'username': 'old-name'},
        ],
      );
      await lookup(tester, username);
      expect(find.text(duplicateMessage), findsOneWidget);
      expect(addEnabled(tester), isFalse);
    }, () => MockClient((_) async => foundUser()));
  });
  for (final removed in [false, true]) {
    testWidgets('valid user can be added with removed row = $removed', (
      tester,
    ) async {
      Map<String, dynamic>? inserted;
      await http.runWithClient(() async {
        await openEditor(
          tester,
          rows: [
            if (removed)
              {'user_id': '284', 'username': username, 'edit_type': 'remove'},
          ],
          onInsert: (row) => inserted = row,
        );
        await lookup(tester, username);
        expect(addEnabled(tester), isTrue);
        await tester.tap(find.text('Add'));
        expect(inserted?['user_id'], '284');
        expect(inserted?['id'], '284');
        expect(inserted?['tenant_id'], '1707');
        expect(inserted?['username'], username);
      }, () => MockClient((_) async => foundUser()));
    });
  }
  testWidgets('pending lookup and stale response cannot enable Add', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await http.runWithClient(() async {
      await openEditor(tester);
      await changeName(tester, username);
      final pending = field(tester).onEditingComplete!() as Future;
      await tester.pump();
      expect(addEnabled(tester), isFalse);
      await changeName(tester, 'another-user');
      response.complete(foundUser());
      await pending;
      await tester.pump();
      expect(addEnabled(tester), isFalse);
      expect(find.text(duplicateMessage), findsNothing);
    }, () => MockClient((_) => response.future));
  });
  testWidgets('failed lookup clears previously resolved ID', (tester) async {
    int calls = 0;
    await http.runWithClient(
      () async {
        await openEditor(tester);
        await lookup(tester, username);
        expect(addEnabled(tester), isTrue);
        await lookup(tester, 'missing-user');
        expect(addEnabled(tester), isFalse);
        await changeName(tester, '');
        expect(addEnabled(tester), isFalse);
      },
      () => MockClient(
        (_) async => ++calls == 1
            ? foundUser()
            : http.Response(
                jsonEncode({
                  'error': {'message': 'No item info found'},
                }),
                200,
              ),
      ),
    );
  });
  testWidgets('ID is required even if lookup returns a record', (tester) async {
    await http.runWithClient(() async {
      await openEditor(tester);
      await lookup(tester, username);
      expect(addEnabled(tester), isFalse);
    }, () => MockClient((_) async => foundUser(null)));
  });
  testWidgets('rechecks current list before inserting', (tester) async {
    final rows = <Map<String, dynamic>>[];
    int inserts = 0;
    await http.runWithClient(() async {
      await openEditor(tester, rows: rows, onInsert: (_) => inserts++);
      await lookup(tester, username);
      rows.add({'user_id': '284', 'username': username});
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(inserts, 0);
      expect(find.text(duplicateMessage), findsOneWidget);
    }, () => MockClient((_) async => foundUser()));
  });
  testWidgets('existing user notification setting remains editable', (
    tester,
  ) async {
    final row = <String, dynamic>{
      'id': '284',
      'user_id': '284',
      'username': username,
      'receive_billing_notification': 'false',
    };
    Map<String, dynamic>? updated;
    await openEditor(
      tester,
      rows: [row],
      initialValue: row,
      onUpdate: (value) => updated = value,
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Update'));
    expect(updated?['user_id'], '284');
    expect(updated?['receive_billing_notification'], 'true');
    expect(find.text(duplicateMessage), findsNothing);
  });
}

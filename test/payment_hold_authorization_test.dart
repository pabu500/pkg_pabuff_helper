import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/comm_fin_ops.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_match_one_payment3.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

http.Response result(String key, dynamic value) => http.Response(
  jsonEncode({
    'success': true,
    'data': {
      'result_key': key,
      'result': {key: value},
    },
  }),
  200,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'permission probe carries the active user token and project scope',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/ems/fin/get_payment_hold_access');
        expect(request.headers['Authorization'], 'Bearer signed-user-token');
        final body = jsonDecode(request.body);
        expect(body['svcClaimDto']['username'], 'dexter-cw');
        expect(body['request']['scope']['project_name'], 'cw_p2');
        return result('payment_hold_access', {
          'is_authorized': true,
          'enabled': true,
        });
      });
      final access = await getPaymentHoldAccess(
        config,
        {
          'scope': {'project_name': 'cw_p2', 'project_id': '12'},
        },
        MdlPagSvcClaim(userId: 194, username: 'dexter-cw'),
        loginToken: 'signed-user-token',
        client: client,
      );
      expect(access['is_authorized'], true);
      client.close();
    },
  );

  test('override request preserves explicit consent and reason with a signed token', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/ems/fin/commit_payment_apply');
      expect(request.headers['Authorization'], 'Bearer signed-user-token');
      final payload = jsonDecode(request.body)['request'];
      expect(payload['keep_earlier_unapplied'], true);
      expect(payload['hold_override_reason'], 'Tenant reconciliation');
      return result('commit_payment_apply_result', {'applied': true});
    });
    await commitPaymentApply(
      config,
      {
        'keep_earlier_unapplied': true,
        'hold_override_reason': 'Tenant reconciliation',
      },
      MdlPagSvcClaim(userId: 194, username: 'dexter-cw'),
      loginToken: 'signed-user-token',
      client: client,
    );
    client.close();
  });

  test(
    'normal application does not opt into overriding earlier payments',
    () async {
      final client = MockClient((request) async {
        final payload = jsonDecode(request.body)['request'];
        expect(payload.containsKey('keep_earlier_unapplied'), false);
        expect(payload.containsKey('hold_override_reason'), false);
        return result('commit_payment_apply_result', {'applied': true});
      });
      await commitPaymentApply(
        config,
        {'payment_id': '12'},
        MdlPagSvcClaim(userId: 194, username: 'dexter-cw'),
        loginToken: 'signed-user-token',
        client: client,
      );
      client.close();
    },
  );

  test('server permission denial is shown to the caller', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'message':
                'Create access to applyNewWithEarlierUnapplied is required',
          },
        }),
        403,
      ),
    );
    await expectLater(
      commitPaymentApply(
        config,
        {'keep_earlier_unapplied': true},
        MdlPagSvcClaim(userId: 194, username: 'dexter-cw'),
        loginToken: 'signed-user-token',
        client: client,
      ),
      throwsA(predicate((e) => e.toString().contains('Create access'))),
    );
    client.close();
  });

  test('logout clears the active login credential', () {
    final user = MdlPagUser(id: 194, username: 'dexter-cw')
      ..loginToken = 'signed-user-token';
    user.logout();
    expect(user.loginToken, isNull);
  });

  Future<void> pumpPayment(
    WidgetTester tester, {
    required bool authorized,
    bool enabled = true,
    String amount = '100',
    List<Map<String, dynamic>> bills = const [],
    List<Map<String, dynamic>> existingApplies = const [],
  }) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WgtMatchOnePayment3(
                  appConfig: config,
                  loggedInUser: MdlPagUser(id: 194, username: 'dexter-cw')
                    ..loginToken = 'signed-user-token',
                  tenantInfo: const {
                    'tenant_name': 'tenant',
                    'tenant_label': 'Tenant',
                    'tenant_id': '1',
                  },
                  defaultPaymentLcStatusStr: 'released',
                  paymentMatchingInfo: {
                    'id': '12',
                    'amount': amount,
                    'lc_status': 'released',
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('get_payment_hold_access')) {
          return result('payment_hold_access', {
            'is_authorized': authorized,
            'enabled': enabled,
          });
        }
        return result('payment_match_op_info', {
          'payment_info': {'id': '12'},
          'bill_list': bills,
          'payment_apply_info_list': existingApplies,
        });
      }),
    );
  }

  testWidgets(
    'manual Commit requires both amounts on every entered bill and a nonnegative balance',
    (tester) async {
      await pumpPayment(
        tester,
        authorized: false,
        amount: '2035.57',
        bills: [
          {
            'id': '7',
            'lc_status': 'released',
            'billed_interest_amount': '36.59',
          },
          {'id': '8', 'lc_status': 'released'},
        ],
        existingApplies: [
          {'billing_rec_id': '6', 'usage_amount_from_payment': '1998.98'},
        ],
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      Finder amountField(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      );
      final field = amountField('interest-7');
      final principal = amountField('principal-7');
      final commit = find.widgetWithIcon(IconButton, Icons.cloud_upload);
      expect(commit, findsNothing);
      await tester.enterText(field, '36.');
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '36.');
      tester.testTextInput.enterText('36.59');
      await tester.pump();
      expect(commit, findsNothing);
      expect(find.text(' 0.00 '), findsOneWidget);
      await tester.enterText(principal, '0');
      await tester.pump();
      expect(tester.widget<IconButton>(commit).onPressed, isNotNull);
      expect(tester.testTextInput.hasAnyClients, isTrue);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('principal-7')),
          matching: find.byIcon(Icons.clear),
        ),
      );
      await tester.pump();
      expect(commit, findsNothing);
      await tester.enterText(principal, '.');
      await tester.pump();
      expect(commit, findsNothing);
      await tester.enterText(principal, '0.00');
      await tester.pump();
      expect(tester.widget<IconButton>(commit).onPressed, isNotNull);

      await tester.enterText(amountField('principal-8'), '0');
      await tester.pump();
      expect(commit, findsNothing);
      await tester.enterText(amountField('principal-8'), '');
      await tester.pump();
      expect(tester.widget<IconButton>(commit).onPressed, isNotNull);

      await tester.enterText(field, '36.60');
      await tester.pump();
      expect(find.text(' -0.01 '), findsOneWidget);
      expect(commit, findsNothing);

      tester.testTextInput.enterText('36.59');
      await tester.pump();
      expect(tester.widget<IconButton>(commit).onPressed, isNotNull);
      tester.testTextInput.enterText('');
      await tester.pump();
      expect(find.text(' 36.59 '), findsOneWidget);
      expect(commit, findsNothing);

      tester.testTextInput.enterText('0');
      await tester.pump();
      expect(commit, findsNothing);
      tester.testTextInput.enterText('36.59');
      await tester.pump();
      Map<String, dynamic>? submitted;
      await http.runWithClient(
        () async {
          await tester.tap(commit);
          await tester.pumpAndSettle();
        },
        () => MockClient((request) async {
          expect(request.url.path, '/ems/fin/commit_payment_apply');
          submitted = jsonDecode(request.body)['request'];
          return result('commit_payment_apply_result', {'applied': true});
        }),
      );
      final allocation = (submitted!['apply_list'] as List).single;
      expect(allocation['billing_rec_id'], '7');
      expect(allocation['usage_amount_from_payment'], 0);
      expect(allocation['interest_amount_from_payment'], 36.59);
      expect(find.text('Apply Committed'), findsOneWidget);
    },
  );

  testWidgets(
    'authorized user explicitly selects override before entering a reason',
    (tester) async {
      await pumpPayment(tester, authorized: true);
      expect(find.text('Keep earlier payments unapplied'), findsOneWidget);
      expect(find.text('Reason (required)'), findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Reason (required)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Tenant reconciliation');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Reason (required)'), findsNothing);
    },
  );

  testWidgets('user without create permission gets no override control', (
    tester,
  ) async {
    await pumpPayment(tester, authorized: false);
    expect(find.text('Keep earlier payments unapplied'), findsNothing);
  });

  testWidgets(
    'disabled feature cannot be selected even by an authorized user',
    (tester) async {
      await pumpPayment(tester, authorized: true, enabled: false);
      expect(
        find.text('Payment override is currently disabled.'),
        findsOneWidget,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    },
  );
}

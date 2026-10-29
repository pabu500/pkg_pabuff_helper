import 'dart:convert';
import 'package:buff_helper/pag_helper/comm/comm_billing.dart';
import 'package:buff_helper/pag_helper/comm/comm_billing2.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_create_pag_composite_bill.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_create_pag_composite_bill2.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/bill_payment_hold_controller.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_payment_hold_override.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'payment_hold_authorization_test.dart' show config, result;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final generation in [2, 3]) {
    test(
      'gen $generation sends explicit bill override with reason and signed login',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/ems/billing/gen_bill');
          expect(request.headers['Authorization'], 'Bearer signed');
          final body = jsonDecode(request.body)['request'];
          expect(body['bypass_payment_hold'], true);
          expect(body['hold_override_reason'], 'Tenant choice');
          expect(body.containsKey('keep_earlier_unapplied'), false);
          return result('bill_info', {'billing_rec_id': '3000'});
        });
        final request = {
          'bypass_payment_hold': true,
          'hold_override_reason': 'Tenant choice',
        };
        final claim = MdlPagSvcClaim(username: 'operator', userId: 194);
        final bill = generation == 2
            ? await genPagBill(
                config,
                request,
                claim,
                loginToken: 'signed',
                client: client,
              )
            : await genPagBill2(
                config,
                request,
                claim,
                loginToken: 'signed',
                client: client,
              );
        expect(bill['billing_rec_id'], '3000');
        client.close();
      },
    );
  }
  test('normal bill request never enables an override', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body)['request'];
      expect(body.containsKey('bypass_payment_hold'), false);
      expect(body.containsKey('hold_override_reason'), false);
      return result('bill_info', {'billing_rec_id': '3000'});
    });
    await genPagBill2(
      config,
      {'tenant_id': '1'},
      MdlPagSvcClaim(),
      loginToken: 'signed',
      client: client,
    );
    client.close();
  });
  test('bill permission denial preserves server error', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'Project permission revoked'},
        }),
        403,
      ),
    );
    await expectLater(
      genPagBill2(
        config,
        {'bypass_payment_hold': true},
        MdlPagSvcClaim(),
        loginToken: 'signed',
        client: client,
      ),
      throwsA(
        predicate((e) => e.toString().contains('Project permission revoked')),
      ),
    );
    client.close();
  });

  testWidgets(
    'same controls require reason, reset consent, and respect revoked access',
    (tester) async {
      final user = MdlPagUser(id: 194, username: 'operator')
        ..loginToken = 'signed';
      final controller = BillPaymentHoldController(config, user);
      var authorized = true;
      final client = MockClient(
        (_) async => result('payment_hold_access', {
          'is_authorized': authorized,
          'enabled': true,
        }),
      );
      await http.runWithClient(controller.fetchAccess, () => client);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => WgtPaymentHoldOverride(
                authorized: controller.authorized,
                enabled: controller.enabled,
                selected: controller.selected,
                busy: false,
                accessError: controller.accessError,
                reason: controller.reason,
                onRetry: controller.fetchAccess,
                onChanged: controller.select,
                label: 'Allow bill generation with unapplied payments',
                description: 'Keep older items open',
                warning: 'Balances stay unchanged',
                reasonHint: 'Explain why',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Reason (required)'), findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.valid, false);
      expect(find.text('Reason (required)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Tenant choice  ');
      await tester.pump();
      expect(controller.valid, true);
      expect(controller.requestFields['hold_override_reason'], 'Tenant choice');
      controller.reset();
      await tester.pump();
      expect(controller.requestFields, isEmpty);
      expect(find.text('Reason (required)'), findsNothing);
      controller.select(true);
      authorized = false;
      await http.runWithClient(controller.fetchAccess, () => client);
      await tester.pump();
      expect(find.byType(Checkbox), findsNothing);
      expect(controller.selected, false);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      client.close();
    },
  );
  for (final version in [2, 3]) {
    testWidgets(
      'manual billing form $version shows the shared override and reason input',
      (tester) async {
        tester.view.physicalSize = const Size(1500, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final user = MdlPagUser(id: 194, username: 'operator')
          ..loginToken = 'signed';
        final app = MdlPagAppContext(
          name: 'ems',
          label: 'EMS',
          shortLabel: 'EMS',
          route: 'ems',
          appContextType: PagAppContextType.ems,
        );
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              ChangeNotifierProvider<PagUserProvider>.value(
                value: PagUserProvider()..setCurrentUser(user),
                child: MaterialApp(
                  home: Scaffold(
                    body: version == 2
                        ? WgtCreatePagCompositeBill(
                            appConfig: config,
                            pagAppContext: app,
                            loggedInUser: user,
                          )
                        : WgtCreatePagCompositeBill2(
                            appConfig: config,
                            pagAppContext: app,
                            loggedInUser: user,
                          ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
            final checkbox = find.descendant(
              of: find.byType(WgtPaymentHoldOverride),
              matching: find.byType(Checkbox),
            );
            expect(checkbox, findsOneWidget);
            await tester.ensureVisible(checkbox);
            await tester.tap(checkbox);
            await tester.pump();
            expect(find.text('Reason (required)'), findsOneWidget);
            expect(
              find.text('Allow bill generation with unapplied payments'),
              findsOneWidget,
            );
            await tester.pumpWidget(const SizedBox());
          },
          () => MockClient((request) async {
            if (request.url.path.endsWith('get_payment_hold_access')) {
              return result('payment_hold_access', {
                'is_authorized': true,
                'enabled': true,
              });
            }
            return result('item_list', []);
          }),
        );
      },
    );
  }
}

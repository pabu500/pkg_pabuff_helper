import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_lc_status_op.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'tenant_mfd_test.dart' as support;

void main() {
  for (final admin in [false, true]) {
    testWidgets('reopen visibility and authenticated commit, admin=$admin', (
      tester,
    ) async {
      Map<String, dynamic>? written;
      PagTenantLcStatus? committed;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: WgtPagTenantLcStatusOp(
                  appConfig: support.config,
                  loggedInUser: support.user(),
                  tenantInfo: const {'id': '1', 'name': 'T1'},
                  initialStatus: PagTenantLcStatus.terminated,
                  enableEdit: true,
                  onCommitted: (PagTenantLcStatus status) => committed = status,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final action = find.text('Reopen (back to Offboarding)');
          expect(action, admin ? findsOneWidget : findsNothing);
          if (admin) {
            await tester.tap(action);
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byType(TextField),
              ' Correct mistaken termination ',
            );
            await tester.pump();
            await tester.tap(find.widgetWithText(FilledButton, 'Reopen'));
            await tester.pumpAndSettle();
            expect(written?['termination_token'], '41');
            expect(written?['reason'], 'Correct mistaken termination');
            expect(written?['tenant_id'], '1');
            expect(written?['scope']['project_name'], 'cw_p2');
            expect(committed, PagTenantLcStatus.offboarding);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient((req) async {
          expect(req.headers['Authorization'], startsWith('Bearer '));
          if (req.url.path.endsWith('/reopen_tenant')) {
            written = Map<String, dynamic>.from(
              jsonDecode(req.body)['request'],
            );
            return support.response({'lc_status': 'offb'});
          }
          return support.response({
            'targets': {
              'mfd': {'eligible': false, 'reasons': []},
              if (admin)
                'offb': {
                  'eligible': true,
                  'reasons': [],
                  'termination_token': '41',
                },
            },
          });
        }),
      );
    });
  }
}

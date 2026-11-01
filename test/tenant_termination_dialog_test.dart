library;

import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_termination_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'deposit confirmation is required even when the deposit is unrecorded',
    (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const WgtTenantTerminationDialog(
                      tenantName: 'T1',
                      info: {
                        'final_bill': {
                          'label': 'FINAL-1',
                          'released_timestamp': '2026-02-01',
                        },
                        'soa_balance': '0.00',
                        'unpaid_bills': [],
                        'deposit_amount': null,
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Deposit amount: not recorded'), findsOneWidget);
      final button = find.widgetWithText(TextButton, 'Terminate');
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'terminate T1');
      await tester.pump();
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField).first, 'Returned in cash');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(result, {
        'deposit_return_confirmed': 'true',
        'deposit_return_remark': 'Returned in cash',
      });
      expect(
        result!.keys.any((k) => k.endsWith('_by') || k.contains('username')),
        isFalse,
      );
    },
  );
  testWidgets(
    'zero deposit still requires confirmation and Cancel returns no confirmation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WgtTenantTerminationDialog(
              tenantName: 'T2',
              info: {'deposit_amount': '0.00'},
            ),
          ),
        ),
      );
      expect(find.text('Deposit amount: 0.00'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Terminate'))
            .onPressed,
        isNull,
      );
    },
  );
}


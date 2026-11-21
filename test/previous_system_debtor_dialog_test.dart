import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_previous_system_debtor_dialog.dart';

void main() {
  testWidgets('conversion needs the exact tenant phrase', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const WgtPreviousSystemDebtorDialog(
                    tenantName: 'T1',
                    bill: {
                      'label': 'INI-T1',
                      'bill_release_timestamp': '2026-01-01',
                      'cycle_remaining_balance': '100',
                    },
                    serviceEndDate: '2025-12-31',
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
    final button = find.widgetWithText(TextButton, 'Confirm');
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    expect(find.text('Outstanding: 100'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'convert T1 ');
    await tester.pump();
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'convert T1');
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

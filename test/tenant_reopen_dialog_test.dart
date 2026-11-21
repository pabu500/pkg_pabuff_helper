import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_reopen_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, Map<String, dynamic> info) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WgtTenantReopenDialog(tenantName: 'T1', info: info),
          ),
        ),
      );
  FilledButton button(WidgetTester tester) =>
      tester.widget(find.widgetWithText(FilledButton, 'Reopen'));
  testWidgets('reason is required, trimmed, and must have ten characters', (
    tester,
  ) async {
    await open(tester, {'eligible': true, 'termination_token': '41'});
    expect(button(tester).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '  short  ');
    await tester.pump();
    expect(button(tester).onPressed, isNull);
    await tester.enterText(
      find.byType(TextField),
      ' Correct mistaken termination ',
    );
    await tester.pump();
    expect(button(tester).onPressed, isNotNull);
  });
  testWidgets('blocking preview reasons prevent commit', (tester) async {
    await open(tester, {
      'eligible': false,
      'reasons': ['Closing readings are inconsistent'],
    });
    await tester.enterText(
      find.byType(TextField),
      'Correct mistaken termination',
    );
    await tester.pump();
    expect(button(tester).onPressed, isNull);
    expect(find.text('Closing readings are inconsistent'), findsOneWidget);
  });
  testWidgets('ambiguous handover effects require acknowledgement', (
    tester,
  ) async {
    await open(tester, {
      'eligible': true,
      'requires_naming_acknowledgement': true,
      'handovers_to_name': [
        {
          'id': '7',
          'meter_name': 'M1',
          'to_tenant_label': 'Receiver',
          'effects': ['This tenant cannot return to Normal.'],
        },
      ],
    });
    await tester.enterText(
      find.byType(TextField),
      'Correct mistaken termination',
    );
    await tester.pump();
    expect(button(tester).onPressed, isNull);
    expect(find.textContaining('Receiver'), findsOneWidget);
    expect(find.text('• This tenant cannot return to Normal.'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(button(tester).onPressed, isNotNull);
  });
  testWidgets('NULL group status needs an explicit selection', (tester) async {
    await open(tester, {
      'eligible': true,
      'groups_without_snapshot': [
        {
          'id': '10',
          'name': 'G10',
          'allowed_values': [null, 'normal'],
        },
      ],
    });
    await tester.enterText(
      find.byType(TextField),
      'Correct mistaken termination',
    );
    await tester.pump();
    expect(button(tester).onPressed, isNull);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No status (NULL)').last);
    await tester.pumpAndSettle();
    expect(button(tester).onPressed, isNotNull);
  });
}

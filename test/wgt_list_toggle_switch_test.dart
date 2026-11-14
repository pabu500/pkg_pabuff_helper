import 'package:buff_helper/xt_ui/wdgt/list/wgt_list_toggle_switch.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('list toggle preserves selection and row update mapping', (
    tester,
  ) async {
    final row = <String, dynamic>{};
    var changed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WgtListToggleSwith(
            initialLabelIndex: 0,
            fieldKey: 'enabled',
            modifiedRow: row,
            flagModified: (value) => changed = value,
          ),
        ),
      ),
    );
    expect(
      tester.widget<ToggleButtons>(find.byType(ToggleButtons)).isSelected,
      [true, false],
    );
    await tester.tap(find.text('No'));
    await tester.pump();
    expect(
      tester.widget<ToggleButtons>(find.byType(ToggleButtons)).isSelected,
      [false, true],
    );
    expect(row['enabled'], isTrue);
    expect(changed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled list toggle cannot change its value', (tester) async {
    final row = <String, dynamic>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WgtListToggleSwith(
            initialLabelIndex: 1,
            disabled: true,
            fieldKey: 'enabled',
            modifiedRow: row,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Yes'));
    await tester.pump();
    expect(
      tester.widget<ToggleButtons>(find.byType(ToggleButtons)).isSelected,
      [false, true],
    );
    expect(row, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

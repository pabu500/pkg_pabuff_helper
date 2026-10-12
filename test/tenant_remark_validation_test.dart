@TestOn('browser')
library;

import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_view_edit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final editValidator = getItemKindValidator(
    PagItemKind.tenant,
    'remark',
    isValueRequired: false,
  );

  test(
    'CSV onboarding, CSV updates and individual edits accept the same remarks',
    () {
      final validators = <String? Function(String)>[editValidator];
      for (final op in [PagTenantOpType.onboarding, PagTenantOpType.update]) {
        final config = getListConfigBaseByTenantOpType(op)
            .firstWhere((field) => field['col_key'] == 'remark');
        validators.add(config['validator'] as String? Function(String));
      }

      for (final validator in validators) {
        for (final value in [
          '',
          'A',
          'FTFwef8Jul25to7Jul28',
          'FTF wef 8 Jul 25 to 7 Jul 28 (A/B) - C & D',
          "Note_1: A, B / C + D - E #2 & F @ G's (unit).",
          'FTF\u00a0wef 8 Jul 25',
          'FTF\u2007wef 8 Jul 25',
          'FTF\u202fwef 8 Jul 25',
          List.filled(255, 'A').join(),
        ]) {
          expect(validator(value), isNull, reason: 'Rejected: $value');
        }
        for (final value in [
          List.filled(256, 'A').join(),
          List.filled(256, ' ').join(),
          'line\nbreak',
          'trailing newline\n',
          'tab\there',
          'invalid<character>',
        ]) {
          expect(validator(value), isNotNull, reason: 'Accepted: $value');
        }
      }
    },
  );

  testWidgets(
    'individual remark edit commits spaces and supported punctuation',
    (tester) async {
      String? savedValue;
      var hasFocus = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return WgtViewEditField(
                    width: 600,
                    labelText: 'Remark',
                    originalValue: 'FTFwef8Jul25to7Jul28',
                    hasFocus: hasFocus,
                    onFocus: (focused) => setState(() => hasFocus = focused),
                    validator: editValidator,
                    onSetValue: (value) async {
                      savedValue = value;
                      return <String, dynamic>{'message': 'Saved'};
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      const remark = 'FTF wef 8 Jul 25 (A/B) - C & D, note_1: OK';
      await tester.enterText(find.byType(TextField), remark);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(savedValue, remark);
      expect(find.text('Saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'individual remark edit blocks values longer than 255 characters',
    (tester) async {
      var saved = false;
      var hasFocus = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return WgtViewEditField(
                    width: 600,
                    originalValue: 'Original remark',
                    hasFocus: hasFocus,
                    onFocus: (focused) => setState(() => hasFocus = focused),
                    validator: editValidator,
                    onSetValue: (value) async {
                      saved = true;
                      return <String, dynamic>{};
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        List.filled(256, 'A').join(),
      );
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(saved, isFalse);
      expect(find.textContaining('length 1-255'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

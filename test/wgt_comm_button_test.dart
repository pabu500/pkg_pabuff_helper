import 'dart:async';

import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('async completion is safe after the button is disposed',
      (tester) async {
    final completion = Completer<void>();
    late StateSetter updateHost;
    var showButton = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return showButton
                    ? WgtCommButton(
                        label: 'Create',
                        onPressed: () => completion.future,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Create'));
    await tester.pump();

    updateHost(() {
      showButton = false;
    });
    await tester.pump();

    completion.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

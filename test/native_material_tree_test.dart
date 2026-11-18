import 'package:buff_helper/pag_helper/def_helper/def_tree.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_tree_element.dart';
import 'package:flutter_fancy_tree_view2/flutter_fancy_tree_view2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('folder button accepts material_ui styles without a bridge', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderButton(
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(foregroundColor: Colors.green),
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FolderButton));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shared tree tile expands and collapses without a legacy wrapper',
    (tester) async {
      final root = PagTreeNode(
        parent: null,
        name: 'site',
        label: 'Site',
        child: null,
        treePartType: PagTreePartType.site,
        level: 0,
      );
      root.children.add(
        PagTreeNode(
          parent: root,
          name: 'meter',
          label: 'Meter',
          child: null,
          treePartType: PagTreePartType.location,
          level: 1,
        ),
      );
      final controller = TreeController<PagTreeNode>(
        roots: [root],
        childrenProvider: (node) => node.children,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedTreeView<PagTreeNode>(
              treeController: controller,
              nodeBuilder: (context, entry) =>
                  PagTreeTile(entry: entry, match: null, searchPattern: null),
            ),
          ),
        ),
      );
      expect(find.text('Meter'), findsNothing);
      await tester.tap(find.byKey(GlobalObjectKey(root)));
      await tester.pumpAndSettle();
      expect(find.text('Meter'), findsOneWidget);
      await tester.tap(find.byKey(GlobalObjectKey(root)));
      await tester.pumpAndSettle();
      expect(find.text('Meter'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

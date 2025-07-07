import 'package:buff_helper/pag_helper/def_helper/def_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
// import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_drawing/path_drawing.dart';

class PagTreeNode {
  PagTreeNode({
    required this.parent,
    required this.name,
    required this.label,
    required this.child,
    required this.treePartType,
    required this.level,
    this.bubbleInfo = const {},
    Iterable<PagTreeNode>? children,
  }) : children = <PagTreeNode>[...?children];

  final PagTreeNode? parent;
  final String name;
  String label;
  final int level;
  final PagTreePartType treePartType;
  final dynamic child;
  final Map<String, dynamic> bubbleInfo;

  final List<PagTreeNode> children;
}

class TreeTile extends StatefulWidget {
  const TreeTile({
    super.key,
    required this.entry,
    required this.match,
    required this.searchPattern,
    this.getNodeWidget,
    this.leafTreePartType,
    this.indent = 13,
  });

  final TreeEntry<PagTreeNode> entry;
  final TreeSearchMatch? match;
  final Pattern? searchPattern;
  final Widget Function(PagTreeNode)? getNodeWidget;
  final PagTreePartType? leafTreePartType;
  final double indent;

  @override
  State<TreeTile> createState() => _TreeTileState();
}

class _TreeTileState extends State<TreeTile> {
  late InlineSpan titleSpan;

  TextStyle? dimStyle;
  TextStyle? highlightStyle;

  late IndentGuide guide = IndentGuide.connectingLines(
    indent: widget.indent,
    color: Theme.of(context).colorScheme.outline.withAlpha(200),
    thickness: 1.2,
    origin: 0.96,
    strokeCap: StrokeCap.square,
    pathModifier: getPathModifierFor(LineStyle.dotted),
    roundCorners: false,
    connectBranches: false,
  );

  bool get shouldShowBadge =>
      !widget.entry.isExpanded && (widget.match?.subtreeMatchCount ?? 0) > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setupTextStyles();
    titleSpan = buildTextSpan();
  }

  @override
  void didUpdateWidget(covariant TreeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchPattern != widget.searchPattern ||
        oldWidget.entry.node.label != widget.entry.node.label) {
      titleSpan = buildTextSpan();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isBranch = widget.entry.node.children.isNotEmpty;
    return TreeIndentation(
      guide: guide,
      entry: widget.entry,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBranch)
            InkWell(
              key: GlobalObjectKey(widget.entry.node),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: widget.entry.isExpanded
                    ? Icon(Symbols.keyboard_arrow_up,
                        size: 15, color: Theme.of(context).hintColor)
                    : Icon(Symbols.keyboard_arrow_down,
                        size: 15, color: Theme.of(context).hintColor),
              ),
              onTap: () => TreeViewScope.of<PagTreeNode>(context)
                ..controller.toggleExpansion(widget.entry.node),
            ),
          if (shouldShowBadge)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Badge(
                label: Text('${widget.match?.subtreeMatchCount}'),
              ),
            ),
          Flexible(
            child: Padding(
                padding: EdgeInsets.only(left: isBranch ? 0 : 8),
                child: Tooltip(
                  message: widget.entry.node.name,
                  waitDuration: const Duration(milliseconds: 500),
                  child: widget.getNodeWidget?.call(widget.entry.node) ??
                      Text.rich(titleSpan),
                )),
          ),
        ],
      ),
    );
  }

  void setupTextStyles() {
    final TextStyle style = DefaultTextStyle.of(context).style;
    // final Color highlightColorX = Colors.red; //Theme.of(context).colorScheme.primary;
    highlightStyle = style.copyWith(
      color: Colors.red, //highlightColorX,
      decorationColor: Colors.red, //highlightColorX,
      decoration: TextDecoration.underline,
    );
    dimStyle = style.copyWith(color: style.color?.withAlpha(128));
  }

  InlineSpan buildTextSpan() {
    final String title = widget.entry.node.label;

    if (widget.searchPattern == null) {
      return TextSpan(text: title);
    }

    final List<InlineSpan> spans = <InlineSpan>[];
    bool hasAnyMatches = false;

    title.splitMapJoin(
      widget.searchPattern!,
      onMatch: (Match match) {
        hasAnyMatches = true;
        spans.add(TextSpan(text: match.group(0)!, style: highlightStyle));
        return '';
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(text: text));
        return '';
      },
    );

    if (hasAnyMatches) {
      return TextSpan(children: spans);
    }

    return TextSpan(text: title, style: dimStyle);
  }
}

enum LineStyle {
  dashed('Dashed'),
  dotted('Dotted'),
  solid('Solid'),
  ;

  const LineStyle(this.title);
  final String title;
}

Path Function(Path)? getPathModifierFor(LineStyle lineStyle) {
  return switch (lineStyle) {
    LineStyle.dashed => (Path path) => dashPath(
          path,
          dashArray: CircularIntervalList(const [6, 4]),
          dashOffset: const DashOffset.absolute(6 / 4),
        ),
    LineStyle.dotted => (Path path) => dashPath(
          path,
          dashArray: CircularIntervalList(const [0.5, 3.5]),
          dashOffset: const DashOffset.absolute(0.5 * 3.5),
        ),
    LineStyle.solid => null,
  };
}

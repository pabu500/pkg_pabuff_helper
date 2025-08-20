import 'package:flutter/material.dart';

class WgtPagListTile extends StatefulWidget {
  const WgtPagListTile({
    super.key,
    required this.index,
    // this.globalKey,
    required this.tileWidgetList,
    this.decor,
    // required this.builder,
    // this.onUpdate,
    this.regFresh,
  });

  final int index;
  final List<Widget> tileWidgetList;
  final BoxDecoration? decor;
  // final GlobalKey? globalKey;
  // final Function(BuildContext, void Function() refresh) builder;
  final Function? regFresh;

  @override
  State<WgtPagListTile> createState() => _WgtPagListTileState();
}

class _WgtPagListTileState extends State<WgtPagListTile> {
  late final BoxDecoration defaultDecor = BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: Theme.of(context).hintColor.withAlpha(80),
        width: 0.5,
      ),
    ),
  );
  Color? _borderColor;
  TextStyle? _textStyle;
  String? _toolTip;
  Widget? _status;
  late int _iniItems;

  void _refresh({
    Color? borderColor,
    TextStyle? textStyle,
    String? toolTip,
    Widget? statusWidget,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _borderColor = borderColor;
      _textStyle = textStyle;
      _toolTip = toolTip;
      _status = statusWidget;
      if (statusWidget != null) {
        widget.tileWidgetList.removeLast();
        widget.tileWidgetList.add(statusWidget);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    widget.regFresh?.call(widget.index, _refresh);

    _iniItems = widget.tileWidgetList.length;
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration decor = widget.decor ?? defaultDecor;
    return ListTile(
      // minVerticalPadding: -4,
      visualDensity: const VisualDensity(vertical: -4),
      dense: true,
      title: Container(
        decoration: decor,
        child: _borderColor == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: widget.tileWidgetList,
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _borderColor!, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: widget.tileWidgetList,
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class WgtListTile extends StatefulWidget {
  const WgtListTile({
    Key? key,
    required this.index,
    // this.globalKey,
    required this.listItem,
    // required this.builder,
    // this.onUpdate,
    this.regFresh,
  }) : super(key: key);

  final int index;
  final List<Widget> listItem;
  // final GlobalKey? globalKey;
  // final Function(BuildContext, void Function() refresh) builder;
  final Function? regFresh;

  @override
  State<WgtListTile> createState() => _WgtListTileState();
}

class _WgtListTileState extends State<WgtListTile> {
  Color? _borderColor;
  TextStyle? _textStyle;
  String? _toolTip;
  Widget? _status;
  late int _iniItems;

  void refresh({
    Color? borderColor,
    TextStyle? textStyle,
    String? toolTip,
    Widget? status,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _borderColor = borderColor;
      _textStyle = textStyle;
      _toolTip = toolTip;
      _status = status;
      if (status != null) {
        widget.listItem.removeLast();
        widget.listItem.add(status);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.regFresh != null) {
      widget.regFresh!(widget.index, refresh);
    }
    _iniItems = widget.listItem.length;
  }

  @override
  Widget build(BuildContext context) {
    // widget.builder.call(context, refresh);
    return ListTile(
      // minVerticalPadding: -4,
      visualDensity: const VisualDensity(vertical: -4),
      dense: true,
      title: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).hintColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: _borderColor == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: widget.listItem,
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _borderColor!, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: widget.listItem,
                ),
              ),
      ),
    );
  }
}

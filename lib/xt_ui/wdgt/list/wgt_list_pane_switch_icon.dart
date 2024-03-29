import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_material_symbols/flutter_material_symbols.dart';
// import 'package:cupertino_icons/cupertino_icons.dart';

class WgtListPaneIcon extends StatefulWidget {
  WgtListPaneIcon({this.mode = 'list', required this.onToggleMode});

  final String mode;
  final void Function(String) onToggleMode;

  @override
  _WgtListPaneIconState createState() => _WgtListPaneIconState();
}

class _WgtListPaneIconState extends State<WgtListPaneIcon> {
  late String _mode;
  @override
  void initState() {
    _mode = widget.mode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _mode == 'pane' ? 'Switch to list mode' : 'Switch to pane mode',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        child: Icon(
          _mode == 'pane'
              ? CupertinoIcons.square_list
              : CupertinoIcons.sidebar_left,
          size: 21,
          color: Theme.of(context).hintColor,
        ),
        onTap: () {
          setState(() {
            _mode = _mode == 'pane' ? 'list' : 'pane';
          });
          widget.onToggleMode(_mode);
        },
      ),
    );
  }
}

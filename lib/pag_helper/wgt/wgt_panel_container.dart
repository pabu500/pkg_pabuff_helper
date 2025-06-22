import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';

class WgtPanelContainer extends StatefulWidget {
  const WgtPanelContainer({
    super.key,
    required this.loggedInUser,
    this.tileColor,
    required this.onAddPanel,
    required this.onRemovePanel,
  });

  final MdlPagUser loggedInUser;
  final Color? tileColor;
  final Function onAddPanel;
  final Function onRemovePanel;

  @override
  State<WgtPanelContainer> createState() => _WgtPanelContainerState();
}

class _WgtPanelContainerState extends State<WgtPanelContainer> {
  final List<Map<String, dynamic>> panelInfoList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.tileColor ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...buildContainerItemList(),
          verticalSpaceTiny,
        ],
      ),
    );
  }

  List<Widget> buildContainerItemList() {
    List<Widget> tiles = [];

    return tiles;
  }
}

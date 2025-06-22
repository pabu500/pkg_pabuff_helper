import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';

class WgtPagListColumnCustomize extends StatefulWidget {
  const WgtPagListColumnCustomize({
    super.key,
    required this.listController,
    required this.onChanged,
    required this.onSet,
    this.listHeight = 160,
    this.sectionName = '',
  });

  final MdlPagListController listController;
  final Function(bool) onChanged;
  final Function() onSet;
  final double? listHeight;
  final String sectionName;

  @override
  State<WgtPagListColumnCustomize> createState() =>
      _WgtPagListColumnCustomizeState();
}

class _WgtPagListColumnCustomizeState extends State<WgtPagListColumnCustomize> {
  // late final List<Map<String, dynamic>> _listConfig;

  bool _isSet = false;

  @override
  void initState() {
    super.initState();

    // _listConfig = List.from(widget.listConfig);
  }

  //clicking any menu item will close the menu, which is not what we want

  // @override
  // Widget build(BuildContext context) {
  //   return PopupMenuButton(
  //       key: _listResetKey,
  //       icon: Icon(
  //         Icons.settings,
  //         size: 13,
  //         color: Theme.of(context).hintColor,
  //       ),
  //       itemBuilder: (BuildContext context) => getColumnSelection(_listConfig));
  // }

  // List<PopupMenuItem> getColumnSelection(
  //     List<Map<String, dynamic>> listConfig) {
  //   List<PopupMenuItem> columnSelection = [];
  //   for (Map<String, dynamic> configItem in listConfig) {
  //     columnSelection.add(
  //       PopupMenuItem(
  //         child: ListTile(
  //           enabled: false,
  //           onTap: () {},
  //           title: Row(
  //             children: [
  //               Transform.scale(
  //                 scale: 0.8,
  //                 child: Checkbox(
  //                   value: configItem['show'] ?? true,
  //                   onChanged: (value) {
  //                     setState(() {
  //                       configItem['show'] = value;
  //                       _listResetKey = UniqueKey();
  //                     });
  //                   },
  //                 ),
  //               ),
  //               Text(
  //                 configItem['title'],
  //                 style: TextStyle(
  //                     fontSize: 13.5, color: Theme.of(context).hintColor),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //   return columnSelection;
  // }

  void _saveCustomize() {
    if (widget.sectionName.isEmpty) {
      if (kDebugMode) {
        print('sectionName is empty');
      }
      return;
    }
    Map<String, dynamic> colCustomize = {};
    for (MdlListColController colController
        in widget.listController.listColControllerList) {
      colCustomize[colController.colKey] = colController.show;
    }
    saveToSharedPref(widget.sectionName, colCustomize);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: getColumnSelection(),
    );
  }

  Widget getColumnSelection() {
    List<Widget> columnSelection = [];
    for (MdlListColController colController
        in widget.listController.listColControllerList) {
      if (colController.hidden) {
        continue;
      }

      String title = colController.colTitle;
      if (title.isEmpty) {
        continue;
      }
      columnSelection.add(
        Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: colController.show,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    colController.show = value;
                    // widget.onChanged(value);
                  });
                },
              ),
            ),
            Text(
              title,
              style:
                  TextStyle(fontSize: 13.5, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }
    return Wrap(children: [
      verticalSpaceSmall,
      SizedBox(
        height: widget.listHeight,
        child: SingleChildScrollView(
          child: Column(children: [
            ...columnSelection,
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: _isSet
                  ? null
                  : () {
                      _saveCustomize();
                      setState(() {
                        _isSet = true;
                      });
                      widget.onSet();

                      Navigator.of(context).pop();
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _isSet
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Set',
                  style: TextStyle(
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      verticalSpaceSmall,
    ]);
  }
}

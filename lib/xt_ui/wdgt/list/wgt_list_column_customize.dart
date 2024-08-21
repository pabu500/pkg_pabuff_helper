import 'package:flutter/material.dart';

class WgtListColumnCustomize extends StatefulWidget {
  const WgtListColumnCustomize({
    super.key,
    required this.listConfig,
    required this.onChanged,
    required this.onReset,
  });

  final List<Map<String, dynamic>> listConfig;
  final Function(bool) onChanged;
  final Function() onReset;

  @override
  State<WgtListColumnCustomize> createState() => _WgtListColumnCustomizeState();
}

class _WgtListColumnCustomizeState extends State<WgtListColumnCustomize> {
  late final List<Map<String, dynamic>> _listConfig;

  UniqueKey? _listResetKey;

  @override
  void initState() {
    super.initState();

    _listConfig = List.from(widget.listConfig);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: getColumnSelection(),
    );
  }

  Widget getColumnSelection() {
    List<Widget> columnSelection = [];
    for (Map<String, dynamic> configItem in _listConfig) {
      if (configItem['hidden'] == true) {
        continue;
      }
      columnSelection.add(
        Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: configItem['show'] ?? true,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    configItem['show'] = value;
                    widget.onChanged(value);
                  });
                },
              ),
            ),
            Text(
              configItem['title'],
              style:
                  TextStyle(fontSize: 13.5, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: columnSelection,
      ),
    );
  }
}

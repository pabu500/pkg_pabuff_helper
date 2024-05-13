import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// import '../service/comm/local_storage.dart';

Widget getCollapsedBar({
  required BuildContext context,
  double? width,
  double? height,
  required String sectionName,
  required String panelTitle,
  required String panelName,
  required Function onTap,
  required Function saveToSharedPref,
  Widget? centerWidget,
  Color? color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0),
    child: Container(
      height: height ?? 21,
      width: width,
      decoration: BoxDecoration(
        color: color ??
            (Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).cardColor
                : Colors.grey.shade600),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(1, 3), // changes position of shadow
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () {
                  onTap();
                  saveToSharedPref('${sectionName}_${panelName}_viz', true);
                },
                child: Icon(
                  Symbols.expand_circle_down,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: centerWidget ??
                Text(
                  panelTitle,
                  style: TextStyle(
                    fontSize: (height ?? 21) < 30 ? 13 : 15,
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 1,
                ),
          ),
        ],
      ),
    ),
  );
}

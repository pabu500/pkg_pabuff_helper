import 'package:buff_helper/xt_ui/wdgt/wgt_popup_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget getCopyButton(BuildContext context, String copyValue,
    {double size = 21, String direction = 'right'}) {
  return WgtPopupButton(
    width: size,
    height: size,
    direction: direction,
    popupWidth: 90,
    popupHeight: 30,
    // backgroundColor: Theme.of(context).colorScheme.primary,
    //  Colors.green.shade700,
    popupChild: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
        border: Border.all(
          color: Theme.of(context).hintColor.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).hintColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Align(
        alignment: Alignment.center,
        child: Text('Copied'),
      ),
    ),
    child: Icon(
      Icons.copy,
      color: Theme.of(context).hintColor.withOpacity(0.5),
      size: size,
    ),
    onTap: () {
      Clipboard.setData(ClipboardData(text: copyValue));
    },
  );
}

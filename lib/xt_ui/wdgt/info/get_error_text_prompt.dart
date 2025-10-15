import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

Widget getErrorTextPrompt(
    {required BuildContext context,
    required String errorText,
    String? title,
    double? margin,
    Color? textColor,
    Color? bgColor,
    Color? borderColor}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: margin ?? 5.0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 13.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor ?? Theme.of(context).colorScheme.error,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title != null)
            Text(
              title,
              style: TextStyle(
                color: textColor ?? Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          SelectableText(
            errorText,
            style: TextStyle(
              color: textColor ?? Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget getErrorWidget(
    {required BuildContext context,
    required String errorText,
    String? title,
    double? margin,
    Color? textColor,
    Color? bgColor,
    Color? borderColor}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: margin ?? 5.0),
    child: Tooltip(
      message: errorText,
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 13.0),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.error,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              Text(
                title,
                style: TextStyle(
                  color: textColor ?? Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Icon(Symbols.error,
                color: textColor ?? Theme.of(context).colorScheme.error),
          ],
        ),
      ),
    ),
  );
}

Widget getInfoTextPrompt(
    {required BuildContext context,
    required String infoText,
    String? title,
    double? margin,
    Color? textColor,
    Color? bgColor,
    Color? borderColor}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: margin ?? 5.0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 13.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor ?? Theme.of(context).hintColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(Symbols.info, color: textColor ?? Theme.of(context).hintColor),
          horizontalSpaceSmall,
          Column(
            mainAxisSize: MainAxisSize.min,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (title != null)
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Theme.of(context).hintColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SelectableText(
                infoText,
                style: TextStyle(
                  color: textColor ?? Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

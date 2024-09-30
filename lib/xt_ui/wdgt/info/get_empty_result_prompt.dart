import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

Widget getEmptyResultPrompt(
    {required BuildContext context,
    required String emptyResultText,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title,
              style: TextStyle(
                color: textColor ?? Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            emptyResultText,
            style: TextStyle(
              color: textColor ?? Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget getEmptyResultWidget(
    {required BuildContext context,
    required String emptyResultText,
    String? title,
    double? margin,
    Color? textColor,
    Color? bgColor,
    Color? borderColor}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: margin ?? 5.0),
    child: Tooltip(
      message: emptyResultText,
      waitDuration: const Duration(milliseconds: 500),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title,
                style: TextStyle(
                  color: textColor ?? Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Icon(Symbols.error,
                color: textColor ?? Theme.of(context).hintColor),
          ],
        ),
      ),
    ),
  );
}

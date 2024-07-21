import 'package:flutter/material.dart';

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
          Text(
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

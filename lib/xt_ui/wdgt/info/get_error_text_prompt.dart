import 'package:flutter/material.dart';

Widget getErrorTextPrompt(
    {required BuildContext context,
    required String errorText,
    String? title,
    double? margin}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: margin ?? 5.0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
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
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            errorText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    ),
  );
}

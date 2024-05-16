import 'package:flutter/material.dart';

Widget getEffectiveScopeTag(BuildContext context, String effectiveScopeStr,
    {Color? bgColor, Color? textColor, Offset? offset}) {
  return effectiveScopeStr == 'SG_ALL'
      ? const SizedBox.shrink()
      : Transform.translate(
          offset: offset ?? const Offset(0, 0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            color: bgColor ??
                Theme.of(context).colorScheme.background.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: Text(
                effectiveScopeStr,
                style: TextStyle(
                    color: textColor ??
                        Theme.of(context).hintColor.withOpacity(0.6),
                    fontSize: 11),
              ),
            ),
          ),
        );
}

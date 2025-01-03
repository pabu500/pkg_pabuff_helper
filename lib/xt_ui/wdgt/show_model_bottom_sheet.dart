import 'package:flutter/material.dart';

void xtShowModelBottomSheet(BuildContext context, Widget child,
    {Function? onClosed}) {
  showModalBottomSheet(
    context: context,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
    ),
    showDragHandle: true,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 3),
        child: SizedBox(width: double.infinity, child: child),
      );
    },
  ).whenComplete(() {
    onClosed?.call();
  });
}

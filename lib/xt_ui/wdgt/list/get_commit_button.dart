import 'package:flutter/material.dart';

import '../../style/evs2_colors.dart';

Widget getCommitButton(Function onTap, {String text = 'Commit'}) {
  return InkWell(
    onTap: () {
      onTap();
    },
    child: Container(
      decoration: BoxDecoration(
        color: commitColor,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

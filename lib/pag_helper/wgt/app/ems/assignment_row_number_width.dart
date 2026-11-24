import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../util/string_util.dart';

double getAssignmentRowNumberWidth(BuildContext context, int rowCount) {
  final digitCount = rowCount.toString().length;
  final style = DefaultTextStyle.of(context).style;
  var textWidth = 0.0;
  for (final digit in '0123456789'.split('')) {
    final digitWidth = getStringDisplaySize2(context, digit, style).width;
    textWidth = math.max(textWidth, digitWidth * digitCount);
  }
  return math.max(21.0, textWidth.ceilToDouble() + 1);
}

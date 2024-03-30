import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../util/util.dart';

const Widget horizontalSpaceTiny = SizedBox(width: 5.0);
const Widget horizontalSpaceSmall = SizedBox(width: 10.0);
const Widget horizontalSpaceRegular = SizedBox(width: 18.0);
const Widget horizontalSpaceMedium = SizedBox(width: 25.0);
const Widget horizontalSpaceLarge = SizedBox(width: 50.0);

const Widget verticalSpaceTiny = SizedBox(height: 5.0);
const Widget verticalSpaceSmall = SizedBox(height: 10.0);
const Widget verticalSpaceRegular = SizedBox(height: 18.0);
const Widget verticalSpaceMedium = SizedBox(height: 25.0);
const Widget verticalSpaceLarge = SizedBox(height: 50.0);

// Screen Size helpers

// double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
// double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

// double screenHeightPercentage(BuildContext context, {double percentage = 1}) =>
//     screenHeight(context) * percentage;

double screenWidthPercentage(BuildContext context,
    {double percentage = 1, double max = 500}) {
  double width = screenWidth(context) * percentage;
  width > max ? width = max : width;
  return width;
}

Size? getSize(GlobalKey key) {
  if (key.currentContext == null) return null;
  final box = key.currentContext!.findRenderObject() as RenderBox?;
  if (box == null) return null;
  Size size = box.size;

  // print("size:$size");
  return size;
}

Offset? getPos(GlobalKey key) {
  if (key.currentContext == null) return null;
  final box = key.currentContext!.findRenderObject() as RenderBox?;
  if (box == null) return null;

  Offset pos = box.localToGlobal(Offset.zero);
  if (kDebugMode) {
    print("pos:$pos");
  }
  return pos;
}

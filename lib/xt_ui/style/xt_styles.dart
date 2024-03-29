import 'package:flutter/cupertino.dart';

// Text Styles

// To make it clear which weight we are using, we'll define the weight even for regular
// fonts
const TextStyle heading1Style = TextStyle(
  fontSize: 34,
  fontWeight: FontWeight.w400,
);

const TextStyle heading2Style = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w600,
);

const TextStyle heading3Style = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
);

const TextStyle headlineStyle = TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.w700,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w400,
);

const TextStyle captionStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
);

BoxDecoration panelBoxDecor(Color boarderColor,
    {Color? bgColor, double? radius}) {
  return BoxDecoration(
      color: bgColor,
      border: Border(
        top: BorderSide(
          width: 1.0,
          color: boarderColor,
        ),
        left: BorderSide(
          width: 1.0,
          color: boarderColor,
        ),
        right: BorderSide(
          width: 1.0,
          color: boarderColor,
        ),
        bottom: BorderSide(
          width: 1.0,
          color: boarderColor,
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(radius ?? 5)));
}

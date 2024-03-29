import 'package:flutter/material.dart';

import '../style/xt_colors.dart';
import '../style/xt_styles.dart';

class xtText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign alignment;

  const xtText.headingOne(this.text, {TextAlign align = TextAlign.start})
      : style = heading1Style,
        alignment = align;
  const xtText.headingTwo(this.text, {TextAlign align = TextAlign.start})
      : style = heading2Style,
        alignment = align;
  const xtText.headingThree(this.text, {TextAlign align = TextAlign.start})
      : style = heading3Style,
        alignment = align;
  const xtText.headline(this.text, {TextAlign align = TextAlign.start})
      : style = headlineStyle,
        alignment = align;
  const xtText.subheading(this.text, {TextAlign align = TextAlign.start})
      : style = subheadingStyle,
        alignment = align;
  const xtText.caption(this.text, {TextAlign align = TextAlign.start})
      : style = captionStyle,
        alignment = align;

  xtText.body(this.text,
      {Color color = kcMediumGreyColor, TextAlign align = TextAlign.start})
      : style = bodyStyle.copyWith(color: color),
        alignment = align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: alignment,
    );
  }
}

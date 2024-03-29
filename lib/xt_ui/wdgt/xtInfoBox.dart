import 'package:flutter/material.dart';

import '../style/xt_colors.dart';

class xtInfoBox extends StatelessWidget {
  const xtInfoBox({
    Key? key,
    this.width,
    this.height,
    this.icon,
    this.iconTextSpace = 0.0,
    this.iconOffset = 0.0,
    this.maxLines = 1,
    this.text,
    this.textColor,
    this.boarderColor,
    this.borderRadius,
    // this.fontSize,
    // this.fontstyle,
    this.textStyle,
    this.padding,
    this.superText,
    this.superTextStyle,
    this.isSelectable,
  }) : super(key: key);

  final Widget? icon;
  final double iconTextSpace;
  final double iconOffset;
  final String? text;
  final Color? boarderColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final TextStyle? textStyle;
  // final double? fontSize;
  // final FontStyle? fontstyle;
  final EdgeInsetsGeometry? padding;
  final String? superText;
  final TextStyle? superTextStyle;
  final bool? isSelectable;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return
        // Container(
        //   decoration: BoxDecoration(
        //     border: Border.all(color: boarderColor ?? xtTransParent),
        //     borderRadius: BorderRadius.circular(borderRadius ?? 0),
        //   ),
        //   padding: padding ?? const EdgeInsets.all(8.0),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Transform.translate(
        //         offset: Offset(iconOffset, 0),
        //         child: icon ?? Container(),
        //       ),
        //       SizedBox(width: iconTextSpace),
        //       isSelectable ?? true
        //           ? Flexible(
        //               child: SelectableText.rich(
        //               TextSpan(
        //                 children: [
        //                   TextSpan(
        //                       text:
        //                           text ?? ''), // 'Please enter meter identifier',),
        //                 ],
        //               ),
        //             ))
        //           : Text(
        //               text ?? '',
        //               style: textStyle ??
        //                   TextStyle(
        //                       color: textColor ?? Colors.white,
        //                       fontSize: 17,
        //                       fontStyle: FontStyle.normal),
        //             )
        //     ],
        //   ),
        // );
        Container(
      // width: width,
      decoration: BoxDecoration(
        border: Border.all(color: boarderColor ?? xtTransParent),
        borderRadius: BorderRadius.circular(borderRadius ?? 0),
      ),
      padding: padding ?? const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(iconOffset, 0),
            child: icon ?? Container(),
          ),
          SizedBox(width: iconTextSpace),
          isSelectable ?? true
              ? getContent()
              : Text(
                  text ?? '',
                  style: textStyle ??
                      TextStyle(
                          color: textColor ?? Colors.white,
                          fontSize: 17,
                          fontStyle: FontStyle.normal),
                )
        ],
      ),
    );
  }

  Widget getContent() {
    return Flexible(
      // width: width,
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(text: text ?? '', style: textStyle),
            if (superText != null)
              WidgetSpan(
                child: Transform.translate(
                  offset: const Offset(2.0, -13.0),
                  child: Text(
                    superText!,
                    style: superTextStyle ?? const TextStyle(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        maxLines: maxLines,
      ),
    );
  }
}

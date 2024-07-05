import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../util/string_util.dart';
import 'wgt_popup_button.dart';

class xtKeyValueText extends StatefulWidget {
  //boilerplate
  const xtKeyValueText({
    super.key,
    required this.keyText,
    required this.valueText,
    this.valueStyle,
    this.keyStyle,
    this.keyWidth,
    this.valueWidth,
    this.valueLoadingAnim,
    this.spaceInBetween = 5,
    this.selectable = true,
    this.clickCopy = false,
  });

  final String keyText;
  final String valueText;
  final TextStyle? valueStyle;
  final TextStyle? keyStyle;
  final double? keyWidth;
  final double? valueWidth;
  final double spaceInBetween;
  final Widget? valueLoadingAnim;
  final bool selectable;
  final bool clickCopy;

  @override
  State<xtKeyValueText> createState() => _xtKeyValueTextState();
}

class _xtKeyValueTextState extends State<xtKeyValueText> {
  String _currentFullText = '';
  @override
  void initState() {
    super.initState();

    _currentFullText = widget.valueText;
    // _controller.text = lengthyString(
    //     widget.valueText,
    //     getStringDisplaySize(
    //             widget.originalFullText,
    //             TextStyle(
    //                 fontSize: widget.valueStyle == null
    //                     ? 15
    //                     : widget.valueStyle!.fontSize))
    //         .width
    //         .round());
  }

  @override
  Widget build(BuildContext context) {
    // _controller.text = widget.text;
    final originalText = widget.valueText;
    final fontSize = widget.valueStyle?.fontSize ?? 15.0;
    // final color = _modified ? Colors.amber.shade900 : null;
    String displayText = convertToDisplayString(
        _currentFullText,
        (widget.valueWidth ?? 60),
        widget.valueStyle ?? const TextStyle(fontSize: 15));
    double stringDisplaySize = 1.13 *
        getStringDisplaySize(
                displayText, widget.valueStyle ?? const TextStyle(fontSize: 15))
            .width;
    String tooltipText = '';
    if (displayText != _currentFullText) {
      tooltipText = _currentFullText;
    }
    return (widget.selectable)
        ? SelectableText.rich(
            getContent(context),
            // textAlign: TextAlign.left,
            // textDirection: TextDirection.ltr,
            // showCursor: false,
            // selectionControls: null,
            // autofocus: false,
            // strutStyle: null,
            // textWidthBasis: null,
            // textHeightBehavior: null,
            maxLines: 1,
            // semanticsLabel: null,
          )
        : getNonSelectableContent(context, displayText,
            tooltipText: tooltipText, stringDisplaySize: stringDisplaySize);
  }

  Widget getNonSelectableContent(BuildContext context, String displayText,
      {String tooltipText = '', double stringDisplaySize = 0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: widget.keyWidth,
          child: Text(
            widget.keyText,
            style: widget.keyStyle ??
                TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
          ),
        ),
        SizedBox(
          width: widget.spaceInBetween,
        ),
        widget.valueLoadingAnim == null
            ? SizedBox(
                width: widget.valueWidth,
                child: Tooltip(
                  message: tooltipText,
                  waitDuration: const Duration(milliseconds: 500),
                  child: widget.clickCopy
                      ? WgtPopupButton(
                          width: stringDisplaySize,
                          height: 20,
                          direction: 'right',
                          popupWidth: 90,
                          popupHeight: 30,
                          // backgroundColor: Theme.of(context).colorScheme.primary,
                          //  Colors.green.shade700,
                          popupChild: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withOpacity(0.1),
                              border: Border.all(
                                color: Theme.of(context)
                                    .hintColor
                                    .withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .hintColor
                                      .withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Align(
                              alignment: Alignment.center,
                              child: Text('Copied'),
                            ),
                          ),
                          child: Text(
                            displayText,
                            style: widget.valueStyle ??
                                TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: _currentFullText));
                          },
                        )
                      : Text(
                          widget.valueText,
                          style: widget.valueStyle ??
                              TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                ))
            : widget.valueLoadingAnim!,
      ],
    );
  }

  TextSpan getContent(BuildContext context) {
    return TextSpan(
      text: widget.keyText,
      style: widget.keyStyle ??
          TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
      children: [
        WidgetSpan(
          child: SizedBox(
            width: widget.spaceInBetween,
          ),
        ),
        widget.valueLoadingAnim == null
            ? TextSpan(
                text: widget.valueText,
                style: widget.valueStyle ??
                    TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              )
            : WidgetSpan(
                child: widget.valueLoadingAnim!,
                alignment: PlaceholderAlignment.middle,
              ),
      ],
    );
  }
}

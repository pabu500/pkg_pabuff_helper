import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../../util/string_util.dart';
import '../info/empty_result.dart';
import '../wgt_popup_button.dart';
import 'wgt_edit_commit_list.dart';

//my custom selectable text widget
class Evs2ListText extends StatefulWidget {
  const Evs2ListText({
    super.key,
    required this.originalFullText,
    this.parentListWgt,
    this.style,
    this.textAlign,
    this.textDirection,
    this.showCursor = false,
    this.selectionControls,
    this.autofocus = false,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.maxLines = 1,
    this.semanticsLabel,
    this.textSpan,
    this.width,
    // this.height,
    this.suffix = const [],
    this.clickEditable = false,
    // this.onChanged,
    this.modifiedRow,
    this.modifiedColor,
    this.fieldKey,
    this.flagModified,
    this.uniqueKey,
    this.validator,
    this.colValidator,
    this.rowValidator,
    this.unique,
    this.listValues,
    this.contentPadding,
    this.nonSelectable = false,
    this.clickCopy = false,
    this.forceShowTooltip = false,
    this.mainAixsAlignment,
  });

  final String originalFullText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool showCursor;
  final TextSelectionControls? selectionControls;
  final bool autofocus;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final int maxLines;
  final String? semanticsLabel;
  final TextSpan? textSpan;
  final double? width;
  // final double? height;
  final List<Widget> suffix;
  final bool forceShowTooltip;

  final bool clickEditable;
  // final Function(String)? onChanged;
  final String? fieldKey;
  final Map<String, dynamic>? modifiedRow;
  final Color? modifiedColor;
  final Function(bool)? flagModified;
  // final Function(GlobalKey key)? informParentTableForcus;
  // final Function()? getCurrentFocusKey;
  final WgtEditCommitList? parentListWgt;
  final UniqueKey? uniqueKey;
  final String? Function(String?)? validator;
  final String? Function(String?, Map<String, dynamic> row)? rowValidator;
  final String? Function(String?, List<String>? listValues)? colValidator;
  final bool? unique;
  final List<String>? listValues;
  final EdgeInsets? contentPadding;
  final bool nonSelectable;
  final bool clickCopy;
  final MainAxisAlignment? mainAixsAlignment;

  @override
  State<Evs2ListText> createState() => _Evs2ListTextState();
}

class _Evs2ListTextState extends State<Evs2ListText> {
  final TextEditingController _controller = TextEditingController();
  // GlobalKey _key = GlobalKey();
  bool _editable = false;
  bool _hasFocus = false;
  bool _modified = false;
  String _currentFullText = '';
  late final _modifiedColor;
  // void setModified(bool value) {
  //   setState(() {
  //     _modified = value;
  //   });
  // }

  void _updateList() {
    if (_modified) {
      // bool modified = true;
      if (widget.validator != null) {
        String? errorText = widget.validator!(_controller.text.trim());
        if (errorText != null) {
          _modified = false;
          showSnackBar(context, errorText);
          return;
        }
      }
      if (widget.rowValidator != null) {
        String? errorText =
            widget.rowValidator!(_controller.text.trim(), widget.modifiedRow!);
        if (errorText != null) {
          _modified = false;
          showSnackBar(context, errorText);
          return;
        }
      }
      if (widget.colValidator != null) {
        String? errorText =
            widget.colValidator!(_controller.text.trim(), widget.listValues);
        if (errorText != null) {
          _modified = false;
          showSnackBar(context, errorText);
          return;
        }
      }

      if (widget.modifiedRow == null || widget.fieldKey == null) return;
      _currentFullText = _controller.text.trim();
      widget.modifiedRow![widget.fieldKey!] = _currentFullText;
      if (widget.flagModified != null) {
        widget.flagModified!(true);
      }
      // _changed = false;
      setState(() {
        // _modified = modified;
      });
    }
  }

  void updateModified(bool modified) {
    setState(() {
      _modified = modified;
    });
    // if (!_modified) {
    //   widget.modifiedRow!.remove(widget.fieldKey);
    // }
  }

  @override
  void initState() {
    super.initState();
    _currentFullText = widget.originalFullText;
    // _controller.text = lengthyString(
    //     widget.originalFullText,
    //     getStringDisplaySize(
    //             widget.originalFullText,
    //             TextStyle(
    //                 fontSize:
    //                     widget.style == null ? 15 : widget.style!.fontSize))
    //         .width
    //         .round());

    if (widget.parentListWgt != null) {
      widget.parentListWgt!.regFieldUpdateModified(updateModified);
    }
    _modifiedColor = widget.modifiedColor ?? Colors.amber.shade900;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _controller.text = widget.text;
    final originalText = widget.originalFullText;
    final fontSize = widget.style?.fontSize ?? 15.0;
    // final color = _modified ? Colors.amber.shade900 : null;
    String displayText = convertToDisplayString(_currentFullText, widget.width!,
        widget.style ?? const TextStyle(fontSize: 15));
    _controller.text = displayText;
    double stringDisplaySize = 1.116 *
        getStringDisplaySize(
                displayText, widget.style ?? const TextStyle(fontSize: 15))
            .width;
    String tooltipText = '';
    if (displayText != _currentFullText || widget.forceShowTooltip) {
      tooltipText = _currentFullText;
    }
    return SizedBox(
      // key: _key,
      width: widget.width,
      // height: widget.height,
      child: Row(
        mainAxisAlignment: widget.mainAixsAlignment ?? MainAxisAlignment.start,
        children: [
          widget.nonSelectable
              ? widget.clickCopy
                  ? Tooltip(
                      message: tooltipText,
                      waitDuration: const Duration(milliseconds: 500),
                      child: WgtPopupButton(
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
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.3),
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
                          style: widget.style == null
                              ? TextStyle(
                                  fontSize: fontSize,
                                  color: _modified ? _modifiedColor : null,
                                )
                              : widget.style!.copyWith(
                                  color: _modified ? _modifiedColor : null,
                                ),
                          textAlign: widget.textAlign,
                          textDirection: widget.textDirection,
                          maxLines: widget.maxLines,
                        ),
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _currentFullText));
                        },
                      ),
                    )
                  : Text(
                      _currentFullText,
                      style: widget.style == null
                          ? TextStyle(
                              fontSize: fontSize,
                              color: _modified ? _modifiedColor : null,
                            )
                          : widget.style!.copyWith(
                              color: _modified ? _modifiedColor : null,
                            ),
                      textAlign: widget.textAlign,
                      textDirection: widget.textDirection,
                      maxLines: widget.maxLines,
                    )
              : (widget.clickEditable && _editable)
                  ? Expanded(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          setState(() {
                            _hasFocus = hasFocus;
                            if (!hasFocus) {
                              _editable = false;
                              _updateList();
                            }
                          });
                        },
                        child: TextField(
                          style: widget.style == null
                              ? TextStyle(
                                  fontSize: fontSize,
                                  color: _modified ? _modifiedColor : null,
                                )
                              : widget.style!.copyWith(
                                  color: _modified ? _modifiedColor : null,
                                ),
                          controller: _controller,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: _hasFocus ? true : false,
                            fillColor: Colors.amber.withOpacity(0.25),
                            isDense: true,
                            contentPadding: widget.contentPadding ??
                                const EdgeInsets.all(1),
                          ),
                          autofocus: true,
                          onChanged: (value) {
                            if (value != originalText) {
                              _modified = true;
                            } else {
                              _modified = false;
                            }
                            // _controller.text = value;
                          },
                          // onSubmitted: (value) {
                          //   setState(() => _editable = !_editable);
                          // },
                          onTapOutside: (value) {
                            setState(() {
                              _editable = !_editable;
                              _hasFocus = false;
                              _updateList();
                            });
                          },
                        ),
                      ),
                    )
                  : Tooltip(
                      message: tooltipText,
                      child: SelectableText.rich(
                        TextSpan(
                          text: displayText,
                          // lengthyString(
                          //     _currentFullText,
                          //     getDisplayLength(
                          //         widget.width!,
                          //         widget.style == null
                          //             ? TextStyle(fontSize: 15)
                          //             : widget.style!)),
                          style: widget.style == null
                              ? TextStyle(
                                  fontSize: fontSize,
                                  color: _modified ? _modifiedColor : null,
                                )
                              : widget.style!.copyWith(
                                  color: _modified ? _modifiedColor : null,
                                ),
                          children: widget.textSpan != null
                              ? [widget.textSpan!]
                              : null,
                        ),
                        textAlign: widget.textAlign,
                        textDirection: widget.textDirection,
                        showCursor: widget.showCursor,
                        selectionControls: widget.selectionControls,
                        autofocus: widget.autofocus,
                        strutStyle:
                            widget.strutStyle, //StrutStyle(height: 1.3),
                        textWidthBasis: widget.textWidthBasis,
                        textHeightBehavior: widget.textHeightBehavior,
                        maxLines: widget.maxLines,
                        semanticsLabel: widget.semanticsLabel,
                        onTap: () {
                          setState(() {
                            _editable = !_editable;
                          });
                          _controller.text = _currentFullText;
                        },
                      ),
                    ),
          for (Widget suffix in widget.suffix) suffix,
          // if (widget.suffix != null)
          //   Padding(
          //     padding: const EdgeInsets.only(left: 0.0),
          //     child: widget.suffix!,
          //   ),
          // if (widget.suffix2 != null)
          //   Padding(
          //     padding: const EdgeInsets.only(left: 0.0),
          //     child: widget.suffix2!,
          //   ),
          // Expanded(child: Container()),
        ],
      ),
    );
  }
}

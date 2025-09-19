import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WgtCommButton extends StatefulWidget {
  const WgtCommButton({
    super.key,
    required this.label,
    this.enabled = true,
    this.inComm = false,
    this.width,
    this.hight,
    this.faceColor,
    this.labelStyle,
    this.labelWidget,
    this.onPressed,
    this.onResult,
  });

  final String label;
  final bool enabled;
  final bool? inComm;
  final double? width;
  final double? hight;
  final Color? faceColor;
  final TextStyle? labelStyle;
  final Widget? labelWidget;
  final Function()? onPressed;
  final Function(dynamic)? onResult;

  @override
  State<WgtCommButton> createState() => _WgtCommButtonState();
}

class _WgtCommButtonState extends State<WgtCommButton> {
  bool _isWaiting = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('WgtCommButton: initState');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('WgtCommButton: build');
      print('WgtCommButton: _isWaiting: $_isWaiting');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: !widget.enabled || (widget.onPressed == null)
              ? null
              : () async {
                  // comm could be initiated by onEditComplete, instead of onPressed
                  // in which case the _waiting flag is set by the parent widget by isComm
                  // instead of by this below
                  setState(() {
                    if (kDebugMode) {
                      print('WgtCommButton: onTap _isWaiting');
                    }
                    _isWaiting = true;
                  });
                  try {
                    var result = await widget.onPressed?.call();
                    widget.onResult?.call(result);
                  } catch (e) {
                    if (kDebugMode) {
                      print('WgtCommButton: onTap error: $e');
                    }
                    widget.onResult?.call(e.toString());
                  } finally {
                    setState(() {
                      _isWaiting = false;
                    });
                  }
                },
          child: Container(
            width: widget.width,
            height: widget.hight,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: widget.faceColor ??
                  (widget.enabled
                      ? pagCallToActionFace.withAlpha(230)
                      : pagCallToActionFace.withAlpha(80)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.labelWidget ??
                    Text(
                      widget.label,
                      style: widget.labelStyle ??
                          TextStyle(
                            color: pagCallToActionText ??
                                Theme.of(context).colorScheme.onSecondary,
                            fontSize: 16,
                          ),
                    ),
                if (_isWaiting || (widget.inComm ?? false))
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: WgtPagWait(
                      size: 21,
                      colorA: Theme.of(context).colorScheme.onSecondary,
                    ),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

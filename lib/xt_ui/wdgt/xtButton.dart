import 'package:flutter/material.dart';

import '../style/xt_colors.dart';
import '../util/xt_util_FormCoordinator.dart';
import '../xt_helpers.dart';
import 'xtWait.dart';

enum btnKey { none, mainbutton }

class xtButton extends StatefulWidget {
  xtButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.xtKey,
    this.outlined = false,
    this.outlineColor = kcPrimaryColor,
    this.color = kcPrimaryColor,
    this.shadowColor,
    this.textColor = Colors.white,
    this.textStyle,
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 8,
    // this.errorText,
    // this.destPage = '/',
    this.formCoordinator,
    this.waiting = false,
    this.textSuffix,
  }) : super(key: key);

  final String text;
  final VoidCallback? onPressed;
  final bool? outlined;
  final Color? outlineColor;
  final Color? color;
  final Color? shadowColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final double? borderRadius;
  // String? errorText;
  btnKey? xtKey;
  xtFormCorrdinator? formCoordinator;
  bool waiting = false;
  Widget? textSuffix;

  @override
  State<xtButton> createState() => _xtButtonState();
}

class _xtButtonState extends State<xtButton> {
  String? _errorText;
  bool _wait = false;

  @override
  void initState() {
    super.initState();
    if (widget.formCoordinator != null) {
      if (widget.xtKey != null) {
        widget.formCoordinator!
            .regFieldUpdateErrorText(widget.xtKey!, updateError);

        widget.formCoordinator!.regToggleWait(widget.xtKey!, toggleWait);
      }
    }
  }

  // final String? destPage;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: ElevatedButton(
              style: widget.outlined!
                  ? OutlinedButton.styleFrom(
                      backgroundColor: widget.color,
                      shadowColor: widget.shadowColor,
                      side: BorderSide(color: widget.outlineColor!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius!),
                      ),
                    )
                  : ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      shadowColor: widget.shadowColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius!),
                      ),
                    ),
              onPressed: widget.waiting ? null : widget.onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.text,
                    style: widget.textStyle ??
                        TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: widget.waiting
                        ? xtWait(
                            color: widget.textColor,
                          )
                        : widget.textSuffix ?? Container(),
                  )
                ],
              ),
            ),
          ),
          if (_wait)
            Transform.translate(
              offset:
                  Offset(getSize(widget.key as GlobalKey)!.width * 0.17, -33),
              child: xtWait(
                color: Colors.white,
              ),
            ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(_errorText!,
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 17,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  void updateError(String? error) {
    setState(() {
      _errorText = error;
    });
  }

  void toggleWait(bool wait) {
    setState(() {
      _wait = wait;
    });
  }
}

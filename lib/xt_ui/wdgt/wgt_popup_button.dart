import 'package:flutter/material.dart';

class WgtPopupButton extends StatelessWidget {
  const WgtPopupButton({
    Key? key,
    // this.buttonKey,
    required this.child,
    required this.width,
    required this.height,
    required this.popupWidth,
    required this.popupHeight,
    required this.popupChild,
    this.backgroundColor,
    this.direction,
    this.onHover,
    this.onTap,
    this.disabled,
    this.xOffset = 0,
    this.center = false,
  }) : super(key: key);

  // final GlobalKey buttonKey = GlobalKey();
  final Widget child;
  final double width;
  final double height;
  final double popupWidth;
  final double popupHeight;
  final Widget popupChild;
  final Color? backgroundColor;
  final String? direction;
  final Function()? onTap;
  final Function(bool val)? onHover;
  final bool? disabled;
  final double xOffset;
  final bool center;

  @override
  Widget build(BuildContext context) {
    GlobalKey buttonKey = GlobalKey();

    return InkWell(
      onTap: (disabled != null && disabled!)
          ? null
          : () {
              if (onTap != null) {
                onTap!();
              }
              final renderBox =
                  buttonKey.currentContext?.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);

              bool toCloseToBottom = false;
              //check if the popup is too close to the bottom of the screen
              if (position.dy + popupHeight >
                  MediaQuery.of(context).size.height) {
                toCloseToBottom = true;
              }
              double vertialOffset = 0;
              if (toCloseToBottom) {
                vertialOffset = popupHeight;
              }

              showDialog(
                context: context,
                builder: (context) {
                  //offset between center of the screen and the button
                  late Offset offset;

                  if (direction == null || direction == 'right') {
                    offset = Offset(
                        position.dx -
                            MediaQuery.of(context).size.width / 2 +
                            popupWidth / 2 +
                            width / 2 +
                            xOffset,
                        position.dy -
                            MediaQuery.of(context).size.height / 2 +
                            popupHeight / 2 +
                            height / 2 -
                            vertialOffset);
                  } else {
                    offset = Offset(
                        position.dx -
                            MediaQuery.of(context).size.width / 2 -
                            popupWidth / 2 +
                            xOffset,
                        // -width / 2,
                        position.dy -
                            MediaQuery.of(context).size.height / 2 +
                            popupHeight / 2 +
                            height / 2 -
                            vertialOffset);
                  }

                  return Transform.translate(
                    offset: center ? Offset.zero : offset,
                    child: Dialog(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          Container(
                            width: popupWidth,
                            height: popupHeight,
                            decoration: BoxDecoration(
                              color: backgroundColor ??
                                  Theme.of(context)
                                      .scaffoldBackgroundColor
                                      .withOpacity(0.8),
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
                            child: popupChild,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
      onHover: onHover,
      child: SizedBox(
        width: width,
        height: height,
        key: buttonKey,
        child: child,
      ),
    );
  }
}

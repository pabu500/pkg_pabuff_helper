import 'package:flutter/material.dart';

class xtWgtPopupButton extends StatelessWidget {
  const xtWgtPopupButton({
    Key? key,
    // this.buttonKey,
    required this.child,
    this.width,
    this.height,
    this.xOffset,
    required this.popupWidth,
    required this.popupHeight,
    this.flexHeight,
    required this.popupChild,
    this.direction,
    this.onHover,
    this.disabled = false,
    this.bgColor,
    this.iniOffset,
  }) : super(key: key);

  // final GlobalKey buttonKey = GlobalKey();
  final Widget child;
  final double? width;
  final double? height;
  final double? xOffset;
  final double popupWidth;
  final double popupHeight;
  final bool? flexHeight;
  final Widget popupChild;
  final String? direction;
  final Function(bool val)? onHover;
  final bool disabled;
  final Color? bgColor;
  final Offset? iniOffset;

  @override
  Widget build(BuildContext context) {
    GlobalKey buttonKey = GlobalKey();
    double width = this.width ?? 35;
    double height = this.height ?? 35;

    return InkWell(
      onTap: disabled
          ? null
          : () {
              final renderBox =
                  buttonKey.currentContext?.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);

              bool tooCloseToBottom = false;
              //check if the popup is too close to the bottom of the screen
              if (position.dy + popupHeight >
                  MediaQuery.of(context).size.height) {
                tooCloseToBottom = true;
              }
              double vertialOffset = 0;
              if (tooCloseToBottom) {
                vertialOffset = popupHeight;
              }

              bool toRight = direction == null || direction == 'right';
              bool tooCloseToRight = false;
              //check if the popup is too close to the right of the screen
              if (position.dx + popupWidth >
                  MediaQuery.of(context).size.width) {
                tooCloseToRight = true;
              }
              bool tooCloseToLeft = false;
              //check if the popup is too close to the left of the screen
              if (!toRight) {
                if (position.dx - popupWidth < 0) {
                  tooCloseToLeft = true;
                }
              }
              double horizontalOffset = 0;
              if (toRight) {
                if (tooCloseToRight) {
                  horizontalOffset = -popupWidth;
                }
                if (tooCloseToLeft) {
                  horizontalOffset = popupWidth;
                }
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
                              horizontalOffset +
                              (xOffset == null ? 0 : xOffset!),
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
                              horizontalOffset +
                              // -width / 2,
                              (xOffset == null ? 0 : xOffset!),
                          position.dy -
                              MediaQuery.of(context).size.height / 2 +
                              popupHeight / 2 +
                              height / 2 -
                              vertialOffset);
                    }

                    return Transform.translate(
                      offset: iniOffset ?? offset,
                      child: Dialog(
                        backgroundColor: bgColor,
                        child: SizedBox(
                          width: popupWidth,
                          height: flexHeight == null
                              ? popupHeight
                              : flexHeight!
                                  ? null
                                  : popupHeight,
                          child: popupChild,
                        ),
                        //     Expanded(
                        //   child: Container(
                        //     width: 100,
                        //     height: 100,
                        //     color: Colors.red,
                        //   ),
                        // ),
                      ),
                    );
                  });
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

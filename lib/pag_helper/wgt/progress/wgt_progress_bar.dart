import 'package:buff_helper/xt_ui/xt_ui.dart';
import 'package:flutter/material.dart';

class WgtProgressBar extends StatefulWidget {
  const WgtProgressBar({
    super.key,
    required this.width,
    required this.high,
    required this.progress,
    this.progressDots = 3,
    this.loadingMessage = 'Loading',
  });

  final double width;
  final double high;
  final double progress;
  final int progressDots;
  final String loadingMessage;

  @override
  State<WgtProgressBar> createState() => _WgtProgressBarState();
}

class _WgtProgressBarState extends State<WgtProgressBar> {
  double _progress = 0;
  String _loadingMessage = 'Loading';
  int _loadingDots = 0;

  @override
  Widget build(BuildContext context) {
    _progress = widget.progress;
    _loadingMessage = '${widget.loadingMessage}...';
    _loadingDots = widget.progressDots;

    return getProcessInfo();
  }

  Widget getProcessInfo() {
    double width = 200;
    double high = 21;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: width - 18,
            child: Text(
              _loadingMessage.length < 3
                  ? _loadingMessage
                  : _loadingMessage.substring(
                      0, _loadingMessage.length - (3 - _loadingDots)),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
        verticalSpaceTiny,
        getProcessBar(context, width, high, _progress),
      ],
    );
  }

  Widget getProcessBar(
      BuildContext context, double width, double high, double progress) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          width: width,
          height: high,
          decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(1, 3), // changes position of shadow
              ),
            ],
          ),
        ),
        SizedBox(
          width: width * progress / 100,
          child: Container(
            height: high,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(200),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: const Offset(1, 3), // changes position of shadow
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtConfirmBox extends StatefulWidget {
  const WgtConfirmBox({
    super.key,
    this.title = 'Confirm',
    this.contentWidget,
    this.keyInConfirmStrList = const [],
    required this.onConfirm,
    this.opName = '',
    this.itemCount = 0,
    this.onEnableConfirm,
    this.message1,
    this.message2,
  });

  final String title;
  final Widget? contentWidget;
  final Function onConfirm;
  final String opName;
  final int itemCount;
  final List<String> keyInConfirmStrList;
  final Function? onEnableConfirm;
  final String? message1;
  final String? message2;

  @override
  State<WgtConfirmBox> createState() => _WgtConfirmBoxState();
}

class _WgtConfirmBoxState extends State<WgtConfirmBox> {
  bool _isConfirmed = false;
  final List<Map<String, dynamic>> _isKeyInMatch = [];

  @override
  void initState() {
    super.initState();
    if (widget.keyInConfirmStrList.isEmpty) {
      _isConfirmed = true;
    } else {
      int i = 0;
      for (var key in widget.keyInConfirmStrList) {
        _isKeyInMatch.add({
          '${key}_${i++}': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        // style: TextStyle(color: commitColor, fontWeight: FontWeight.bold),
      ),
      content: getContentWidget(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isConfirmed
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color:
                  _isConfirmed ? commitColor : Theme.of(context).disabledColor,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget getContentWidget() {
    if (widget.contentWidget != null) {
      return widget.contentWidget!;
    }

    return widget.keyInConfirmStrList.isEmpty
        ? getDefualtContent()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              getDefualtContent(),
              verticalSpaceSmall,
              Text(widget.message1 ??
                  'This operation has major implications on the system'),
              verticalSpaceSmall,
              Text(widget.message2 ??
                  'It\'s recommended to double check before proceeding'),
              verticalSpaceSmall,
              Text(
                'To proceed, please enter ${widget.keyInConfirmStrList.join(', ')}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var key in widget.keyInConfirmStrList)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: key,
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onChanged: (value) {
                            final index = widget.keyInConfirmStrList
                                .indexWhere((element) => element == key);
                            String matchStr = '${key}_$index';
                            if (value == key) {
                              setState(() {
                                _isKeyInMatch[index][matchStr] = true;
                              });

                              if (_isKeyInMatch.every((element) =>
                                  element.values.every((element) => element))) {
                                setState(() {
                                  _isConfirmed = true;
                                });

                                if (widget.onEnableConfirm != null) {
                                  widget.onEnableConfirm!(true);
                                }
                              }
                            } else {
                              setState(() {
                                _isKeyInMatch[index][matchStr] = false;
                                _isConfirmed = false;
                              });

                              if (widget.onEnableConfirm != null) {
                                widget.onEnableConfirm!(false);
                              }
                            }
                            // if (value == key) {
                            //   setState(() {
                            //     _isConfirmed = true;
                            //   });

                            //   if (widget.onEnableConfirm != null) {
                            //     widget.onEnableConfirm!(true);
                            //   }
                            // } else {
                            //   setState(() {
                            //     _isConfirmed = false;
                            //   });

                            //   if (widget.onEnableConfirm != null) {
                            //     widget.onEnableConfirm!(false);
                            //   }
                            // }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
  }

  Widget getDefualtContent() {
    return Text.rich(
      TextSpan(
        text: 'Confirm ',
        children: [
          TextSpan(
            text: '${widget.opName} ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: commitColor,
            ),
          ),
          const TextSpan(
            text: ' for ',
          ),
          TextSpan(
            text: '${widget.itemCount} ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: commitColor,
            ),
          ),
          TextSpan(
            text: widget.itemCount > 1 ? 'items?' : 'item?',
          ),
        ],
      ),
    );
  }
}

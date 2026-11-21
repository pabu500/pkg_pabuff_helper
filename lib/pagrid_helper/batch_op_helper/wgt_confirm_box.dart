import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:material_ui/material_ui.dart';

class WgtConfirmBox extends StatefulWidget {
  const WgtConfirmBox({
    super.key,
    this.title = 'Confirm',
    this.titleWidget,
    this.contentWidget,
    this.footerWidget,
    this.keyInConfirmStrList = const [],
    required this.onConfirm,
    this.opName = '',
    this.itemCount = 0,
    this.onEnableConfirm,
    this.confirmEnabled = true,
    this.confirmResult,
    this.confirmLabel = 'Confirm',
    this.showCancel = true,
    this.message1,
    this.message2,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? contentWidget;

  /// Extra content below the standard confirmation summary and inputs.
  final Widget? footerWidget;
  final Function onConfirm;
  final String opName;
  final int itemCount;
  final List<String> keyInConfirmStrList;
  final Function? onEnableConfirm;

  /// Additional validation supplied by the confirmation content.
  final bool confirmEnabled;

  /// Result returned to callers awaiting the dialog route.
  final Object? confirmResult;
  final String confirmLabel;
  final bool showCancel;
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
        _isKeyInMatch.add({'${key}_${i++}': false});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.titleWidget ?? Text(widget.title),
      content: getContentWidget(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      actions: [
        if (widget.showCancel)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        TextButton(
          onPressed: _isConfirmed && widget.confirmEnabled
              ? () {
                  Navigator.of(context).pop(widget.confirmResult);
                  widget.onConfirm();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: _isConfirmed && widget.confirmEnabled
                  ? commitColor
                  : Theme.of(context).disabledColor,
            ),
            child: Text(
              widget.confirmLabel,
              style: const TextStyle(color: Colors.white),
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

    final content = widget.keyInConfirmStrList.isEmpty
        ? getDefualtContent()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              getDefualtContent(),
              verticalSpaceSmall,
              Text(
                widget.message1 ??
                    'This operation has major implications on the system',
              ),
              verticalSpaceSmall,
              Text(
                widget.message2 ??
                    'It\'s recommended to double check before proceeding',
              ),
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
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onChanged: (value) {
                            final index = widget.keyInConfirmStrList.indexWhere(
                              (element) => element == key,
                            );
                            String matchStr = '${key}_$index';
                            if (value == key) {
                              setState(() {
                                _isKeyInMatch[index][matchStr] = true;
                              });

                              if (_isKeyInMatch.every(
                                (element) =>
                                    element.values.every((element) => element),
                              )) {
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
    if (widget.footerWidget == null) return content;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content, verticalSpaceSmall, widget.footerWidget!],
      ),
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
          const TextSpan(text: ' for '),
          TextSpan(
            text: '${widget.itemCount} ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: commitColor,
            ),
          ),
          TextSpan(text: widget.itemCount > 1 ? 'items?' : 'item?'),
        ],
      ),
    );
  }
}

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WgtViewEditField extends StatefulWidget {
  const WgtViewEditField({
    super.key,
    required this.originalValue,
    required this.onSetValue,
    required this.onFocus,
    // this.onSuffixTap,
    this.validator,
    this.editable = true,
    // this.errorText,
    this.labelText,
    this.hintText,
    this.width = 200,
    this.textStyle,
    this.hasFocus = false,
    this.showCommitted = true,
    this.committedMessage = 'Change committed',
    this.suffixes = const [],
    this.showLabel = false,
    this.labelWidth = 100,
    this.required = true,
    this.minLength,
    this.onPullRefVal,
    this.showCopy = false,
    this.useDatePicker = false,
  });

  final String originalValue;
  final double width;
  final String? labelText;
  final String? hintText;
  final TextStyle? textStyle;
  final Function(String) onSetValue;
  final Function(bool) onFocus;
  final String? Function(String? val)? validator;
  final bool hasFocus;
  // final String? errorText;
  final bool? showCommitted;
  final String committedMessage;
  final List<Map<String, dynamic>> suffixes;
  final bool showLabel;
  final double labelWidth;
  final bool editable;
  final bool required;
  final int? minLength;
  final Function? onPullRefVal;
  final bool showCopy;
  final bool useDatePicker;

  @override
  State<WgtViewEditField> createState() => _WgtViewEditFieldState();
}

class _WgtViewEditFieldState extends State<WgtViewEditField> {
  bool _isEditing = false;
  bool _isSubmitting = false;
  String _errorText = '';
  bool? _showCommitted;
  late String _committedMessage;

  final TextEditingController _controller = TextEditingController();

  String _refVal = '';

  UniqueKey? _popupKey;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? d = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      initialDate: DateTime.now(),
      firstDate: /*widget.defaultFirstDate ??*/ DateTime(2023),
      lastDate: /*widget.defaultLastDate ??*/
          DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) {
      setState(() {
        _controller.text = getDateTimeStrFromDateTime(d);
        // _selectedDateTime = d;
      });
      // widget.onDateChanged?.call(d);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.originalValue;
    _committedMessage = widget.committedMessage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.symmetric(vertical: 3, horizontal: 8);
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showLabel)
                SizedBox(
                  width: widget.labelWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: InkWell(
                            onTap: widget.onPullRefVal == null ||
                                    _isEditing ||
                                    _refVal.isNotEmpty
                                ? null
                                : () async {
                                    _refVal = await widget.onPullRefVal?.call();
                                    setState(() {});
                                  },
                            child: Text(
                              widget.labelText ?? '',
                              style: TextStyle(
                                color: widget.onPullRefVal == null ||
                                        _isEditing ||
                                        _refVal.isNotEmpty
                                    ? Theme.of(context).hintColor
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        if (_refVal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: SelectableText.rich(
                              TextSpan(
                                text: _refVal,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: _isEditing && widget.hasFocus
                    ? TextField(
                        controller: _controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          contentPadding: padding,
                          labelText: widget.labelText ?? '',
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(),
                          ),
                          errorText:
                              // _errorText.isNotEmpty
                              //     ? _errorText
                              //     : (widget.errorText ?? '').isNotEmpty
                              //         ? widget.errorText
                              //         : null,
                              _errorText.isNotEmpty ? _errorText : null,
                          errorStyle: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            _errorText = '';
                            _showCommitted = false;
                          });
                        },
                        // onSubmitted: (newValue) {
                        //   setState(() {
                        //     _isEditing = false;
                        //     widget.width = 200;
                        //   });
                        // },
                      )
                    : Container(
                        width: widget.width,
                        padding: padding,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).hintColor,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.originalValue.isEmpty
                                    ? widget.hintText ?? ''
                                    : widget.originalValue,
                                style: widget.textStyle ??
                                    TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).hintColor,
                                    ),
                              ),
                            ),
                            widget.suffixes.isEmpty
                                ? Container()
                                : Row(children: getSuffixes()),
                          ],
                        ),
                      ),
              ),
              _isSubmitting
                  ? Padding(
                      padding: const EdgeInsets.only(left: 13),
                      child: xtWait(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : _isEditing && widget.hasFocus
                      ? Tooltip(
                          message: 'Commit change',
                          waitDuration: const Duration(milliseconds: 500),
                          child: SizedBox(
                            width: 40,
                            child: InkWell(
                              child: Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onTap: () async {
                                _isSubmitting = true;
                                try {
                                  if (_controller.text ==
                                      widget.originalValue) {
                                    setState(() {
                                      _isEditing = false;
                                      _isSubmitting = false;
                                    });
                                    return;
                                  }
                                  String? validated = widget.validator == null
                                      ? null
                                      : widget.validator!(_controller.text);
                                  if (validated != null) {
                                    setState(() {
                                      _errorText = validated;
                                    });
                                    return;
                                  }

                                  Map<String, dynamic> result =
                                      await widget.onSetValue(_controller.text);

                                  bool hasError = false;
                                  if (result['error'] != null) {
                                    hasError = true;
                                  }
                                  if (hasError) {
                                    setState(() {
                                      if (result['error'] is String) {
                                        _errorText = result['error'];
                                      } else if (result['error']
                                          is Map<String, dynamic>) {
                                        _errorText = result['error']
                                                ['status'] ??
                                            result['error']['message'];
                                      }

                                      if (_errorText.isNotEmpty) {
                                        _errorText = _errorText.replaceAll(
                                            'Exception: ', '');
                                        if (_errorText.contains('OQG')) {
                                          if (_errorText
                                              .contains('duplicate key')) {
                                            _errorText = 'Duplicated value';
                                          } else {
                                            _errorText = 'error updating value';
                                          }
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      _errorText = '';
                                      _isEditing = false;
                                      _showCommitted = widget.showCommitted;
                                      _committedMessage = result['message'] ??
                                          'Change committed';
                                    });
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print(e);
                                  }
                                } finally {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              },
                            ),
                          ),
                        )
                      : SizedBox(
                          width: 40,
                          child: !widget.editable
                              ? null
                              : widget.useDatePicker
                                  ? InkWell(
                                      child: const Icon(Icons.calendar_today),
                                      onTap: () {
                                        _selectDate(context);
                                        widget.onFocus(true);

                                        setState(() {
                                          _isEditing = true;
                                          _showCommitted = false;
                                          _controller.text =
                                              widget.originalValue;
                                        });
                                      },
                                    )
                                  : InkWell(
                                      onTap: widget.editable
                                          ? () {
                                              widget.onFocus(true);

                                              setState(() {
                                                _isEditing = true;
                                                _showCommitted = false;
                                                _controller.text =
                                                    widget.originalValue;
                                              });
                                            }
                                          : null,
                                      child: Icon(Icons.edit,
                                          color: Theme.of(context).hintColor),
                                    ),
                        ),
              // horizontalSpaceSmall,
              if (widget.originalValue != _controller.text)
                InkWell(
                  child: Icon(
                    Icons.close,
                    size: 35,
                    color: Theme.of(context).hintColor,
                  ),
                  onTap: () {
                    setState(() {
                      _isEditing = false;
                      _controller.text = widget.originalValue;
                    });
                  },
                ),
              if (widget.showCopy)
                SizedBox(
                    width: 35,
                    child: getCopyButton(context, widget.originalValue,
                        direction: 'left')),
            ],
          ),
          if (_showCommitted ?? false)
            Row(
              children: [
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _committedMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> getSuffixes() {
    List<Widget> suffixes = [];
    int i = 0;
    for (var suffix in widget.suffixes) {
      if (i++ > 0) {
        suffixes.add(horizontalSpaceTiny);
      }
      suffixes.add(
        InkWell(
          onTap: () async {
            setState(() {
              _isSubmitting = true;
            });

            try {
              await Future.delayed(const Duration(milliseconds: 500));
              Map<String, dynamic> result = await suffix['onTap']();

              if (result['error'] != null) {
                setState(() {
                  _errorText = result['error'];
                });
              } else {
                setState(() {
                  _errorText = '';
                  _isEditing = false;
                  _showCommitted = widget.showCommitted;
                  if (result['show_committed'] != null) {
                    _showCommitted = result['show_committed'];
                  }
                  _committedMessage = result['message'] ?? _committedMessage;
                });
              }
            } catch (e) {
              if (kDebugMode) {
                print(e);
              }
            } finally {
              setState(() {
                _isSubmitting = false;
              });
            }
          },
          child: suffix['widget'],
        ),
      );
    }
    return suffixes;
  }
}

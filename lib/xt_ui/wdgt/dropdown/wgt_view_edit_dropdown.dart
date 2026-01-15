import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WgtViewEditDropdown extends StatefulWidget {
  const WgtViewEditDropdown({
    super.key,
    this.dropdownValueListString,
    this.dropdownValueListMap,
    this.originalValue,
    this.originalValueMap,
    required this.onSetValue,
    required this.onFocus,
    required this.hint,
    // this.onSuffixTap,
    this.validator,
    // this.errorText,
    this.labelText,
    this.width = 200,
    this.textStyle,
    this.hasFocus = false,
    this.showCommitted = true,
    this.committedMessage = 'Change committed',
    this.suffixes = const [],
    this.showLabel = false,
    this.labelWidth = 100,
    this.readOnly = false,
  });

  final List<String>? dropdownValueListString;
  final List<Map<String, dynamic>>? dropdownValueListMap;
  final String? originalValue;
  final Map<String, dynamic>? originalValueMap;
  final String hint;
  final double width;
  final String? labelText;
  final TextStyle? textStyle;
  final Function(dynamic) onSetValue;
  final Function(bool) onFocus;
  // final Function? onSuffixTap;
  final bool hasFocus;
  final String? Function(String?)? validator;
  // final String? errorText;
  final bool? showCommitted;
  final String committedMessage;
  final List<Map<String, dynamic>> suffixes;
  final bool showLabel;
  final double labelWidth;
  final bool readOnly;

  @override
  State<WgtViewEditDropdown> createState() => _WgtViewEditDropdownState();
}

class _WgtViewEditDropdownState extends State<WgtViewEditDropdown> {
  bool _isEditing = false;
  bool _isSubmitting = false;
  String _errorText = '';
  bool? _showCommitted;
  late String _committedMessage;
  String? _currentValue;
  Map<String, dynamic>? _currentValueMap;

  late final useMap = widget.dropdownValueListMap != null;

  @override
  void initState() {
    super.initState();
    _committedMessage = widget.committedMessage;
    _currentValue = widget.originalValue;
    _currentValueMap = widget.originalValueMap;

    assert(widget.dropdownValueListString != null ||
        widget.dropdownValueListMap != null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const EdgeInsets _padding =
        EdgeInsets.symmetric(vertical: 8, horizontal: 8);
    return Container(
      width: widget.width,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showLabel)
                SizedBox(
                  width: widget.labelWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: Text(
                        widget.labelText ?? '',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
              IgnorePointer(
                ignoring: widget.readOnly,
                child: useMap
                    ? DropdownButton<Map<String, dynamic>>(
                        alignment: AlignmentDirectional.centerStart,
                        value: _currentValueMap,
                        hint: Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(widget.hint,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context).hintColor))),
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 21,
                        // elevation: 16,
                        style: widget.readOnly
                            ? TextStyle(color: Theme.of(context).hintColor)
                            : TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                        underline: Container(
                            height: 1,
                            color: Theme.of(context).hintColor.withAlpha(75)),
                        onChanged: (Map<String, dynamic>? newValue) {
                          if (newValue == null) {
                            return;
                          }
                          if (newValue == _currentValueMap) {
                            return;
                          }
                          setState(() {
                            _currentValueMap = newValue;
                            _isEditing = true;
                            _showCommitted = false;
                            _errorText = '';
                          });
                          widget.onFocus(true);
                        },
                        items: widget.dropdownValueListMap!
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                                (Map<String, dynamic> value) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: value,
                            child: Text(value['label'] ?? value['title']),
                          );
                        }).toList())
                    : DropdownButton<String>(
                        alignment: AlignmentDirectional.centerStart,
                        value: _currentValue,
                        hint: Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(widget.hint,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context).hintColor))),
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 21,
                        // elevation: 16,
                        style: widget.readOnly
                            ? TextStyle(color: Theme.of(context).hintColor)
                            : TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                        underline: Container(
                            height: 1,
                            color: Theme.of(context).hintColor.withAlpha(75)),
                        onChanged: (String? newValue) {
                          if (newValue == null) {
                            return;
                          }
                          if (newValue == _currentValue) {
                            return;
                          }
                          setState(() {
                            _currentValue = newValue;
                            _isEditing = true;
                            _showCommitted = false;
                            _errorText = '';
                          });
                          widget.onFocus(true);
                        },
                        items: widget.dropdownValueListMap != null
                            ? widget.dropdownValueListMap!
                                .map<DropdownMenuItem<String>>(
                                    (Map<String, dynamic> value) {
                                return DropdownMenuItem<String>(
                                  value: value['value'] ?? value['val'],
                                  child: Text(value['label'] ?? value['title']),
                                );
                              }).toList()
                            : widget.dropdownValueListString!
                                .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                      ),
              ),
              Expanded(child: Container()),
              _isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.only(left: 13),
                      child: WgtPagWait(size: 21),
                    )
                  : _isEditing /*&& widget.hasFocus*/
                      ? Tooltip(
                          message: 'Commit change',
                          waitDuration: const Duration(milliseconds: 500),
                          child: IconButton(
                            // tooltip: 'Commit change',
                            icon: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () async {
                              _isSubmitting = true;
                              try {
                                // if (_controller.text == widget.originalValue) {
                                //   setState(() {
                                //     _isEditing = false;
                                //     _isSubmitting = false;
                                //   });
                                //   return;
                                // }
                                // String? validated = widget.validator == null
                                //     ? null
                                //     : widget.validator!(_controller.text);
                                // if (validated != null) {
                                //   setState(() {
                                //     _errorText = validated;
                                //   });
                                //   return;
                                // }

                                Map<String, dynamic> result =
                                    await widget.onSetValue(useMap
                                        ? _currentValueMap!
                                        : _currentValue!);
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
                                      _errorText = result['error']['status'] ??
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
                                    _committedMessage =
                                        result['message'] ?? 'Change committed';
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
                        )
                      : Container(),
              // horizontalSpaceSmall,
              if (useMap &&
                  (_currentValueMap != widget.originalValueMap &&
                      _currentValueMap != null))
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).hintColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _currentValueMap = widget.originalValueMap;
                    });
                  },
                ),
              if (!useMap &&
                  (_currentValue != widget.originalValue &&
                      _currentValue != null))
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).hintColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _currentValue = widget.originalValue;
                    });
                  },
                )
            ],
          ),
          if (_errorText.isNotEmpty)
            Row(
              children: [
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _errorText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
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
}

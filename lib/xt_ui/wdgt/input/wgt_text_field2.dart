import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../wgt_pag_wait.dart';

class WgtTextField extends StatefulWidget {
  const WgtTextField({
    super.key,
    required this.appConfig,
    required this.onChanged,
    this.controller,
    this.initialValue,
    this.required = false,
    this.minLength,
    this.onTap,
    this.onEditingComplete,
    this.validator,
    this.checkUnique,
    this.uniqueKey,
    this.itemTableName,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.labelText,
    this.hintText,
    this.resetKey,
    this.onUniqueCheck,
    this.onValidate,
    this.onClear,
    this.scanner,
    this.showClearButton = true,
    this.enabled = true,
    this.obscureText = false,
    this.decoration,
    this.isPag = false,
    this.suffix,
  });

  final dynamic appConfig;
  final Function onChanged;
  final TextEditingController? controller;
  final String? initialValue;
  final bool required;
  final int? minLength;
  final Function? onEditingComplete;
  final Function? onTap;
  final Function? validator;
  final Function(dynamic, String, String, String)? checkUnique;
  final String? uniqueKey;
  final String? itemTableName;
  final int maxLines;
  final int? maxLength;
  final String? labelText;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final UniqueKey? resetKey;
  final Function? onUniqueCheck;
  final Function? onValidate;
  final Function? onClear;
  final Widget? scanner;
  final bool showClearButton;
  final bool enabled;
  final bool obscureText;
  final InputDecoration? decoration;
  final bool isPag;
  final Widget? suffix;

  @override
  State<WgtTextField> createState() => _WgtTextFieldState();
}

class _WgtTextFieldState extends State<WgtTextField> {
  final TextEditingController controller = TextEditingController();
  late final TextEditingController _controller;
  // late final FocusNode _focusNode;

  String _errorText = '';
  bool _waiting = false;
  String _checkUniqueResult = '';
  bool _isValidated = true;
  bool _uniqueChecked = false;

  UniqueKey? _resetKey;

  Future<void> checkUnique(
      dynamic appConfig, String field, String val, String table) async {
    if (val.trim().isEmpty) {
      return;
    }
    setState(() {
      _checkUniqueResult = '';
      _waiting = true;
    });
    if (widget.checkUnique == null) {
      return;
    }
    try {
      Map<String, dynamic> result =
          await widget.checkUnique!(widget.appConfig, field, val, table);
      if (result['exists'] != null) {
        bool exists = result['exists'] == true;
        setState(() {
          _checkUniqueResult = exists ? 'taken' : 'available';
          _uniqueChecked = true;
        });
        if (widget.onUniqueCheck != null) {
          widget.onUniqueCheck!(exists);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _waiting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? controller;
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    controller.dispose();
    // _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resetKey != null) {
      if (widget.resetKey != _resetKey) {
        _resetKey = widget.resetKey;
        _controller.text = widget.initialValue ?? '';
        _checkUniqueResult = '';
        _uniqueChecked = false;
        _errorText = '';
      }
    }
    return Focus(
      descendantsAreFocusable: widget.enabled,
      canRequestFocus: widget.enabled,
      onFocusChange: (value) {
        if (!value) {
          widget.onEditingComplete?.call();
          if (_controller.text.trim().isNotEmpty) {
            if (widget.checkUnique != null) {
              if (!_uniqueChecked && _isValidated) {
                assert(widget.itemTableName != null);
                assert(widget.uniqueKey != null);

                checkUnique(widget.appConfig, widget.uniqueKey!,
                    _controller.text, widget.itemTableName!);
              }
            }
          }
        }
      },
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            controller: _controller,
            maxLines: widget.maxLines,
            minLines: 1,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onChanged: (value) {
              setState(() {
                _uniqueChecked = false;
              });
              if (_checkUniqueResult.isNotEmpty) {
                setState(() {
                  _checkUniqueResult = '';
                });
              }
              if (value.isEmpty) {
                if (widget.required) {
                  setState(() {
                    _isValidated = false;
                    _errorText = 'required';
                  });
                  return;
                }
              }
              String? result;
              if (widget.validator != null) {
                _isValidated = false;
                result = widget.validator!(
                  value,
                  // widget.minLength,
                  // widget.required,
                );
                widget.onValidate?.call(result);
              }
              if (result != null) {
                setState(() {
                  _isValidated = false;
                  _errorText = result!;
                });
                return;
              } else {
                setState(() {
                  _isValidated = true;
                  _errorText = '';
                });
              }
              widget.onChanged(value);
            },
            onEditingComplete: () {
              if (!_isValidated) {
                return;
              }
              widget.onEditingComplete?.call();

              if (widget.checkUnique != null) {
                checkUnique(widget.appConfig, widget.uniqueKey!,
                    _controller.text, widget.itemTableName!);
              }
            },
            decoration: widget.decoration ??
                InputDecoration(
                  labelText: widget.labelText,
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).hintColor,
                  ),
                  hintText: widget.hintText,
                  errorText: _errorText.isEmpty ? null : _errorText,
                  hintStyle: TextStyle(
                    // fontSize: 16,
                    color: Theme.of(context).hintColor.withAlpha(130),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: Theme.of(context).hintColor.withAlpha(75),
                    ),
                  ),
                  suffix: getSuffix(),
                ),
          ),
          widget.suffix ?? const SizedBox(),
        ],
      ),
    );
  }

  Widget getSuffix() {
    return _waiting
        ? widget.isPag
            ? WgtPagWait(
                size: 20,
                showCenterSquare: false,
                colorA: Theme.of(context).colorScheme.primary,
              )
            : xtWait(
                color: Theme.of(context).colorScheme.primary,
              )
        : Focus(
            descendantsAreFocusable: false,
            canRequestFocus: false,
            child: _checkUniqueResult == 'available'
                ? const Text(
                    'available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  )
                : _checkUniqueResult == 'taken'
                    ? const Text(
                        'taken',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      )
                    : (_controller.text.isNotEmpty && widget.showClearButton)
                        ? InkWell(
                            child: Icon(
                              Icons.clear,
                              color: Theme.of(context).hintColor,
                            ),
                            onTap: () {
                              setState(() {
                                _controller.text = '';
                                _checkUniqueResult = '';
                                _uniqueChecked = false;
                                _errorText = '';
                                if (widget.onValidate != null) {
                                  widget.onValidate!('');
                                }
                                if (widget.onClear != null) {
                                  widget.onClear!();
                                }
                              });
                            },
                          )
                        : (widget.scanner != null)
                            ? widget.scanner!
                            : const SizedBox(),
          );
  }
}

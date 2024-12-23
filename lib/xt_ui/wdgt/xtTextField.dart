import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pagrid_helper/app_helper/pagrid_app_config.dart';

class xtTextField extends StatefulWidget {
  xtTextField(
      {super.key,
      required this.appConfig,
      this.decoration,
      this.onTap,
      this.onChanged,
      this.onEditingComplete,
      this.obscureText,
      this.doValidate,
      this.onValidate,
      this.requireUnique,
      this.doCommCheckUnique,
      this.tfKey,
      this.formCoordinator,
      this.controller,
      this.initialText,
      // this.formProvider,
      // this.canRequestFocus,
      // this.autofocus,
      this.order,
      this.maxLength,
      this.inputFormatters,
      this.disabled});

  final PaGridAppConfig appConfig;
  InputDecoration? decoration;
  bool? requireUnique;
  Future<String> Function(PaGridAppConfig, Enum, String)? doCommCheckUnique;
  bool? obscureText;
  void Function()? onTap;
  String? Function(String)? onChanged;
  void Function()? onEditingComplete;
  String? Function(String)? doValidate;
  void Function(String?)? onValidate;
  Enum? tfKey;
  // FormProvider? formProvider;
  xtFormCorrdinator? formCoordinator;
  TextEditingController? controller;

  final String? initialText;

  // bool? canRequestFocus;
  // bool? autofocus;
  int? order;
  int? maxLength;
  List<TextInputFormatter>? inputFormatters;
  bool? disabled;

  @override
  _xtTextFieldState createState() => _xtTextFieldState();
}

class _xtTextFieldState extends State<xtTextField> {
  InputDecoration? decoration;
  String? _errorText;
  // Color? errorColor;

  bool _dbwaiting = false;
  bool _dbUnique = false;
  String storedText = '';

  String? suffixType;
  Widget? suffix;

  bool _disabled = false;

  late final TextEditingController _controller;
  // The node used to request the keyboard focus.
  late final FocusNode _focusNode;

  //debug message
  String? _message;

  //will only be called once
  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();

    _focusNode = FocusNode(canRequestFocus: true);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        //if text changed
        if (_controller.text != storedText) {
          suffix = null;
          storedText = _controller.text;

          if (widget.doValidate != null) {
            setState(() {
              _errorText = widget.doValidate!(_controller.text);

              widget.onValidate?.call(_errorText);
            });
            if (widget.formCoordinator != null && widget.tfKey != null) {
              widget.formCoordinator!.formErrors[widget.tfKey!] =
                  _errorText; //update error
            }

            if (_errorText == null &&
                widget.tfKey != null &&
                widget.formCoordinator != null) {
              widget.formCoordinator!.formData[widget.tfKey!] =
                  _controller.text;
            }
            bool requireUnique = widget.requireUnique ?? false;
            if (requireUnique &&
                _controller.text.isNotEmpty &&
                _errorText == null) {
              //filled and validated and db check needed

              if (widget.tfKey != null && widget.doCommCheckUnique != null) {
                checkUnique(widget.appConfig, widget.tfKey!, _controller.text);
              }
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onAfterBuild(context));

    if (widget.decoration != null) {
      decoration =
          widget.decoration!.copyWith(errorText: _errorText, suffix: suffix);
    } else {
      decoration = xtBuildInputDecoration(
        errorText: _errorText,
        suffix: suffix,
      );
    }

    FocusOrder order;
    if (widget.order is num) {
      order = NumericFocusOrder((widget.order as num).toDouble());
    } else {
      order = LexicalFocusOrder(widget.order.toString());
    }

    return Focus(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: FocusTraversalOrder(
        order: order,
        child: _txTextField(
          controller: widget.controller ?? _controller,
          decoration: decoration,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          doValidate: widget.doValidate,
          obscureText: widget.obscureText,
          disabled: _disabled,
          maxLength: widget.maxLength,
          initialText: widget.initialText,
          inputFormatters: widget.inputFormatters,
        ),
      ),
    );
  }

  void clearText() {
    _controller.clear();
  }

  void updateError(String? error) {
    setState(() {
      _errorText = error;
    });
  }

  void toggleDisabled(bool disabled) {
    setState(() {
      _disabled = disabled;
    });
  }

  void saveField() {
    if (widget.tfKey != null) {
      widget.formCoordinator!.formData[widget.tfKey!] = _controller.text.trim();
    }
  }

  // Handles the key events from the RawKeyboardListener and update the
  // _message.
  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    // logKeyMessage(event);

    return event.physicalKey == PhysicalKeyboardKey.keyA
        // ? KeyEventResult.handled
        ? KeyEventResult.ignored
        : KeyEventResult.ignored;
  }

  void logKeyMessage(RawKeyEvent event) {
    setState(() {
      if (event.physicalKey == PhysicalKeyboardKey.keyA) {
        _message = 'Pressed the key next to CAPS LOCK!';
      } else {
        if (kReleaseMode) {
          _message =
              'Not the key next to CAPS LOCK: Pressed 0x${event.physicalKey.usbHidUsage.toRadixString(16)}';
        } else {
          // As the name implies, the debugName will only print useful
          // information in debug mode.
          _message =
              'Not the key next to CAPS LOCK: Pressed ${event.physicalKey.debugName}';
        }
      }
    });
  }

  Future<void> checkUnique(
    PaGridAppConfig appConfig,
    Enum field,
    String val,
    /*Future<String> doCommFunc(Enum fld, String v)*/
  ) async {
    if (widget.doCommCheckUnique == null) {
      return;
    }

    setState(() {
      suffix = txTextInputSuffix('waiting', null);
    });

    var dbresult =
        await widget.doCommCheckUnique!(appConfig, field, val.toLowerCase());

    setState(() {
      if (dbresult == 'available') {
        _dbUnique = true;
        suffix = txTextInputSuffix('available', xtLightGreen1);
        _errorText = null;
      } else {
        _dbUnique = false;
        suffix = null;
        if (dbresult.contains('taken')) {
          _errorText = '${field.name} already used';
        } else {
          _errorText = 'Service Error';
        }
      }
      if (widget.formCoordinator != null && widget.tfKey != null) {
        widget.formCoordinator!.formErrors[widget.tfKey!] = _errorText;
      }
    });

    return;
  }

  onAfterBuild(BuildContext context) {
    _controller.addListener(
      //afer providing a listener,
      //the provided onChanged handler should be called inside the listener
      () {
        if (widget.onChanged != null) {
          setState(() {
            if (_controller.text != storedText) {
              suffix = null;
            }
            _errorText = widget.onChanged!(_controller.text);
            if (widget.formCoordinator != null && widget.tfKey != null) {
              widget.formCoordinator!.formErrors[widget.tfKey!] = _errorText;
            }
          });
        }
      },
    );

    if (widget.formCoordinator != null) {
      if (widget.tfKey != null) {
        widget.formCoordinator!
            .regFieldUpdateErrorText(widget.tfKey!, updateError);
        widget.formCoordinator!
            .regFieldToggleDisabled(widget.tfKey!, toggleDisabled);
        widget.formCoordinator!.regFieldSave(widget.tfKey!, saveField);
        widget.formCoordinator!.regClearText(widget.tfKey!, clearText);

        if (widget.doValidate != null) {
          widget.formCoordinator!
              .regFieldValidator(widget.tfKey!, widget.doValidate!);
        }
        if (widget.requireUnique ?? false) {
          widget.formCoordinator!
              .regFieldCheckUnique(widget.tfKey!, checkUnique);
        }
      }
    }
  }
}

class _txTextField extends StatelessWidget {
  const _txTextField({
    Key? key,
    required this.controller,
    required this.onTap,
    required this.onChanged,
    required this.onEditingComplete,
    required this.doValidate,
    required this.decoration,
    required this.obscureText,
    required this.maxLength,
    required this.disabled,
    required this.initialText,
    required this.inputFormatters,
  }) : super(key: key);

  final TextEditingController controller;
  final InputDecoration? decoration;

  final bool? obscureText;
  final int? maxLength;
  final bool? disabled;

  final void Function()? onTap;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final String? Function(String)? doValidate;
  final String? initialText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    if (controller.text.isEmpty && initialText != null) {
      controller.text = initialText!;
    }
    return TextField(
      controller: controller,
      onTap: onTap,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      decoration: decoration,
      obscureText: obscureText ?? false,
      maxLength: maxLength,
      enabled: !(disabled ?? false),
      inputFormatters: inputFormatters,
      // buildInputDecoration(hintText, errorText, errorColor, icon, suffix),
    );
  }
}

InputDecoration xtBuildInputDecoration(
    {String? hintText,
    String? errorText,
    Color? errorColor,
    Widget? prefixIcon,
    Widget? suffix,
    BuildContext? context}) {
  return InputDecoration(
    prefixIcon: prefixIcon,
    hintText: hintText,
    hintStyle: TextStyle(
      color:
          context == null ? null : Theme.of(context).hintColor.withAlpha(130),
      fontSize: 15,
    ),
    //suffixIcon: will be placed in front of suffix
    //if suffix is null, there will be a space
    suffix: Padding(
      padding: const EdgeInsets.all(5),
      child: suffix,
    ),
    errorText: errorText,
    errorStyle: TextStyle(color: errorColor, fontSize: 15),
    errorMaxLines: 2,
    // contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: context == null
            ? Colors.grey
            : Theme.of(context).hintColor.withAlpha(75),
      ),
    ),
  );
}

Widget txTextInputSuffix(String? type, Color? color) {
  switch (type) {
    case 'waiting':
      return xtWait();
    case 'available':
      return Text(
        'available',
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontStyle: FontStyle.italic,
        ),
      );
    default:
      return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wgt_text_field2.dart';

class WgtFinderFieldInput extends StatefulWidget {
  const WgtFinderFieldInput({
    super.key,
    this.width = 220,
    this.height = 70,
    this.initialValue,
    this.isInitialValueMutable = true,
    this.onChanged,
    this.onEditingComplete,
    this.onTap,
    this.validator,
    this.onClear,
    this.onValidate,
    this.onUniqueCheck,
    this.resetKey,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.labelText,
    this.hintText,
    this.inputFormatters,
    this.maxLines = 1,
    this.uniqueKey,
    this.tableName,
    this.checkUnique,
    this.getItems,
    this.onResult,
    this.onModified,
    // this.enableSearchButton,
    this.onUpdateEnableSearchButton,
    this.scanner,
  });

  final double width;
  final double height;
  final String? initialValue;
  final bool isInitialValueMutable;
  final Function? onChanged;
  final Function? onEditingComplete;
  final Function? onTap;
  final Function? validator;
  final Function? onClear;
  final Function? onValidate;
  final Function? onUniqueCheck;
  final UniqueKey? resetKey;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final String? labelText;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? uniqueKey;
  final String? tableName;
  final Function? checkUnique;
  final Function? getItems;
  final Function? onResult;
  final Function? onModified;
  // final Function? enableSearchButton;
  final Function? onUpdateEnableSearchButton;
  final Widget? scanner;

  @override
  _WgtFinderFieldInputState createState() => _WgtFinderFieldInputState();
}

class _WgtFinderFieldInputState extends State<WgtFinderFieldInput> {
  late final TextEditingController _controller;
  String _value = '';
  UniqueKey? _resetKey;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _resetKey = widget.resetKey;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resetKey != widget.resetKey) {
      _controller.clear();
      _controller.text = widget.initialValue ?? '';
      _value = widget.initialValue ?? '';
      _resetKey = widget.resetKey;
    }

    bool enableEdit = true;
    if (widget.initialValue != null) {
      if (!widget.isInitialValueMutable) {
        enableEdit = false;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: widget.width,
          child: xtTextField2(
              controller: _controller,
              labelText: widget.labelText,
              hintText: widget.hintText,
              initialValue: widget.initialValue,
              enabled: enableEdit,
              showClearButton: enableEdit,
              resetKey: widget.resetKey,
              validator: widget.validator,
              scanner: widget.scanner,
              onChanged: (value) {
                widget.onChanged?.call(value);

                if (value.isNotEmpty) {
                  widget.onUpdateEnableSearchButton?.call();
                }
              },
              onEditingComplete: () async {
                if (_controller.text == _value) {
                  return;
                }
                _value = _controller.text;

                widget.onModified?.call();

                var result = widget.onEditingComplete?.call();
                if (result == null) {
                  return;
                }

                if (widget.getItems != null) {
                  Map<String, dynamic> itemFindResult =
                      await widget.getItems!();

                  widget.onResult?.call(itemFindResult);
                }
              },
              onClear: () {
                _controller.clear();
                widget.onClear?.call();
                widget.onUpdateEnableSearchButton?.call();
                widget.onModified?.call();
              }),
        ),
      ],
    );
  }
}

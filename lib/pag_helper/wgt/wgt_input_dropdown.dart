import 'package:buff_helper/util/string_util.dart';
import 'package:flutter/material.dart';

class WgtInputDropdown extends StatefulWidget {
  const WgtInputDropdown({
    super.key,
    this.items = const [],
    this.initialValue,
    this.isInitialValueMutable = true,
    required this.onSelected,
    this.controller,
    this.onClear,
    this.hint = 'Select',
    this.width,
    this.height,
    this.enabled = true,
    this.textStyle,
  });
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>?) onSelected;
  final TextEditingController? controller;
  final Map<String, dynamic>? initialValue;
  final bool isInitialValueMutable;
  final String hint;
  final double? width;
  final double? height;
  final Function()? onClear;
  final bool enabled;
  final TextStyle? textStyle;

  @override
  State<WgtInputDropdown> createState() => _WgtInputDropdownState();
}

class _WgtInputDropdownState extends State<WgtInputDropdown> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();

    if (widget.initialValue != null) {
      _controller.text = convertToDisplayString(
        widget.initialValue!['label'],
        widget.width == null ? 230 : widget.width!.toInt() - 50,
        const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle dropDownListTextStyle = const TextStyle(
      fontSize: 14,
      color: Colors.black,
    );

    bool enableEdit = true;
    if (widget.initialValue != null) {
      if (!widget.isInitialValueMutable) {
        enableEdit = false;
      }
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          DropdownMenu<Map<String, dynamic>>(
            enabled: enableEdit,
            width: widget.width,
            hintText: widget.hint,
            controller: _controller,
            textStyle: widget.textStyle,
            initialSelection: widget.initialValue,
            trailingIcon: Icon(
              Icons.arrow_drop_down,
              color:
                  widget.items.isEmpty ? Theme.of(context).disabledColor : null,
            ),
            menuHeight: 520,
            enableFilter: true,
            requestFocusOnTap: true,
            dropdownMenuEntries: widget.items
                .map<DropdownMenuEntry<Map<String, dynamic>>>(
                    (Map<String, dynamic> item) {
              return DropdownMenuEntry<Map<String, dynamic>>(
                value: item,
                label: convertToDisplayString(
                  item['label'],
                  widget.width == null ? 230 : widget.width!.toInt() - 50,
                  dropDownListTextStyle,
                ),
              );
            }).toList(),
            onSelected: (Map<String, dynamic>? value) async {
              widget.onSelected(value);
            },
            menuStyle: MenuStyle(
              elevation: const WidgetStatePropertyAll<double>(8.0),
              shadowColor:
                  WidgetStatePropertyAll<Color>(Theme.of(context).shadowColor),
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  WidgetStatePropertyAll<Color>(Theme.of(context).canvasColor),
              surfaceTintColor:
                  const WidgetStatePropertyAll(Colors.transparent),
            ),
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(130),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).hintColor.withAlpha(80),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              fillColor: Colors.transparent,
              filled: true,
              // isDense: true,
              // isCollapsed: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
            ),
          ),
          if (_controller.text.isNotEmpty &&
              widget.isInitialValueMutable &&
              widget.enabled)
            Transform.translate(
              offset: const Offset(-34, 0),
              child: InkWell(
                onTap: () {
                  _controller.clear();
                  widget.onSelected(null);
                  if (widget.onClear != null) {
                    widget.onClear!();
                  }
                },
                child: Icon(Icons.clear,
                    size: 21, color: Theme.of(context).hintColor.withAlpha(80)),
              ),
            ),
        ],
      ),
    );
  }
}

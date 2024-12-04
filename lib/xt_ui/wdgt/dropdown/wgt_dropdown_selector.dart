import 'package:buff_helper/util/string_util.dart';
import 'package:flutter/material.dart';

class WgtDropdownSelector extends StatefulWidget {
  const WgtDropdownSelector({
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
  });
  final List<String> items;
  final Function(String?) onSelected;
  final TextEditingController? controller;
  final String? initialValue;
  final bool isInitialValueMutable;
  final String hint;
  final double? width;
  final double? height;
  final Function()? onClear;

  @override
  State<WgtDropdownSelector> createState() => _WgtDropdownSelectorState();
}

class _WgtDropdownSelectorState extends State<WgtDropdownSelector> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
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
          DropdownMenu<String>(
            enabled: enableEdit,
            width: widget.width,
            hintText: widget.hint,
            controller: _controller,
            initialSelection: widget.initialValue,
            trailingIcon: Icon(
              Icons.arrow_drop_down,
              color:
                  widget.items.isEmpty ? Theme.of(context).disabledColor : null,
            ),
            menuHeight: 520,
            enableFilter: true,
            requestFocusOnTap: true,
            dropdownMenuEntries:
                widget.items.map<DropdownMenuEntry<String>>((String value) {
              return DropdownMenuEntry<String>(
                value: value,
                label: convertToDisplayString(
                  value,
                  widget.width == null ? 230 : widget.width!.toInt() - 50,
                  dropDownListTextStyle,
                ),
              );
            }).toList(),
            onSelected: (String? value) async {
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
                color: Theme.of(context).hintColor.withOpacity(0.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).hintColor.withOpacity(0.3),
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
          if (_controller.text.isNotEmpty)
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
                    size: 21,
                    color: Theme.of(context).hintColor.withOpacity(0.3)),
              ),
            ),
        ],
      ),
    );
  }
}

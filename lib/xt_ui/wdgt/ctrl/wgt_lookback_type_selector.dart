import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtLoookbackTypeSelector extends StatefulWidget {
  const WgtLoookbackTypeSelector({
    super.key,
    required this.lookbackTyps,
    required this.iniSelection,
    required this.onUpdateSelection,
  });

  final List<LookbackType> lookbackTyps;
  final LookbackType iniSelection;
  final Function(LookbackType lookbackType) onUpdateSelection;

  @override
  State<WgtLoookbackTypeSelector> createState() =>
      _WgtLoookbackTypeSelectorState();
}

class _WgtLoookbackTypeSelectorState extends State<WgtLoookbackTypeSelector> {
  late LookbackType _currentSelection;
  LookbackType? _currentHovering;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.iniSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...widget.lookbackTyps.map(
          (e) => _buildButton(e),
        ),
      ],
    );
  }

  Widget _buildButton(LookbackType lookbackType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: SizedBox(
        height: _currentHovering == lookbackType ? 25 : 21,
        width: _currentHovering == lookbackType ? 60 : 55,
        child: TextButton(
          onPressed: _currentSelection == lookbackType
              ? null
              : () {
                  setState(() {
                    _currentSelection = lookbackType;
                  });
                  widget.onUpdateSelection(_currentSelection);
                },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: _currentSelection == lookbackType
                ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                : Theme.of(context).hintColor.withOpacity(0.35),
          ),
          onHover: (value) {
            // if (_currentSelection == lookbackType) return;
            if (value) {
              setState(() {
                _currentHovering = lookbackType;
              });
            } else {
              setState(() {
                _currentHovering = null;
              });
            }
          },
          child: Text(
            getLookbackTypeLabel(lookbackType),
            style: TextStyle(
              color: _currentSelection == lookbackType
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              fontSize: _currentHovering == lookbackType ? 16 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

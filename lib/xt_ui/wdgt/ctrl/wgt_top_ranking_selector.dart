import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtTopRankingSelector extends StatefulWidget {
  const WgtTopRankingSelector({
    super.key,
    required this.topSelectorValues,
    required this.iniSelection,
    required this.onUpdateSelection,
    this.enableControl = true,
    this.showRightDivider = false,
  });

  final List<String> topSelectorValues;
  final String iniSelection;
  final Function(String top) onUpdateSelection;
  final bool enableControl;
  final bool showRightDivider;

  @override
  State<WgtTopRankingSelector> createState() => _WgtTopRankingSelectorState();
}

class _WgtTopRankingSelectorState extends State<WgtTopRankingSelector> {
  late String _currentSelection;
  String? _currentHovering;

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
        ...widget.topSelectorValues.map(
          (e) => _buildButton(e),
        ),
        if (widget.showRightDivider)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).hintColor.withAlpha(50),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButton(String top) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      child: SizedBox(
        height: _currentHovering == top ? 25 : 21,
        width: _currentHovering == top ? 45 : 39,
        child: TextButton(
          onPressed: !widget.enableControl
              ? null
              : _currentSelection == top
                  ? null
                  : () {
                      setState(() {
                        _currentSelection = top;
                      });
                      widget.onUpdateSelection(_currentSelection);
                    },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: _currentSelection == top
                ? Theme.of(context).colorScheme.primary.withAlpha(210)
                : Theme.of(context).hintColor.withAlpha(80),
          ),
          onHover: (value) {
            if (value) {
              setState(() {
                _currentHovering = top;
              });
            } else {
              setState(() {
                _currentHovering = null;
              });
            }
          },
          child: Text(
            getTopLabel(top),
            style: TextStyle(
              color: _currentSelection == top
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimary.withAlpha(210),
              fontSize: _currentHovering == top ? 16 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:material_ui/material_ui.dart';

class WgtLookbackTypeSelector extends StatefulWidget {
  const WgtLookbackTypeSelector({
    super.key,
    required this.lookbackTyps,
    required this.iniSelection,
    required this.onUpdateSelection,
    this.enableControl = true,
  });

  final List<LookbackType> lookbackTyps;
  final LookbackType iniSelection;
  final Function(LookbackType lookbackType) onUpdateSelection;
  final bool enableControl;

  @override
  State<WgtLookbackTypeSelector> createState() =>
      _WgtLookbackTypeSelectorState();
}

class _WgtLookbackTypeSelectorState extends State<WgtLookbackTypeSelector> {
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
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      child: SizedBox(
        height: _currentHovering == lookbackType ? 25 : 21,
        width: _currentHovering == lookbackType ? 55 : 50,
        child: TextButton(
          onPressed: !widget.enableControl
              ? null
              : _currentSelection == lookbackType
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
                ? Theme.of(context).colorScheme.primary.withAlpha(210)
                : Theme.of(context).hintColor.withAlpha(80),
          ),
          onHover: (value) {
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
                  : Theme.of(context).colorScheme.onPrimary.withAlpha(210),
              fontSize: _currentHovering == lookbackType ? 16 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/material.dart';

class WgtDeviceGroupSelector extends StatefulWidget {
  const WgtDeviceGroupSelector({
    Key? key,
    required this.deviceGroups,
    this.iniSelection = DeivceGroupType.building,
    required this.onUpdateSelection,
  }) : super(key: key);

  final List<DeivceGroupType> deviceGroups;
  final DeivceGroupType iniSelection;
  final Function(DeivceGroupType deviceGroup) onUpdateSelection;

  @override
  _WgtDeviceGroupSelectorState createState() => _WgtDeviceGroupSelectorState();
}

class _WgtDeviceGroupSelectorState extends State<WgtDeviceGroupSelector> {
  late DeivceGroupType _currentSelection;
  DeivceGroupType? _currentHovering;

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
        ...widget.deviceGroups.map(
          (e) => _buildButton(e),
        ),
      ],
    );
  }

  Widget _buildButton(DeivceGroupType deviceGroup) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      child: Container(
        height: _currentHovering == deviceGroup ? 28 : 22,
        decoration: BoxDecoration(
          color: _currentSelection == deviceGroup
              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: InkWell(
          onTap: _currentSelection == deviceGroup
              ? null
              : () {
                  setState(() {
                    _currentSelection = deviceGroup;
                  });
                  widget.onUpdateSelection(_currentSelection);
                },
          onHover: (value) {
            // if (_selectedMeterType == meterType) return;
            if (value) {
              setState(() {
                _currentHovering = deviceGroup;
              });
            } else {
              setState(() {
                _currentHovering = null;
              });
            }
          },
          child: getDeivceGroupType(
            deviceGroup,
            iconColor: _currentSelection == deviceGroup
                ? Colors.white
                : Theme.of(context).hintColor,
            iconSize: _currentHovering == deviceGroup ? 25 : 21,
          ),
        ),
      ),
    );
  }
}

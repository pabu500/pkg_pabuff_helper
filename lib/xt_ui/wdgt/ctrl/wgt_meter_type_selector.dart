import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/material.dart';

class WgtMeterTypeSelector extends StatefulWidget {
  const WgtMeterTypeSelector({
    super.key,
    required this.meterTypes,
    this.iniMeterType = MeterType.electricity1p,
    required this.onUpdateSelection,
    this.enableControl = true,
  });

  final List<MeterType> meterTypes;
  final Function(MeterType) onUpdateSelection;
  final MeterType iniMeterType;
  final bool enableControl;

  @override
  State<WgtMeterTypeSelector> createState() => _WgtMeterTypeSelectorState();
}

class _WgtMeterTypeSelectorState extends State<WgtMeterTypeSelector> {
  late MeterType _selectedMeterType;
  MeterType? _currentHovering;

  @override
  void initState() {
    super.initState();
    _selectedMeterType = widget.iniMeterType;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...widget.meterTypes.map(
          (e) => _buildButton(e),
        ),
      ],
    );
  }

  Widget _buildButton(MeterType meterType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: Container(
        height: _currentHovering == meterType ? 34 : 25,
        decoration: BoxDecoration(
          color: _selectedMeterType == meterType
              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: InkWell(
          onTap: !widget.enableControl
              ? null
              : _selectedMeterType == meterType
                  ? null
                  : () {
                      setState(() {
                        _selectedMeterType = meterType;
                      });
                      widget.onUpdateSelection(_selectedMeterType);
                    },
          onHover: (value) {
            // if (_selectedMeterType == meterType) return;
            if (value) {
              setState(() {
                _currentHovering = meterType;
              });
            } else {
              setState(() {
                _currentHovering = null;
              });
            }
          },
          child: getDeviceTypeIcon(
            meterType,
            iconColor: _selectedMeterType == meterType ? Colors.white : null,
            iconSize: _currentHovering == meterType ? 34 : null,
          ),
        ),
      ),
    );
  }
}

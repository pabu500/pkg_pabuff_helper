import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/up_helper/helper/device_def.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'wgt_meter_type_selector.dart';

/// Meter selection for an individual PAG dashboard section.
///
/// The parent handles selection changes and loading the section's statistics.
class WgtPagDashboardControl extends StatefulWidget {
  const WgtPagDashboardControl({
    super.key,
    required this.meterTypes,
    required this.onUpdateMeterType,
    this.iniMeterType = MeterType.electricity1p,
    this.enableControl = true,
    this.iconColor,
    this.marginWhenShrinked = EdgeInsets.zero,
    this.offsetWhenShrinked = 0,
  });

  /// Uses the meter types configured for the project's selected portal.
  factory WgtPagDashboardControl.fromProjectProfile({
    Key? key,
    required MdlPagProjectProfile projectProfile,
    required ValueChanged<MeterType> onUpdateMeterType,
    MeterType iniMeterType = MeterType.electricity1p,
    bool enableControl = true,
    Color? iconColor,
    EdgeInsets marginWhenShrinked = EdgeInsets.zero,
    double offsetWhenShrinked = 0,
  }) {
    final meterTypes = projectProfile
        .getPortalMeterTypeTagList()
        .map((tag) => getMeterType(tag.trim()))
        .whereType<MeterType>()
        .toSet()
        .toList(growable: false);

    return WgtPagDashboardControl(
      key: key,
      meterTypes: meterTypes,
      onUpdateMeterType: onUpdateMeterType,
      iniMeterType: iniMeterType,
      enableControl: enableControl,
      iconColor: iconColor,
      marginWhenShrinked: marginWhenShrinked,
      offsetWhenShrinked: offsetWhenShrinked,
    );
  }

  final List<MeterType> meterTypes;
  final ValueChanged<MeterType> onUpdateMeterType;
  final MeterType iniMeterType;
  final bool enableControl;
  final Color? iconColor;
  final EdgeInsets marginWhenShrinked;
  final double offsetWhenShrinked;

  @override
  State<WgtPagDashboardControl> createState() => _WgtPagDashboardControlState();
}

class _WgtPagDashboardControlState extends State<WgtPagDashboardControl> {
  bool _isCollapsed = true;
  MeterType? _selectedMeterType;

  MeterType? _resolveMeterType(MeterType? preferred) {
    if (widget.meterTypes.contains(preferred)) return preferred;
    return widget.meterTypes.firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _selectedMeterType = _resolveMeterType(widget.iniMeterType);
  }

  @override
  void didUpdateWidget(covariant WgtPagDashboardControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedMeterType = _resolveMeterType(
      oldWidget.iniMeterType != widget.iniMeterType
          ? widget.iniMeterType
          : _selectedMeterType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMeterType = _selectedMeterType;
    if (selectedMeterType == null) return const SizedBox.shrink();

    if (_isCollapsed) {
      return Tooltip(
        message: 'more settings',
        waitDuration: const Duration(milliseconds: 500),
        child: Padding(
          padding: widget.marginWhenShrinked,
          child: Transform.translate(
            offset: Offset(0, widget.offsetWhenShrinked),
            child: SizedBox(
              height: 21,
              width: 30,
              child: InkWell(
                onTap: () => setState(() => _isCollapsed = false),
                child: Icon(
                  Symbols.more_horiz,
                  color:
                      widget.iconColor ??
                      Theme.of(context).hintColor.withAlpha(80),
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade100
                  : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(1, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: WgtMeterTypeSelector(
                // The shared selector reads its initial value in initState.
                key: ValueKey(selectedMeterType),
                enableControl: widget.enableControl,
                meterTypes: widget.meterTypes,
                iniMeterType: selectedMeterType,
                onUpdateSelection: (meterType) {
                  if (meterType == _selectedMeterType) return;
                  setState(() => _selectedMeterType = meterType);
                  widget.onUpdateMeterType(meterType);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => setState(() => _isCollapsed = true),
          child: Icon(
            Icons.cancel,
            color:
                widget.iconColor ?? Theme.of(context).hintColor.withAlpha(50),
            size: 25,
          ),
        ),
      ],
    );
  }
}

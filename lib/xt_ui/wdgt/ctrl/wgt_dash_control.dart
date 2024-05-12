import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'wgt_lookback_type_selector.dart';
import 'wgt_meter_type_selector.dart';

class WgtDashControl extends StatefulWidget {
  const WgtDashControl({
    Key? key,
    required this.onUpdateLookbackType,
    required this.onUpdateMeterType,
    this.iniLookbackType = LookbackType.last_24h,
    this.iniMeterType = MeterType.electricity1p,
    required this.lookbackTyps,
    required this.meterTypes,
    this.marginWhenShrinked =
        EdgeInsets.zero, // const EdgeInsets.only(top: 10, right: 10),
    this.offsetWhenShrinked = 0,
    this.panelTitle = '',
  }) : super(key: key);

  final Function(LookbackType) onUpdateLookbackType;
  final Function(MeterType) onUpdateMeterType;
  final LookbackType iniLookbackType;
  final MeterType iniMeterType;
  final List<LookbackType> lookbackTyps;
  final List<MeterType> meterTypes;
  final EdgeInsets marginWhenShrinked;
  final double offsetWhenShrinked;
  final String panelTitle;

  @override
  _WgtDashControlState createState() => _WgtDashControlState();
}

class _WgtDashControlState extends State<WgtDashControl> {
  bool _shrinked = true;
  bool _pinned = false;
  late LookbackType _selectedLookbackType;
  late MeterType _selectedMeterType;

  @override
  void initState() {
    super.initState();
    _selectedLookbackType = widget.iniLookbackType;
    _selectedMeterType = widget.iniMeterType;
  }

  @override
  Widget build(BuildContext context) {
    return _shrinked
        ? Tooltip(
            message: 'more settings',
            waitDuration: const Duration(milliseconds: 500),
            child: Padding(
              padding: widget.marginWhenShrinked,
              child: Transform.translate(
                offset: Offset(0, widget.offsetWhenShrinked),
                child: SizedBox(
                  height: 21,
                  width: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _shrinked = false;
                          });
                        },
                        child: Icon(
                          // CupertinoIcons.gear_solid,
                          Symbols.more_horiz,
                          color: Theme.of(context).hintColor.withOpacity(0.35),
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              horizontalSpaceSmall,
              const SizedBox(width: 25),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey.shade100
                      // Theme.of(context).cardColor
                      : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(1, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    horizontalSpaceTiny,
                    // InkWell(
                    //   onTap: () {
                    //     setState(() {
                    //       _pinned = !_pinned;
                    //     });
                    //   },
                    //   child: Icon(
                    //     Icons.push_pin,
                    //     color: _pinned
                    //         ? Theme.of(context)
                    //             .colorScheme
                    //             .primary
                    //             .withOpacity(0.7)
                    //         : Theme.of(context).hintColor.withOpacity(0.3),
                    //     size: 25,
                    //   ),
                    // ),
                    // horizontalSpaceSmall,
                    WgtLoookbackTypeSelector(
                      lookbackTyps: widget.lookbackTyps,
                      iniSelection: _selectedLookbackType,
                      onUpdateSelection: (lookbackType) {
                        if (lookbackType == _selectedLookbackType) return;
                        setState(() {
                          _selectedLookbackType = lookbackType;
                        });
                        widget.onUpdateLookbackType(_selectedLookbackType);
                      },
                    ),
                    if (widget.meterTypes.isNotEmpty) horizontalSpaceSmall,
                    if (widget.meterTypes.isNotEmpty)
                      WgtMeterTypeSelector(
                        meterTypes: widget.meterTypes,
                        iniMeterType: _selectedMeterType,
                        onUpdateSelection: (MeterType meterType) {
                          if (meterType == _selectedMeterType) return;
                          setState(() {
                            _selectedMeterType = meterType;
                          });
                          widget.onUpdateMeterType(_selectedMeterType);
                        },
                      ),
                    // horizontalSpaceSmall,
                    // InkWell(
                    //   onTap: () {
                    //     setState(() {
                    //       _shrinked = true;
                    //     });
                    //   },
                    //   child: Icon(
                    //     Icons.cancel,
                    //     color: Theme.of(context).hintColor.withOpacity(0.3),
                    //     size: 25,
                    //   ),
                    // ),
                    horizontalSpaceTiny,
                  ],
                ),
              ),
              horizontalSpaceSmall,
              InkWell(
                onTap: () {
                  setState(() {
                    _shrinked = true;
                  });
                },
                child: Icon(
                  Icons.cancel,
                  color: Theme.of(context).hintColor.withOpacity(0.21),
                  size: 25,
                ),
              ),
            ],
          );
  }
}

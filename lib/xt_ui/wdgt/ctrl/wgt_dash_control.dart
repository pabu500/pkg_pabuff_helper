import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'wgt_lookback_type_selector.dart';
import 'wgt_meter_type_selector.dart';

class WgtDashControl extends StatefulWidget {
  const WgtDashControl({
    super.key,
    required this.onUpdateLookbackType,
    required this.onUpdateMeterType,
    this.onUpdateMainMetersOnly,
    this.iniLookbackType = LookbackType.last_24h,
    this.iniMeterType = MeterType.electricity1p,
    // this.mainMetersOnly = true,
    this.mainOrSub = 'main',
    required this.lookbackTyps,
    required this.meterTypes,
    this.marginWhenShrinked =
        EdgeInsets.zero, // const EdgeInsets.only(top: 10, right: 10),
    this.offsetWhenShrinked = 0,
    this.panelTitle = '',
    this.enableControl = true,
  });

  final Function(LookbackType) onUpdateLookbackType;
  final Function(MeterType) onUpdateMeterType;
  final Function(String)? onUpdateMainMetersOnly;
  final LookbackType iniLookbackType;
  final MeterType iniMeterType;
  final List<LookbackType> lookbackTyps;
  final List<MeterType> meterTypes;
  final EdgeInsets marginWhenShrinked;
  final double offsetWhenShrinked;
  final String panelTitle;
  // final bool mainMetersOnly;
  final String mainOrSub;
  final bool enableControl;

  @override
  State<WgtDashControl> createState() => _WgtDashControlState();
}

class _WgtDashControlState extends State<WgtDashControl> {
  bool _shrinked = true;
  bool _pinned = false;
  late LookbackType _selectedLookbackType;
  late MeterType _selectedMeterType;
  // late bool _mainMetersOnly;
  late String _mainOrSub;

  @override
  void initState() {
    super.initState();
    _selectedLookbackType = widget.iniLookbackType;
    _selectedMeterType = widget.iniMeterType;
    // _mainMetersOnly = widget.mainMetersOnly;
    _mainOrSub = widget.mainOrSub;
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
                      enableControl: widget.enableControl,
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
                        enableControl: widget.enableControl,
                        meterTypes: widget.meterTypes,
                        iniMeterType: _selectedMeterType,
                        onUpdateSelection: (MeterType meterType) {
                          if (meterType == _selectedMeterType) return;
                          setState(() {
                            _selectedMeterType = meterType;
                            if (_selectedMeterType != MeterType.electricity1p &&
                                _selectedMeterType != MeterType.btu) {
                              // _mainMetersOnly = false;
                              _mainOrSub = 'sub';
                            }
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
                    //onUpdateMainMetersOnly
                    if (widget.onUpdateMainMetersOnly != null)
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 5),
                      //   decoration: BoxDecoration(
                      //     color: Theme.of(context)
                      //         .colorScheme
                      //         .primary
                      //         .withOpacity(0.7),
                      //     borderRadius: BorderRadius.circular(5),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.1),
                      //         spreadRadius: 3,
                      //         blurRadius: 5,
                      //         offset: const Offset(1, 3),
                      //       ),
                      //     ],
                      //   ),
                      //   child: InkWell(
                      //     onTap: !widget.enableControl
                      //         ? null
                      //         : (_selectedMeterType !=
                      //                     MeterType.electricity1p &&
                      //                 _selectedMeterType != MeterType.btu)
                      //             ? null
                      //             : () {
                      //                 widget.onUpdateMainMetersOnly
                      //                     ?.call(!_mainMetersOnly);
                      //                 setState(() {
                      //                   _mainMetersOnly = !_mainMetersOnly;
                      //                 });
                      //               },
                      //     child: const Text(
                      //       'Main',
                      //       style: TextStyle(color: Colors.white),
                      //     ),
                      //   ),
                      // ),
                      //toggle switch
                      Row(
                        children: [
                          Text(
                            'Sub',
                            style: TextStyle(
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _mainOrSub == 'main',
                              onChanged: !widget.enableControl
                                  ? null
                                  : (_selectedMeterType !=
                                              MeterType.electricity1p &&
                                          _selectedMeterType != MeterType.btu)
                                      ? null
                                      : (value) {
                                          String mainOrSub =
                                              value ? 'main' : 'sub';
                                          widget.onUpdateMainMetersOnly
                                              ?.call(mainOrSub);
                                          setState(() {
                                            _mainOrSub = mainOrSub;
                                          });
                                        },
                              activeColor: Colors.white,
                              activeTrackColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.7),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor:
                                  Theme.of(context).hintColor.withOpacity(0.35),
                            ),
                          ),
                          Text(
                            'Main',
                            style: TextStyle(
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    horizontalSpaceSmall,
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

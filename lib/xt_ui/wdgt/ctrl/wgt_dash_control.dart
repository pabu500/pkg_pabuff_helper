import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/file/wgt_save_table.dart';
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
    this.iniMainSubMeterSel = const {'main': true, 'sub': true},
    // this.mainMetersOnly = true,
    this.mainOrSub = 'main',
    required this.lookbackTyps,
    required this.meterTypes,
    this.marginWhenShrinked =
        EdgeInsets.zero, // const EdgeInsets.only(top: 10, right: 10),
    this.offsetWhenShrinked = 0,
    this.panelTitle = '',
    this.enableControl = true,
    this.showMainMetersSwitch = false,
    this.showDownload = false,
    this.onUpdateMainSubMeterSel,
    this.getList,
  });

  final Function(LookbackType) onUpdateLookbackType;
  final Function(MeterType) onUpdateMeterType;
  final Function(String)? onUpdateMainMetersOnly;
  final LookbackType iniLookbackType;
  final MeterType iniMeterType;
  final Map<String, bool> iniMainSubMeterSel;
  final List<LookbackType> lookbackTyps;
  final List<MeterType> meterTypes;
  final EdgeInsets marginWhenShrinked;
  final double offsetWhenShrinked;
  final String panelTitle;
  // final bool mainMetersOnly;
  final String mainOrSub;
  final bool enableControl;
  final bool showMainMetersSwitch;
  final bool showDownload;
  final Function(Map<String, bool>)? onUpdateMainSubMeterSel;
  final List<List<dynamic>> Function()? getList;

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

  late bool _mainMeterSelected = widget.iniMainSubMeterSel['main'] ?? true;
  late bool _subMeterSelected = widget.iniMainSubMeterSel['sub'] ?? true;

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
                          color: Theme.of(context).hintColor.withAlpha(80),
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
                      color: Colors.black.withAlpha(30),
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
                    if (widget.meterTypes.isNotEmpty) horizontalSpaceTiny,
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
                              color: Theme.of(context).hintColor.withAlpha(180),
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
                                  .withAlpha(180),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor:
                                  Theme.of(context).hintColor.withAlpha(80),
                            ),
                          ),
                          Text(
                            'Main',
                            style: TextStyle(
                              color: Theme.of(context).hintColor.withAlpha(180),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    if (widget.showMainMetersSwitch) getMainMeterSwitcher(),
                    if (widget.showDownload) getDownload(),
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
                  color: Theme.of(context).hintColor.withAlpha(50),
                  size: 25,
                ),
              ),
            ],
          );
  }

  Widget getMainMeterSwitcher() {
    bool enableMainMeterSelect = true;
    if (!_subMeterSelected && _mainMeterSelected) {
      enableMainMeterSelect = false;
    }
    bool enableSubMeterSelect = true;
    if (!_mainMeterSelected && _subMeterSelected) {
      enableSubMeterSelect = false;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(180),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Checkbox(
                value: _mainMeterSelected,
                onChanged: !enableMainMeterSelect
                    ? null
                    : (value) {
                        setState(() {
                          _mainMeterSelected = value!;
                        });
                        widget.onUpdateMainSubMeterSel?.call({
                          'main': value!,
                          'sub': _subMeterSelected,
                        });
                      },
              ),
              Text('Main',
                  style: TextStyle(
                      color: enableMainMeterSelect
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withAlpha(130))),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _subMeterSelected,
                onChanged: !enableSubMeterSelect
                    ? null
                    : (value) {
                        setState(() {
                          _subMeterSelected = value!;
                        });
                        widget.onUpdateMainSubMeterSel?.call({
                          'main': _mainMeterSelected,
                          'sub': value!,
                        });
                      },
              ),
              Text('Sub',
                  style: TextStyle(
                      color: enableSubMeterSelect
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withAlpha(130))),
            ],
          ),
        ],
      ),
    );
  }

  Widget getDownload() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(180),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: WgtSaveTable(
        iconSize: 20,
        color: Theme.of(context).colorScheme.onPrimary.withAlpha(210),
        getList: widget.getList ?? () => null,
        fileName: makeReportName('trending_stat', null, null, null),
      ),
    );
  }
}

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../finder_helper/wgt_item_finder2.dart';

class WgtBillingRecFinder extends StatefulWidget {
  const WgtBillingRecFinder({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.activePortalProjectScope,
    this.tenantName,
    this.lcStatusList,
    this.sectionName = '',
    this.width,
    this.onModified,
    this.onSearching,
    required this.onResult,
    this.onClearSearch,
    this.identifySingleItem = false,
    this.getCountOnly = false,
    this.idConstraintKey = 'name',
    this.showTimeRangePicker = false,
    this.timeRangePicker,
    this.initialNoR,
    this.initialType,
    this.iniShowPanel = true,
    this.onShowPanel,
    this.sidePadding = EdgeInsets.zero,
  });
  // final bool showMeterSn;

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final ProjectScope activePortalProjectScope;
  final String sectionName;
  final String? tenantName;
  final List<BillingLcStatus>? lcStatusList;
  final void Function()? onModified;
  final void Function()? onSearching;
  final void Function(Map<String, dynamic> itemFindResult) onResult;
  final void Function()? onClearSearch;
  final double? width;
  final bool identifySingleItem;
  final bool getCountOnly;
  final String idConstraintKey;
  final bool showTimeRangePicker;
  final Widget? timeRangePicker;
  final int? initialNoR;
  final String? initialType;
  final bool iniShowPanel;
  final Function? onShowPanel;
  final EdgeInsets sidePadding;

  @override
  _WgtBillingRecFinderState createState() => _WgtBillingRecFinderState();
}

class _WgtBillingRecFinderState extends State<WgtBillingRecFinder> {
  final String panelName = 'billing_rec_finder';
  final String panelTitle = 'Billing Record Finder';

  UniqueKey? _finderKey;

  DateTime? _startDateCreated;
  DateTime? _endDateCreated;
  DateTime? _startDateFrom;
  DateTime? _endDateFrom;
  // bool _isMonthly = false;

  String? _selectedGenType;
  late final List<String> _genTypeList = [];
  String? _selectedLcStatus;
  late final List<String> _lcStatusList = [];

  Map<String, dynamic> _additionalPropQueryMap = {};
  Map<String, dynamic> _additionalTypeQueryMap = {};
  Map<String, dynamic> _additionalTypeQueryMap2 = {};

  late TextStyle dropDownListTextStyle;
  late TextStyle dropDownListHintStyle;
  late Widget dropDownUnderline;

  @override
  void initState() {
    super.initState();

    _genTypeList.clear();
    if (widget.activePortalProjectScope == ProjectScope.EMS_CW_NUS) {
      _genTypeList.addAll([
        '   ',
        BillGenType.auto.name,
        BillGenType.manual.name,
      ]);
      if (widget.lcStatusList == null) {
        _lcStatusList.addAll([
          '   ',
          BillingLcStatus.generated.name,
          BillingLcStatus.released.name,
        ]);
      } else {
        _lcStatusList.addAll(widget.lcStatusList!.map((e) => e.name));
      }
      if (_lcStatusList.length == 1) {
        _selectedLcStatus = _lcStatusList[0];
      }
    }

    // _additionalPropQueryMap = {
    //   'time_range': {
    //     'from_timestamp': {
    //       'start_datetime':
    //           DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
    //       'end_datetime': DateTime.now().toIso8601String()
    //     },
    //     'created_timestamp': {
    //       'start_datetime':
    //           DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
    //       'end_datetime': DateTime.now().toIso8601String()
    //     },
    //   }
    // };
    _additionalPropQueryMap = {'time_range': {}};
    _additionalTypeQueryMap = {
      'gen_type': _selectedGenType ?? '',
    };
    _additionalTypeQueryMap2 = {
      'lc_status': _selectedLcStatus ?? '',
    };
  }

  void _reset() {
    setState(() {
      _startDateCreated = null;
      _endDateCreated = null;
      _startDateFrom = null;
      _endDateFrom = null;
      _additionalPropQueryMap.clear();
      _additionalTypeQueryMap.clear();
      _additionalTypeQueryMap2.clear();
      _finderKey = UniqueKey();
      // _isMonthly = false;
      _selectedGenType = null;
      _selectedLcStatus = null;
      if (_lcStatusList.length == 1) {
        if (kDebugMode) {
          print('lcStatusList: $_lcStatusList');
        }
        _selectedLcStatus = _lcStatusList[0];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    dropDownListTextStyle =
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    dropDownUnderline = Container(
        height: 1, color: Theme.of(context).hintColor.withOpacity(0.3));

    return WgtItemFinder2(
      activePortalProjectScope: widget.activePortalProjectScope,
      loggedInUser: widget.loggedInUser,
      scopeProfile: widget.scopeProfile,
      showSiteScopeSelector: false,
      sidePadding: widget.sidePadding,
      sectionName: widget.sectionName,
      panelTitle: panelTitle,
      panelName: panelName,
      itemNameText: 'Identifier',
      fixedItemName: widget.tenantName,
      itemType: ItemType.billing_rec,
      initialNoR: widget.initialNoR,
      iniShowPanel: widget.iniShowPanel,
      onShowPanel: widget.onShowPanel,
      identifySingleItem: widget.identifySingleItem,
      idConstraintKey: widget.idConstraintKey,
      getAdditionalPropWidget: getTenantAdditionalPropWidget,
      getAdditionalTypeWidget: getAdditionalTypeWidget,
      getAdditionalTypeWidget2: getAdditionalTypeWidget2,
      additionalPropQueryMap: _additionalPropQueryMap,
      additionalTypeQueryMap2: _additionalTypeQueryMap2,
      // {
      //   'location_tag': _locationTag,
      //   'sap_wbs': _sapWbs,
      // },
      additionalTypeQueryMap: _additionalTypeQueryMap,
      // {
      //   'tenant_type': _selectedTenantType ?? '',
      // },
      // itemTypeList: _tenantTypeList,
      onResult: widget.onResult,
      onClearSearch: () {
        // setState(() {
        //   _startDateCreated = null;
        //   _endDateCreated = null;
        //   _startDateFrom = null;
        //   _endDateFrom = null;
        //   _additionalPropQueryMap.clear();
        //   _additionalTypeQueryMap.clear();
        //   _additionalTypeQueryMap2.clear();
        //   _finderKey = UniqueKey();
        //   // _isMonthly = false;
        //   _selectedGenType = null;
        //   _selectedLcStatus = null;
        // });
        _reset();

        widget.onClearSearch?.call();
      },
      onModified: widget.onModified,
      onSearching: widget.onSearching,
      timeRangePicker: widget.timeRangePicker,
      showTimeRangePicker: widget.showTimeRangePicker,
    );
  }

  Widget getTenantAdditionalPropWidget(getItemList, updateEnableSearchButton) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        verticalSpaceSmall,
        Row(
          children: [
            SizedBox(
              width: 55,
              child: Text('Created',
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ),
            WgtDateRangePickerMonthly(
              scopeProfile: widget.scopeProfile,
              showMonthly: false,
              key: _finderKey,
              iniStartDateTime: _startDateCreated,
              iniEndDateTime: _endDateCreated,
              onRangeSet: (DateTime start, DateTime end) {
                setState(() {
                  _startDateCreated = start;
                  _endDateCreated = end;
                  _additionalPropQueryMap.putIfAbsent('time_range', () => {});
                  _additionalPropQueryMap['time_range']['created_timestamp'] = {
                    'start_datetime': start.toIso8601String(),
                    'end_datetime': end.toIso8601String()
                  };
                });

                // updateEnableSearchButton();
                widget.onModified?.call();
              },
            ),
          ],
        ),
        verticalSpaceSmall,
        Row(
          children: [
            SizedBox(
                width: 55,
                child: Text('From',
                    style: TextStyle(color: Theme.of(context).hintColor))),
            WgtDateRangePickerMonthly(
              // key: _finderKey,
              scopeProfile: widget.scopeProfile,
              iniStartDateTime: _startDateFrom,
              iniEndDateTime: _endDateFrom,
              // monthPicked: _monthPicked,
              onRangeSet: (startDate, endDate) async {
                if (startDate == null || endDate == null) return;
                _reset();
                setState(() {
                  _startDateFrom = startDate;
                  _endDateFrom = endDate;

                  // _isMTD = false;
                  // _monthPicked = null;

                  _additionalPropQueryMap.putIfAbsent('time_range', () => {});
                  _additionalPropQueryMap['time_range']['from_timestamp'] = {
                    'start_datetime': startDate.toIso8601String(),
                    'end_datetime': endDate.toIso8601String()
                  };
                });
              },
              onMonthPicked: (selected) {
                _reset();
                setState(() {
                  // _timePickerKey = UniqueKey();
                  // _monthPicked = selected;
                  _startDateFrom = DateTime(selected.year, selected.month, 1);
                  _endDateFrom = DateTime(selected.year, selected.month + 1, 0);
                  // _customRange = false;
                  DateTime localNow =
                      getTargetLocalDatetimeNow(widget.scopeProfile.timezone);

                  // _isMTD = false;
                  // if (localNow.year == selected.year &&
                  //     localNow.month == selected.month) {
                  //   _isMTD = true;
                  // }

                  _additionalPropQueryMap.putIfAbsent('time_range', () => {});
                  _additionalPropQueryMap['time_range']['from_timestamp'] = {
                    'start_datetime': _startDateFrom!.toIso8601String(),
                    'end_datetime': _endDateFrom!.toIso8601String()
                  };
                });
                widget.onModified?.call();
              },
            ),
            // WgtDateRangePickerMonthly(
            //   scopeProfile: _scopeProfile,
            //   showMonthly: false,
            //   key: _finderKey,
            //   iniStartDateTime: _startDateFrom,
            //   iniEndDateTime: _endDateFrom,
            //   onRangeSet: (DateTime start, DateTime end) {
            //     setState(() {
            //       _startDateFrom = start;
            //       _endDateFrom = end;

            //       _additionalPropQueryMap.putIfAbsent('time_range', () => {});
            //       _additionalPropQueryMap['time_range']['from_timestamp'] = {
            //         'start_datetime': start.toIso8601String(),
            //         'end_datetime': end.toIso8601String()
            //       };
            //     });

            //     // updateEnableSearchButton();
            //     widget.onModified?.call();
            //   },
            // ),
          ],
        ),
      ],
    );
  }

  Widget getAdditionalTypeWidget(updateType, updateEnableSearchButton) {
    return DropdownButton<String>(
        alignment: AlignmentDirectional.centerEnd,
        hint: Padding(
          padding: const EdgeInsets.only(bottom: 3.0),
          child: Text('Type', style: dropDownListHintStyle),
        ),
        value: _selectedGenType,
        // isDense: true,
        // itemHeight: 21,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (String? value) async {
          if (value != null) {
            if (value == _selectedGenType) {
              return;
            }
          }
          setState(() {
            _selectedGenType = value;
            // _finderKey = UniqueKey();
            _additionalTypeQueryMap['gen_type'] = _selectedGenType ?? '';
            updateType(_additionalTypeQueryMap);
            updateEnableSearchButton(value);
          });
          if (widget.onModified != null) {
            widget.onModified!();
          }
        },
        items: _genTypeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text(value, style: dropDownListTextStyle),
            ),
          );
        }).toList());
  }

  Widget getAdditionalTypeWidget2(updateType, updateEnableSearchButton) {
    return DropdownButton<String>(
        alignment: AlignmentDirectional.centerEnd,
        hint: Padding(
          padding: const EdgeInsets.only(bottom: 3.0),
          child: Text('Status', style: dropDownListHintStyle),
        ),
        value: _selectedLcStatus,
        // isDense: true,
        // itemHeight: 21,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (String? value) async {
          if (value != null) {
            if (value == _selectedLcStatus) {
              return;
            }
          }
          setState(() {
            _selectedLcStatus = value;
            // _finderKey = UniqueKey();
            _additionalTypeQueryMap2['lc_status'] = _selectedLcStatus ?? '';
            updateType(_additionalTypeQueryMap2);
            updateEnableSearchButton(value);
          });
          if (widget.onModified != null) {
            widget.onModified!();
          }
        },
        items: _lcStatusList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text(value, style: dropDownListTextStyle),
            ),
          );
        }).toList());
  }
}

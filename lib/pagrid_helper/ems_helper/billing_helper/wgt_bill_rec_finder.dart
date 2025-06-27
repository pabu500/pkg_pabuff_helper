import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_helper/pagrid_app_config.dart';
import '../../finder_helper/wgt_item_finder2.dart';

class WgtBillingRecFinder extends StatefulWidget {
  const WgtBillingRecFinder({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
    this.tenantName,
    this.tenantLabel,
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
    this.includeTestItems = false,
  });
  // final bool showMeterSn;

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final PaGridAppConfig appConfig;
  final String sectionName;
  final String? tenantName;
  final String? tenantLabel;
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
  final bool includeTestItems;

  @override
  State<WgtBillingRecFinder> createState() => _WgtBillingRecFinderState();
}

class _WgtBillingRecFinderState extends State<WgtBillingRecFinder> {
  final String panelName = 'billing_rec_finder';
  final String panelTitle = 'Billing Record Finder';

  UniqueKey? _finderKey;

  DateTime? _startDateCreated;
  DateTime? _endDateCreated;
  DateTime? _startDateFrom;
  DateTime? _endDateFrom;
  bool _isMonthly = false;
  UniqueKey? _timePickerKeyCreated;
  UniqueKey? _timePickerKeyFrom;
  bool _customDateRangeSelectedCreated = false;
  bool _customDateRangeSelectedFrom = false;

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

  final List<Map<String, dynamic>> _tenantInfoList = [];
  final List<String> _tenantLabelList = [];
  int _pullFails = 0;
  bool _loadingTenantInfoList = false;

  Future<dynamic> _getTenantInfoList() async {
    // List<Map<String, dynamic>> tenantInfoList = [];
    try {
      setState(() {
        _loadingTenantInfoList = true;
      });
      List<Map<String, dynamic>> result = await doGetAllTenantList(
        widget.appConfig,
        {},
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: widget.scopeProfile.getEffectiveScopeStr(),
          target: getAclTargetStr(AclTarget.tenant_p_info),
          operation: AclOperation.list.name,
        ),
      );
      if (result.isNotEmpty) {
        //drop all labels start with 'test'
        if (!widget.includeTestItems) {
          result.removeWhere((element) => element['tenant_label']
              .toString()
              .toLowerCase()
              .startsWith('test'));
          result.removeWhere((element) => element['tenant_label']
              .toString()
              .toLowerCase()
              .contains('delete'));
        }

        _tenantInfoList.addAll(result);

        // filter out non internal tenant types
        for (var tenant in _tenantInfoList) {
          if (tenant['type'] != null &&
              tenant['type'].toString().toLowerCase() != 'cw_nus_internal') {
            continue;
          }
          _tenantLabelList.add(tenant['tenant_label'] as String);
        }
        // sort tenant labels asc
        _tenantLabelList
            .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        // _tenantLabelList.addAll(result.map((e) => e['tenant_label'] as String));
      }
      _pullFails = 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      _pullFails++;
    } finally {
      // if (kDebugMode) {
      //   print('tenantLabelList: $tenantLabelList');
      // }
      setState(() {
        _loadingTenantInfoList = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _pullFails = 0;

    _genTypeList.clear();
    if (widget.appConfig.activePortalProjectScope == ProjectScope.EMS_CW_NUS) {
      _genTypeList.addAll([
        '   ',
        BillGenType.auto.name,
        BillGenType.manual.name,
      ]);
      if (widget.lcStatusList == null) {
        _lcStatusList.addAll([
          '   ',
          BillingLcStatus.generated.name,
          BillingLcStatus.pv.name,
          BillingLcStatus.released.name,
          BillingLcStatus.mfd.name,
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

  void _reset({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _startDateCreated = null;
        _endDateCreated = null;
        _startDateFrom = null;
        _endDateFrom = null;
        _customDateRangeSelectedCreated = false;
        _customDateRangeSelectedFrom = false;
        _timePickerKeyFrom = UniqueKey();
        _timePickerKeyCreated = UniqueKey();
      }
      _additionalPropQueryMap.clear();
      _additionalTypeQueryMap.clear();
      _additionalTypeQueryMap2.clear();
      _finderKey = UniqueKey();
      // _isMonthly = false;
      _selectedGenType = null;
      if (_genTypeList.length == 1) {
        if (kDebugMode) {
          print('genTypeList: $_genTypeList');
        }
        _selectedGenType = _genTypeList[0];
        _additionalTypeQueryMap['gen_type'] = _selectedGenType ?? '';
      }
      _selectedLcStatus = null;
      if (_lcStatusList.length == 1) {
        if (kDebugMode) {
          print('lcStatusList: $_lcStatusList');
        }
        _selectedLcStatus = _lcStatusList[0];
        _additionalTypeQueryMap2['lc_status'] = _selectedLcStatus ?? '';
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

    bool pullData = _tenantInfoList.isEmpty && !_loadingTenantInfoList;
    if (_pullFails >= 3) {
      if (kDebugMode) {
        print('billing release: pull fails more than $_pullFails times');
      }
      pullData = false;
      return SizedBox(
          height: 60,
          child: Center(
              child: getErrorTextPrompt(
                  context: context, errorText: 'Error getting data')));
    }

    return pullData
        ? FutureBuilder<void>(
            future: _getTenantInfoList(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Center(
                      child: xtWait(
                    color: Theme.of(context).colorScheme.primary,
                  ));

                default:
                  if (snapshot.hasError) {
                    return Center(
                        child: getErrorTextPrompt(
                            context: context, errorText: 'Error getting data'));
                  } else {
                    return buildFinder();
                  }
              }
            },
          )
        : buildFinder();
  }

  Widget buildFinder() {
    return WgtItemFinder2(
      appConfig: widget.appConfig,
      loggedInUser: widget.loggedInUser,
      scopeProfile: widget.scopeProfile,
      showSiteScopeSelector: false,
      useItemLabelDropdownSelector: true,
      itemLableList: _tenantLabelList,
      sidePadding: widget.sidePadding,
      sectionName: widget.sectionName,
      panelTitle: panelTitle,
      panelName: panelName,
      itemLabelText: 'Tenant Label',
      itemNameText: 'Identifier',
      fixedItemName: widget.tenantName,
      fixedItemLabel: widget.tenantLabel,
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
      additionalTypeQueryMap: _additionalTypeQueryMap,
      onResult: widget.onResult,
      onClearSearch: () {
        _reset(resetDateRange: true);

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
              // key: _finderKey,
              key: _timePickerKeyCreated,
              iniStartDateTime: _startDateCreated,
              iniEndDateTime: _endDateCreated,
              customRangeSelected: _customDateRangeSelectedCreated,
              scopeProfile: widget.scopeProfile,
              populateDefaultRange: false,
              maxHistoryDays: 370,
              showMonthly: false,
              onRangeSet: (DateTime start, DateTime end) {
                setState(() {
                  _startDateCreated = start;
                  _endDateCreated = end;
                  _customDateRangeSelectedCreated = true;
                  _isMonthly = false;

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
              key: _timePickerKeyFrom,
              iniStartDateTime: _startDateFrom,
              iniEndDateTime: _endDateFrom,
              customRangeSelected: _customDateRangeSelectedFrom,
              scopeProfile: widget.scopeProfile,
              populateDefaultRange: false,
              // monthPicked: _monthPicked,
              onRangeSet: (startDate, endDate) async {
                if (startDate == null || endDate == null) return;
                _reset();
                setState(() {
                  _startDateFrom = startDate;
                  _endDateFrom = endDate;
                  _customDateRangeSelectedFrom = true;
                  _isMonthly = false;
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

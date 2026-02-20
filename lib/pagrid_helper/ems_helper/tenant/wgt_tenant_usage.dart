import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'comm_tenant_usage.dart';
import 'wgt_tenant_finder2.dart';

class WgtTenantUsage extends StatefulWidget {
  const WgtTenantUsage({
    super.key,
    required this.appConfig,
    this.itemListPaneMode = false,
    this.tenantName,
    this.tenantLabel,
  });

  final PaGridAppConfig appConfig;
  final bool itemListPaneMode;
  final String? tenantName;
  final String? tenantLabel;

  @override
  State<WgtTenantUsage> createState() => _WgtTenantUsageState();
}

class _WgtTenantUsageState extends State<WgtTenantUsage> {
  late ScopeProfile _scopeProfile;
  late Evs2User? _loggedInUser;
  late List<Map<String, dynamic>> _listConfig;

  String _emptyResultText = 'No history data available';
  String _errorText = '';
  bool _showEmptyResult = false;

  bool _isItemListLoading = false;
  bool _queryItemsComplete = false;

  late final ItemIdType _selectedItemIdType;
  late final String _itemIdConstraintKey;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _monthPicked;
  bool _isMTD = false;
  // bool _customRange = true;

  // final List<Tenant> _entityItems = [];
  final List<Map<String, dynamic>> _entityItems = [];
  Map<String, dynamic> _queryMap = {};
  int _maxRowsPerPage = 20;
  int _currentPage = 1;
  String? _sortBy;
  String _sortOrder = 'desc';

  int _totalItemCount = 0;
  bool _showCount = false;
  String _itemSelectQuery = '';

  UniqueKey? _timePickerKey;
  bool _customDateRangeSelected = false;

  late ItemType _itemType;

  final List<Map<String, dynamic>> _tenantUsageSummary = [];
  // final List<Map<String, dynamic>> _subTenantListUsageSummary = [];

  EmsTypeUsageCalc? _emsTypeUsageCalc;

  Future<void> _getTenantUsageSummary() async {
    if (_selectedEndDate == null || _selectedStartDate == null) return;

    //align end date to end of day
    _selectedEndDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month,
        _selectedEndDate!.day, 23, 59, 59);

    setState(() {
      _isItemListLoading = true;
      _queryItemsComplete = false;
      _errorText = '';
    });

    _entityItems.clear();
    try {
      Map<String, dynamic> result = {};
      List<Map<String, dynamic>> usageSummary = [];

      Duration duration = _selectedEndDate!.difference(_selectedStartDate!);
      Map<String, String> queryMap = {
        'item_type': _itemType.name,
        'meter_type': _itemType.name,
        'project_scope': _scopeProfile.selectedProjectScope!.name,
        'site_scope': _scopeProfile.selectedSiteScope == null
            ? ''
            : _scopeProfile.selectedSiteScope!.name,
        'start_datetime': _selectedStartDate.toString(),
        'end_datetime': _selectedEndDate.toString(),
        'max_rows_per_page': _maxRowsPerPage.toString(),
        'current_page': _currentPage.toString(),
        'sort_by': _sortBy ?? 'id',
        'sort_order': _sortOrder,
        'item_id_type': _selectedItemIdType.name,
        'id_select_query': _itemSelectQuery,
        'is_monthly': _monthPicked == null || _isMTD ? 'false' : 'true',
      };

      result = await queryTenantUsageSummary(
        widget.appConfig,
        queryMap,
        duration,
        SvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: AclScope.global.name,
          target: getAclTargetStr(AclTarget.tenant_p_usage),
          operation: AclOperation.read.name,
        ),
      );
      usageSummary = result[Evs2HistoryType.tenant_list_usage_summary.name]
          as List<Map<String, dynamic>>;

      _tenantUsageSummary.clear();
      for (var item in usageSummary) {
        _tenantUsageSummary.add(item);
      }
      List<Map<String, dynamic>> autoUsageSummary = [];
      for (var item in usageSummary[0]['tenant_usage_summary']) {
        autoUsageSummary.add(item);
      }

      _emsTypeUsageCalc = EmsTypeUsageCalc(
        gst: null,
        typeRates: {},
        usageFactor: {'E': 1.0, 'W': 1.0, 'B': 1.0, 'N': 1.0, 'G': 1.0},
        autoUsageSummary: autoUsageSummary,
        subTenantUsageSummary: [],
        manualUsageList: [],
        lineItemList: [],
      );
      _emsTypeUsageCalc!.doCalc();

      setState(() {
        if (_currentPage == 1) {}

        for (var item in usageSummary) {
          item['checked'] = true;
        }
        // _entityItems.addAll(usageSummary);
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains('No transaction')) {
        _emptyResultText = e.toString().replaceFirst('Exception: ', '');
      }
      String errorText = explainException(e);
      if (errorText.isEmpty) {
        errorText = 'Error getting tenant usage summary';
      }
      setState(() {
        _errorText = errorText;
      });
    } finally {
      setState(() {
        _isItemListLoading = false;
        _queryItemsComplete = true;
        _showCount = false;
      });
    }
  }

  // Future<void> _onMonthlyPressed(
  //     {required BuildContext context, String? locale}) async {
  //   final localeObj = locale != null ? Locale(locale) : null;
  //   final selected = await showMonthYearPicker(
  //     context: context,
  //     initialDate: _monthPickerSelected ?? DateTime.now(),
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2030),
  //     locale: localeObj,
  //   );

  //   if (selected != null) {
  //     if (selected.isAfter(DateTime.now())) {
  //       return;
  //     }
  //     if (selected == _monthPickerSelected) {
  //       return;
  //     }
  //     reset();
  //     setState(() {
  //       _monthPickerSelected = selected;
  //       _selectedStartDate = DateTime(selected.year, selected.month, 1);
  //       _selectedEndDate = DateTime(selected.year, selected.month + 1, 0);
  //       _customRange = false;
  //       DateTime localNow = getTargetLocalDatetimeNow(_scopeProfile.timezone);
  //       _isMTD = false;
  //       if (localNow.year == selected.year &&
  //           localNow.month == selected.month) {
  //         _isMTD = true;
  //       }
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _scopeProfile =
        Provider.of<AppModel>(context, listen: false).portalScopeProfile;
    _loggedInUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;

    if (widget.appConfig.activePortalProjectScope == ProjectScope.EMS_CW_NUS) {
      _itemType = ItemType.meter_iwow;
      _selectedItemIdType = ItemIdType.name;
      _itemIdConstraintKey = 'tenant_name';
    } else if (widget.appConfig.activePortalProjectScope ==
        ProjectScope.EMS_SMRT) {
      _itemType = ItemType.meter_3p;
      _selectedItemIdType = ItemIdType.name;
      _itemIdConstraintKey = 'tenant_name';
    } else {
      _itemType = ItemType.meter;
      _selectedItemIdType = ItemIdType.name;
      _itemIdConstraintKey = 'tenant_name';
    }

    //not setting the default date range
    if (false) {
      // _selectedEndDate = getTargetLocalDatetimeNow(_scopeProfile.timezone);
      // _selectedEndDate = DateTime(_selectedEndDate.year, _selectedEndDate.month,
      //     _selectedEndDate.day, 23, 59, 59);
      // _selectedStartDate = _selectedEndDate.subtract(const Duration(hours: 48));
      // _selectedStartDate = DateTime(_selectedStartDate.year,
      //     _selectedStartDate.month, _selectedStartDate.day, 0, 0, 0);
    }

    _listConfig = [
      // {'title': 'ID', 'fieldKey': 'id', 'editable': false, 'width': 55.0},
      {
        'logicName': 'sn',
        'title': 'Item S/N',
        'fieldKey': 'meter_sn',
        'editable': false,
        'width': 120.0,
        'showSort': true,
        'detailKey': true,
      },
      {
        'logicName': 'name',
        'title': 'Name',
        'fieldKey': 'meter_name',
        'editable': false,
        'width': 100.0,
        'showSort': true,
        // 'validator': (value) {
        //   return validateFullName(value, emptyCallout: 'empty field');
        // },
        // 'disableIf': (row, compareValue) {
        //   return row['max_rank'] >= compareValue.toInt();
        // },
        'disabledTooltip': 'No permission to modify this setting',
        'detailKey': true,
      },
      {
        'logicName': 'alt_name',
        'title': 'Alt Name',
        'fieldKey': 'alt_name',
        'editable': false,
        'width': 130.0,
        'showSort': true,
        // 'validator': (value) {
        //   return validateFullName(value, emptyCallout: 'empty field');
        // },
        // 'disableIf': (row, compareValue) {
        //   return row['max_rank'] >= compareValue.toInt();
        // },
        'disabledTooltip': 'No permission to modify this setting',
        'detailKey': true,
      },
      // {
      //   'title': 'Site',
      //   'fieldKey': 'site_tag',
      //   'editable': false,
      //   'width': 150.0,
      //   'showSort': true,
      //   // 'validator': (value) {
      //   //   return validatePhone(value, emptyCallout: 'empty field');
      //   // },
      //   // 'disableIf': (row, compareValue) {
      //   //   return row['max_rank'] >= compareValue.toInt();
      //   // },
      //   'disabledTooltip': 'No permission to modify this setting',
      // },
      {
        'title': 'first reading time',
        'fieldKey': 'first_reading_time',
        'editable': false,
        'width': 150.0,
      },
      {
        'title': 'last reading time',
        'fieldKey': 'last_reading_time',
        'editable': false,
        'width': 150.0,
      },
      {
        'title': 'first reading',
        'fieldKey': 'first_reading_val',
        'decimal': 2,
        'editable': false,
        'width': 150.0,
      },
      {
        'title': 'last reading',
        'fieldKey': 'last_reading_val',
        'decimal': 2,
        'editable': false,
        'width': 150.0,
      },
      {
        'title': 'usage',
        'fieldKey': 'usage',
        'editable': false,
        'width': 150.0,
        'color': Colors.green,
      },
      // {
      //   'title': 'unit',
      //   'fieldKey': 'unit',
      //   'editable': false,
      //   'width': 150.0,
      // },
      // {
      //   'title': 'rate',
      //   'fieldKey': 'rate',
      //   'editable': false,
      //   'width': 150.0,
      // },
      // {
      //   'title': 'amount',
      //   'fieldKey': 'amount',
      //   'editable': false,
      //   'width': 150.0,
      // },
      // {
      //   'title': 'status',
      //   'fieldKey': 'status',
      //   'editable': false,
      //   'width': 150.0,
      // },
      // {
      //   'title': 'action',
      //   'fieldKey': 'action',
      //   'editable': false,
      //   'width': 150.0,
      // },
    ];

    if (_scopeProfile.selectedSiteScope != null) {}
  }

  @override
  Widget build(BuildContext context) {
    // bool emptyMeterIdentifier = _totalMeterCount == 0;
    return // Container();
        SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          xtInfoBox(
            text: 'Tenant Usage Summary',
            textStyle:
                opsWidgetTitle.copyWith(color: Theme.of(context).hintColor),
            iconTextSpace: 3,
            icon: const Icon(Symbols.cases),
          ),
          verticalSpaceSmall,
          WgtTenantFinder2(
            appConfig: widget.appConfig,
            tenantName: widget.tenantName,
            tenantLabel: widget.tenantLabel,
            loggedInUser: _loggedInUser!,
            scopeProfile: _scopeProfile,
            identifySingleItem: true,
            getCountOnly: true,
            idConstraintKey: _itemIdConstraintKey,
            onResult: (itemFindResult) {
              setState(() {
                _errorText = '';
              });
              Map<String, dynamic> result = itemFindResult['itemFindResult'];
              if (result.isEmpty) {
                setState(() {
                  _isItemListLoading = false;
                });
              } else {
                if (_currentPage == 1) {}
                _entityItems.clear();
                final itemList = result['item_list'];

                for (var item in itemList) {
                  // Tenant tenant = Tenant.fromJson(item);
                  _entityItems.add(item);
                }

                setState(() {
                  // _listKey = UniqueKey();
                  _totalItemCount = result['total_count'];
                  _itemSelectQuery = result['id_select_query'];
                  _queryMap = result['query_map'];
                  _maxRowsPerPage =
                      int.parse(_queryMap['max_rows_per_page'] ?? '20');

                  if (_totalItemCount == 0) {
                    _showEmptyResult = true;
                  } else {
                    _showEmptyResult = false;
                  }
                  _showCount = true;
                  _isItemListLoading = false;

                  // set to false to show Button to get list
                  _queryItemsComplete = false;
                });
              }
            },
            onClearSearch: () {
              reset(resetDateRange: true);
            },
            onModified: () {
              reset();
            },
            timeRangePicker: WgtDateRangePickerMonthly(
              key: _timePickerKey,
              iniEndDateTime: _selectedEndDate,
              iniStartDateTime: _selectedStartDate,
              customRangeSelected: _customDateRangeSelected,
              scopeProfile: _scopeProfile,
              monthPicked: _monthPicked,
              populateDefaultRange: false,
              onRangeSet: (startDate, endDate) async {
                if (startDate == null || endDate == null) return;
                reset(resetDateRange: true);
                setState(() {
                  _selectedStartDate = startDate;
                  _selectedEndDate = endDate;

                  _customDateRangeSelected = true;
                  _isMTD = false;
                  _monthPicked = null;

                  // _timePickerKey = UniqueKey();
                });
              },
              onMonthPicked: (selected) {
                reset(resetDateRange: true);
                setState(() {
                  // _timePickerKey = UniqueKey();
                  _monthPicked = selected;
                  _selectedStartDate =
                      DateTime(selected.year, selected.month, 1);
                  _selectedEndDate =
                      DateTime(selected.year, selected.month + 1, 0);
                  // _customRange = false;
                  DateTime localNow =
                      getTargetLocalDatetimeNow(_scopeProfile.timezone);
                  _isMTD = false;
                  if (localNow.year == selected.year &&
                      localNow.month == selected.month) {
                    _isMTD = true;
                  }
                });
              },
            ),
          ),
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _totalItemCount > 0 && _showCount
                  ? SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          Text(
                            '$_totalItemCount tenant found',
                            style:
                                TextStyle(color: Theme.of(context).hintColor),
                          ),
                          verticalSpaceSmall,
                          _queryItemsComplete ? Container() : getListButton(),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
          verticalSpaceSmall,
          _isItemListLoading
              ? xtWait(
                  color: Theme.of(context).colorScheme.primary,
                )
              : _tenantUsageSummary.isEmpty
                  ? _queryItemsComplete && _showEmptyResult
                      ? EmptyResult(
                          message: _emptyResultText,
                        )
                      : _errorText.isNotEmpty
                          ? getErrorTextPrompt(
                              context: context,
                              errorText: _errorText,
                            )
                          : Container()
                  : SingleChildScrollView(
                      child: Column(
                        children: getTenantSummaryList(),
                      ),
                    ),
        ],
      ),
    );
  }

  List<Widget> getTenantSummaryList() {
    List<Widget> list = [];

    if (_selectedStartDate == null || _selectedEndDate == null) return list;

    for (var item in _tenantUsageSummary) {
      List<Map<String, dynamic>> tenantUsageSummaryList = [];
      for (var item in item['tenant_usage_summary']) {
        tenantUsageSummaryList.add(item);
      }
      // List<Map<String, dynamic>> subTenantListUsageSummary = [];
      // if (item['sub_tenant_list_usage_summary'] != null) {
      //   for (var item in item['sub_tenant_list_usage_summary']) {
      //     subTenantListUsageSummary.add(item);
      //   }
      // }

      list.add(
        WgtTenantUsageSummary2(
          appConfig: widget.appConfig,
          loggedInUser: _loggedInUser!,
          scopeProfile: _scopeProfile,
          displayContextStr: 'tenant_usage_summary',
          usageCalc: _emsTypeUsageCalc,
          showFactoredUsage: false,
          itemType: _itemType,
          isMonthly: _monthPicked == null || _isMTD ? false : true,
          fromDatetime: _selectedStartDate!,
          toDatetime: _selectedEndDate!,
          tenantName: item['tenant_name'],
          tenantLabel: item['tenant_label'],
          tenantType: item['tenant_type'],
          excludeAutoUsage: false,
          tenantUsageSummary: tenantUsageSummaryList,
          subTenantListUsageSummary: [], //subTenantListUsageSummary,
        ),
      );
    }
    return list;
  }

  Widget getListButton() {
    return _totalItemCount > 1 ||
            (_selectedEndDate == null || _selectedStartDate == null)
        ? Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).hintColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: xtInfoBox(
              icon: Icon(
                Icons.info,
                color: Theme.of(context).hintColor,
              ),
              text: _totalItemCount > 1
                  ? 'Please select 1 tenant to get summary.'
                  : 'Please select date range to get summary.',
              textStyle: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
          )
        : xtButton(
            color: Theme.of(context).colorScheme.primary,
            text: 'Get Summary',
            onPressed: _isItemListLoading
                ? null
                : _totalItemCount == 0
                    ? null
                    : () async {
                        // setState(() {
                        //   _showCount = false;
                        // });
                        await _getTenantUsageSummary();
                      },
            waiting: _isItemListLoading,
          );
  }

  void reset({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        // _selectedEndDate = getTargetLocalDatetimeNow(_scopeProfile.timezone);
        _selectedEndDate = null;
        // DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day, 23, 59, 59);
        _selectedStartDate = null;
        //  _selectedEndDate.subtract(const Duration(hours: 48));
        // _selectedStartDate = DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day, 0, 0, 0);
        _timePickerKey = UniqueKey();
        _customDateRangeSelected = false;
        _monthPicked = null;
      }
      _totalItemCount = 0;
      _itemSelectQuery = '';
      _entityItems.clear();
      _tenantUsageSummary.clear();
      _showEmptyResult = false;
      _currentPage = 1;
      _queryItemsComplete = false;
      // _monthPicked = null;
      _showCount = false;
      _errorText = '';
    });
  }
}

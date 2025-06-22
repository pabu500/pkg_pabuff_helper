import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def/list_helper.dart';
import 'package:buff_helper/pag_helper/def/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/datetime/wgt_date_range_picker_monthly.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import '../comm/comm_list.dart';
import 'wgt_custom_pin.dart';
import 'wgt_finder_field_input.dart';
import 'wgt_input_dropdown.dart';

class WgtPagItemFinderFlexi extends StatefulWidget {
  const WgtPagItemFinderFlexi({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.itemKind,
    required this.itemType,
    required this.listController,
    required this.listContextType,
    required this.onResult,
    this.meterTypeList = const [],
    this.sectionName = '',
    this.panelName = '',
    this.panelTitle = '',
    this.width,
    this.onModified,
    this.onSearching,
    this.onClearSearch,
    this.identifySingleItem = false,
    this.getCountOnly = false,
    this.showTimeRangePicker = false,
    this.timeRangePicker,
    this.initialType,
    this.initialNoR,
    this.iniShowPanel,
    this.onShowPanel,
    this.sidePadding = EdgeInsets.zero,
    this.onLabelSelected,
    this.onCustomizeSet,
    // this.getItemList,
    // this.projectProfile,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final PagItemKind itemKind;
  final dynamic itemType;
  final MdlPagListController listController;
  final PagListContextType listContextType;
  final List<String> meterTypeList;
  final String sectionName;
  final String panelName;
  final String panelTitle;
  final void Function()? onModified;
  final void Function()? onSearching;
  final void Function(Map<String, dynamic> itemFindResult) onResult;
  final void Function()? onClearSearch;
  final double? width;
  final bool identifySingleItem;
  final bool getCountOnly;
  final bool showTimeRangePicker;
  final Widget? timeRangePicker;
  final String? initialType;
  final int? initialNoR;
  final bool? iniShowPanel;
  final Function? onShowPanel;
  final EdgeInsets sidePadding;
  final void Function(String)? onLabelSelected;
  final void Function()? onCustomizeSet;
  // final MdlPagProjectProfile? projectProfile;
  // final Function? getItemList;

  @override
  State<WgtPagItemFinderFlexi> createState() => _WgtPagItemFinderFlexiState();
}

class _WgtPagItemFinderFlexiState extends State<WgtPagItemFinderFlexi> {
  late final String listName;
  late final String itemTypeStr;
  BoxDecoration? blockDecoration;

  late DateTime _lastLoadingTime;
  DateTime? _lastRequestTime;
  String _errorText = '';

  bool _isFullPanel = false;
  bool _showPanel = false;

  late final MdlPagListController _listController;

  final TextEditingController _numberOfRecordsController =
      TextEditingController();

  final _defaultNorCap = 20;
  final _rowsPerPage = [20, 50, 100];
  int _selectedRowsPerPage = 20;
  int _currentPage = 1;
  final _norCap = 300;

  bool _isCustSet = false;

  late TextStyle _dropDownListTextStyle;
  late TextStyle _dropDownListHintStyle;
  late Widget _dropDownUnderline;

  late bool _enableSearch;
  bool _isSearching = false;
  bool _isLoaded = false;

  bool _filterListPulled = false;

  MdlPagSiteGroupProfile? _selectedSiteGroupProfile;
  MdlPagSiteProfile? _selectedSiteProfile;
  MdlPagBuildingProfile? _selectedBuildingProfile;
  MdlPagLocationGroupProfile? _selectedLocationGroupProfile;

  MdlListColController? _selectedSiteGroupColController;
  MdlListColController? _selectedSiteColController;
  MdlListColController? _selectedBuildingColController;
  MdlListColController? _selectedLocationGroupColController;

  final TextEditingController siteGroupController = TextEditingController();
  final TextEditingController siteController = TextEditingController();
  final TextEditingController buildingController = TextEditingController();
  final TextEditingController locationGroupController = TextEditingController();

  UniqueKey? _timePickerKey;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  bool _customDateRangeSelected = false;
  bool _isMTD = false;
  DateTime? _pickedMonth;

  Future<dynamic> _getItemList() async {
    if (_isSearching) {
      return null;
    }

    setState(() {
      _isSearching = true;
      _isLoaded = false;
      _errorText = '';
      _enableSearch = false;
    });

    widget.onSearching?.call();

    Map<String, dynamic> result = {};

    // this query map will be passed on to ls_item_flexi
    // when query with sort or page
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_kind': widget.itemKind.name,
      'item_type': itemTypeStr,
      'max_rows_per_page': '$_selectedRowsPerPage',
      'current_page': '$_currentPage',
      'sort_by': '',
      'sort_order': 'desc',
      'get_count_only': widget.getCountOnly ? 'true' : 'false',
      'list_context_type': widget.listContextType.name,
    };

    if (widget.listContextType == PagListContextType.usage) {
      queryMap['meter_type_list'] = widget.meterTypeList;
    }

    if (_selectedFromDate != null) {
      _genAlignedFromTo(_selectedFromDate, _selectedToDate);

      queryMap['from_timestamp'] = _selectedFromDate!.toIso8601String();
      queryMap['to_timestamp'] = _selectedToDate!.toIso8601String();
      // queryMap['is_mtd'] = '$_isMTD';
      queryMap['is_monthly'] =
          (_pickedMonth == null || _isMTD) ? 'false' : 'true';
    }

    Map<String, dynamic> fliterMap = widget.listController.getFilterMap(
      getFilterValueKey: (MdlListColController colController) {
        if (colController.filterGroupType == PagFilterGroupType.SPEC ||
            colController.filterGroupType ==
                PagFilterGroupType
                    .STATUS /* || colController.filterGroupType == PagFilterGroupType.LOCATION*/) {
          return "value";
        }
        return "label";
      },
    );
    queryMap.addAll(fliterMap);

    if (widget.listController.isNotEmpty) {
      queryMap['list_info'] = widget.listController.toJson();
    }

    // AclTarget aclTarget = getAclTargetFromItemType(widget.itemType);

    try {
      result = await fetchItemList(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      if (result['error'] != null) {
        throw Exception(result['error']);
      }

      var itemList = result['item_list'];
      if (itemList == null) {
        throw Exception('Failed to get item list');
      }

      _isLoaded = true;

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      widget.onResult({'error': 'Error getting item list'});
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _enableSearch = _enableSearchButton();
        });
      }
    }
  }

  void _genAlignedFromTo(DateTime? from, DateTime? to) {
    if (from == null || to == null) return;

    _selectedFromDate = DateTime(from.year, from.month, from.day);
    _selectedToDate = DateTime(to.year, to.month, to.day, 23, 59, 59);
    _selectedToDate = _selectedToDate!.add(const Duration(seconds: 1));
  }

  // get value list to populate input dropdown
  Future<dynamic> _getFilterValueList(
      MdlListColController listColController) async {
    // assert(widget.itemType is DeviceType ||
    //     widget.itemType is MeterType ||
    //     widget.itemType is SensorType ||
    // widget.itemType == null);
    // String itemTypeStr = '';
    // switch (widget.itemType.runtimeType) {
    //   case const (DeviceType):
    //     itemTypeStr = (widget.itemType as DeviceType).name;
    //     break;
    //   case const (MeterType):
    //     itemTypeStr = (widget.itemType as MeterType).name;
    //     break;
    //   case const (SensorType):
    //     itemTypeStr = (widget.itemType as SensorType).name;
    //     break;
    // }

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_kind': widget.itemKind.name,
      'item_type': itemTypeStr,
    };
    try {
      var result = await getFilterValueList(
        widget.appConfig,
        widget.loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (result['filter_value_list'] == null) {
        throw Exception('Failed to get filter value list');
      }

      listColController.valueList?.clear();
      for (var item in result['filter_value_list']) {
        listColController.valueList?.add(item);
      }
      if (listColController.valueList!.length == 1) {
        Map<String, dynamic> value = listColController.valueList![0];
        listColController.filterValue = value;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _filterListPulled = true;
          _enableSearch = _enableSearchButton();
        });
      }
    }

    return null;
  }

  bool _enableSearchButton() {
    if (widget.identifySingleItem) {
      // return (_itemLabel ?? '').isNotEmpty || (_itemName ?? '').isNotEmpty;
      return widget.listController.isIdentifierSet();
    }

    if (_isSearching) {
      return false;
    }

    if (widget.listContextType == PagListContextType.usage) {
      if (_selectedFromDate == null || _selectedToDate == null) {
        return false;
      }
    }

    return true;
  }

  void _clearSearch() {
    setState(() {
      _listController.clearFilter();

      // if (widget.fixedItemName != null) {
      //   _itemName = widget.fixedItemName;
      // }
      // if (widget.fixedItemLabel != null) {
      //   _itemLabel = widget.fixedItemLabel;
      // }
      _selectedFromDate = null;
      _selectedToDate = null;

      _isLoaded = false;
      _currentPage = 1;
      _errorText = '';
      _numberOfRecordsController.clear();

      _onClearSiteGroup();

      _enableSearch = _enableSearchButton();
    });

    widget.onClearSearch?.call();
    widget.onModified?.call();
  }

  void _clearResult() {
    widget.onModified?.call();
  }

  void _saveCustomize() {
    Map<String, dynamic> colCustomize = {};

    for (MdlListColController item
        in widget.listController.listColControllerList) {
      colCustomize['${listName}_${item.colKey}_pinned'] = item.pinned;
    }

    saveToSharedPref(listName, colCustomize);
  }

  void _loadCustomize() {
    dynamic listCustmize = readFromSharedPref(listName);
    Map<String, dynamic> colCustomize = json.decode(listCustmize ?? '{}');

    for (var item in widget.listController.listColControllerList) {
      String key = '${listName}_${item.colKey}';
      if (colCustomize['${key}_pinned'] != null) {
        item.pinned = colCustomize['${key}_pinned'] ?? false;
      }
    }
  }

  void _iniScopesPreload() {
    // get loc profiles form logged in user
    _selectedSiteGroupProfile =
        widget.loggedInUser.selectedScope.siteGroupProfile;
    _selectedSiteProfile = widget.loggedInUser.selectedScope.siteProfile;
    _selectedBuildingProfile =
        widget.loggedInUser.selectedScope.buildingProfile;
    _selectedLocationGroupProfile =
        widget.loggedInUser.selectedScope.locationGroupProfile;

    // get filter list col controllers from list controller
    for (MdlListColController colController
        in widget.listController.listColControllerList) {
      if (colController.colKey == 'site_group_label') {
        _selectedSiteGroupColController = colController;
        _selectedSiteGroupColController!.filterWidgetController =
            siteGroupController;
      }
      if (colController.colKey == 'site_label') {
        _selectedSiteColController = colController;
        _selectedSiteColController!.filterWidgetController = siteController;
      }
      if (colController.colKey == 'building_label') {
        _selectedBuildingColController = colController;
        _selectedBuildingColController!.filterWidgetController =
            buildingController;
      }
      if (colController.colKey == 'location_group_label') {
        _selectedLocationGroupColController = colController;
        _selectedLocationGroupColController!.filterWidgetController =
            locationGroupController;
      }
    }

    _updateBind();
  }

  void _updateBind() {
    // bind filter col controllers with loc profile
    // during wich value list will be populated with children loc profiles
    widget.loggedInUser.selectedScope.projectProfile?.bindFilterColController(
        _selectedSiteGroupColController,
        defaultSiteGroupProfile:
            widget.loggedInUser.selectedScope.siteGroupProfile,
        limitToDefault: true);
    _selectedSiteGroupProfile?.bindFilterColController(
        _selectedSiteColController,
        defaultSiteProfile: widget.loggedInUser.selectedScope.siteProfile,
        limitToDefault: true);
    _selectedSiteProfile?.bindFilterColController(
        _selectedBuildingColController,
        defaultBuildingProfile:
            widget.loggedInUser.selectedScope.buildingProfile,
        limitToDefault: true);
    _selectedBuildingProfile?.bindFilterColController(
        _selectedLocationGroupColController,
        defaultLocationGroupProfile:
            widget.loggedInUser.selectedScope.locationGroupProfile,
        limitToDefault: true);
    // _selectedLocationGroupProfile?.bindFilterColController(
    //   _selectedLocationGroupColController,
    // );
  }

  void _onUpdateSiteGroup(MdlPagSiteGroupProfile? selectedSiteGroup) {
    _selectedSiteGroupProfile = widget
        .loggedInUser.selectedScope.projectProfile!
        .getSiteGroupProfileById(selectedSiteGroup?.id.toString());
    _selectedSiteGroupProfile
        ?.bindFilterColController(_selectedSiteColController);
    _selectedSiteColController?.resetFilter();
    _selectedSiteProfile = _selectedSiteGroupProfile?.getDefaultSiteProfile();
    _onUpdateSite(_selectedSiteProfile);
  }

  void _onUpdateSite(MdlPagSiteProfile? selectedSite) {
    _selectedSiteProfile = _selectedSiteGroupProfile
        ?.getSiteProfileById(selectedSite?.id.toString());
    _selectedSiteProfile
        ?.bindFilterColController(_selectedBuildingColController);
    _selectedBuildingColController?.resetFilter();
    _selectedBuildingProfile =
        _selectedSiteProfile?.getDefaultBuildingProfile();
    _onUpdateBuilding(_selectedBuildingProfile);
  }

  void _onUpdateBuilding(MdlPagBuildingProfile? selectedBuilding) {
    _selectedBuildingProfile = _selectedSiteProfile
        ?.getBuildingProfileById(selectedBuilding?.id.toString());
    _selectedBuildingProfile
        ?.bindFilterColController(_selectedLocationGroupColController);
    _selectedLocationGroupColController?.resetFilter();
    _selectedLocationGroupProfile =
        _selectedBuildingProfile?.getDefaultLocationGroupProfile();
    _onUpdateLocationGroup(_selectedLocationGroupProfile);
  }

  void _onUpdateLocationGroup(
      MdlPagLocationGroupProfile? selectedLocationGroup) {
    _selectedLocationGroupProfile = _selectedBuildingProfile
        ?.getLocationGroupProfileById(selectedLocationGroup?.id.toString());
    _selectedLocationGroupProfile?.filterColController?.filterValue =
        selectedLocationGroup?.toJson();
    _selectedLocationGroupProfile?.filterColController?.filterWidgetController
        ?.text = selectedLocationGroup?.label ?? '';
  }

  void _onClearSiteGroup() {
    _selectedSiteGroupProfile = null;
    _selectedSiteProfile = null;
    _selectedBuildingProfile = null;
    _selectedLocationGroupProfile = null;
    _selectedSiteGroupColController?.resetFilter();
    _selectedSiteColController?.clearFilter();
    _selectedBuildingColController?.clearFilter();
    _selectedLocationGroupColController?.clearFilter();
  }

  void _onClearSite() {
    _selectedSiteProfile = null;
    _selectedBuildingProfile = null;
    _selectedLocationGroupProfile = null;
    _selectedSiteColController?.resetFilter();
    _selectedBuildingColController?.clearFilter();
    _selectedLocationGroupColController?.clearFilter();
  }

  void _onClearBuilding() {
    _selectedBuildingProfile = null;
    _selectedLocationGroupProfile = null;
    _selectedBuildingColController?.resetFilter();
    _selectedLocationGroupColController?.clearFilter();
  }

  void _onClearLocationGroup() {
    _selectedLocationGroupProfile = null;
    _selectedLocationGroupColController?.resetFilter();
  }

  void _resetTimeRangPicker({bool resetDateRange = false}) {
    // setState(() {
    if (resetDateRange) {
      _selectedToDate = null;
      _selectedFromDate = null;
      _timePickerKey = UniqueKey();
      _customDateRangeSelected = false;
      _pickedMonth = null;
      _isMTD = false;
    }
    widget.onModified?.call();
    // });
  }

  @override
  void initState() {
    super.initState();

    assert(widget.itemType is DeviceCat ||
        widget.itemType is PagScopeType ||
        widget.itemType is PagItemKind ||
        widget.itemType == null);
    // switch (widget.itemType.runtimeType) {
    //   case const (DeviceType):
    //     itemTypeStr = (widget.itemType as DeviceType).name;
    //     break;
    //   case const (MeterType):
    //     itemTypeStr = (widget.itemType as MeterType).name;
    //     break;
    //   case const (SensorType):
    //     itemTypeStr = (widget.itemType as SensorType).name;
    //     break;
    //   default:
    //     itemTypeStr = 'NOT_SET';
    // }
    if (widget.itemType is DeviceCat) {
      itemTypeStr = (widget.itemType as DeviceCat).name.toLowerCase();
    } else if (widget.itemType is PagScopeType) {
      itemTypeStr = (widget.itemType as PagScopeType).name.toLowerCase();
    } else if (widget.itemType is PagItemKind) {
      itemTypeStr = (widget.itemType as PagItemKind).name.toLowerCase();
    } else {
      itemTypeStr = 'unknown_item_type';
    }

    listName = '${widget.itemKind.name}_$itemTypeStr';

    _listController = widget.listController;

    _selectedRowsPerPage = widget.initialNoR ?? _defaultNorCap;
    //if the initialNoR is not in the list, add it then sort it
    if (!_rowsPerPage.contains(_selectedRowsPerPage)) {
      _rowsPerPage.add(_selectedRowsPerPage);
      _rowsPerPage.sort();
    }

    _iniScopesPreload();

    _enableSearch = _enableSearchButton();

    if (widget.iniShowPanel != null) {
      _showPanel = widget.iniShowPanel!;
    } else {
      dynamic showPanel =
          readFromSharedPref('${widget.sectionName}_${widget.panelName}_viz');
      if (showPanel != null && showPanel is bool) {
        _showPanel = showPanel;
      } else {
        _showPanel = true;
      }
    }

    _loadCustomize();

    _lastLoadingTime = DateTime.now();
  }

  @override
  void dispose() {
    _numberOfRecordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _dropDownListTextStyle =
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    _dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    _dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
    double width = widget.width ?? MediaQuery.of(context).size.width - 130;

    blockDecoration = BoxDecoration(
      border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(75), width: 1),
      borderRadius: BorderRadius.circular(5),
    );

    return completedWidget(width);
  }

  Widget completedWidget(double width) {
    return width > 800
        ? Padding(
            padding: widget.sidePadding,
            child: getItemPickerWide(width),
          )
        : getItemPickerNarrow();
  }

  Widget getItemPickerNarrow() {
    return _showPanel
        ? Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 5),
            decoration: BoxDecoration(
              // color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: Theme.of(context).hintColor /*.withOpacity(0.3)*/,
                  width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // getItemPropertySelector(330),
                verticalSpaceTiny,
                // getScopeSelector(),
                if (widget.timeRangePicker != null) verticalSpaceTiny,
                if (widget.timeRangePicker != null)
                  Row(children: [widget.timeRangePicker!]),
                verticalSpaceSmall,
                getOptions(),
              ],
            ),
          )
        : getCollapsedBar(
            context: context,
            saveToSharedPref: saveToSharedPref,
            color: Theme.of(context).colorScheme.primary,
            width: widget.width,
            height: 38,
            sectionName: widget.sectionName,
            panelTitle: widget.panelTitle,
            panelName: widget.panelName,
            onTap: () {
              setState(() {
                _showPanel = true;
                widget.onShowPanel?.call(true);
              });
            },
          );
  }

  Widget getItemPickerWide(double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).hintColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          getOptions(),
          horizontalSpaceTiny,
          getFileterCore(),
          horizontalSpaceTiny,
          getSearchButton(),
        ],
      ),
    );
  }

  Widget getFileterCore() {
    return Column(
      children: [
        Wrap(
          children: [
            getItemIdFilterGroup(),
            getItemSpecFilterGroup(),
            getItemLocationFilterGroup(),
            getItemStatusFilterGroup(),
          ],
        ),
        getItemTimeRangeFilterGroup(),
      ],
    );
  }

  Widget getItemIdFilterGroup() {
    List<Widget> list = getItemIdGroupList();
    if (list.isEmpty) {
      return Container();
    }
    return Container(
      decoration: blockDecoration,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...list],
      ),
    );
  }

  Widget getItemSpecFilterGroup() {
    List<Widget> list = getItemSpecGroupList();
    if (list.isEmpty) {
      return Container();
    }
    return Container(
      decoration: blockDecoration,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...list],
      ),
    );
  }

  Widget getItemStatusFilterGroup() {
    List<Widget> list = getItemStatusGroupList();
    if (list.isEmpty) {
      return Container();
    }
    return Container(
      decoration: blockDecoration,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...list],
      ),
    );
  }

  Widget getItemLocationFilterGroup() {
    List<Widget> list = getItemLocationGroupList();
    if (list.isEmpty) {
      return Container();
    }
    return Container(
      decoration: blockDecoration,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...list],
      ),
    );
  }

  Widget getItemTimeRangeFilterGroup() {
    bool showTimeRangePicker = widget.showTimeRangePicker;
    if (widget.listContextType == PagListContextType.usage) {
      showTimeRangePicker = true;
    }
    if (!showTimeRangePicker) return Container();
    return Container(
      decoration: blockDecoration,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isFullPanel)
            getPin(
              customKey: 'time_range',
              pinned: true,
              allowUnpin: false,
            ),
          if (_isFullPanel) horizontalSpaceTiny,
          Text(
            'Time Range',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 16,
            ),
          ),
          horizontalSpaceSmall,
          StatefulBuilder(builder: (context, setState) {
            return WgtPagDateRangePickerMonthly(
              // key: _timePickerKey,
              iniEndDateTime: _selectedToDate,
              iniStartDateTime: _selectedFromDate,
              customRangeSelected: _customDateRangeSelected,
              monthPicked: _pickedMonth,
              populateDefaultRange: false,
              onRangeSet: (startDate, endDate) async {
                if (startDate == null || endDate == null) return;
                _resetTimeRangPicker(resetDateRange: true);
                setState(() {
                  _selectedFromDate = startDate;
                  _selectedToDate = endDate;

                  _customDateRangeSelected = true;
                  _isMTD = false;
                  _pickedMonth = null;

                  // _timePickerKey = UniqueKey();
                  _enableSearch = _enableSearchButton();
                });
                // widget.onModified?.call();
              },
              onMonthPicked: (selected) {
                _resetTimeRangPicker(resetDateRange: true);
                setState(() {
                  // _timePickerKey = UniqueKey();
                  _pickedMonth = selected;
                  _selectedFromDate =
                      DateTime(selected.year, selected.month, 1);
                  _selectedToDate =
                      DateTime(selected.year, selected.month + 1, 0);
                  // _customRange = false;
                  DateTime localNow = getTargetLocalDatetimeNow(
                      widget.loggedInUser.selectedScope.getProjectTimezone());
                  _isMTD = false;
                  if (localNow.year == selected.year &&
                      localNow.month == selected.month) {
                    _isMTD = true;
                  }
                  _enableSearch = _enableSearchButton();
                });
                // widget.onModified?.call();
              },
            );
          }),
        ],
      ),
    );
  }

  List<Widget> getItemIdGroupList() {
    List<Widget> list = [];
    for (var colController in widget.listController.listColControllerList) {
      if (colController.show == false) continue;
      if (!_isFullPanel && !colController.pinned) continue;

      if (colController.filterGroupType == PagFilterGroupType.IDENTITY) {
        UniqueKey? resetKey = colController.filterResetKey;
        list.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
            child: SizedBox(
              height: 55,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_isFullPanel) getPin(listColController: colController),
                  if (_isFullPanel) horizontalSpaceTiny,
                  WgtPagFinderFieldInput(
                    // key: resetKey,
                    appConfig: widget.appConfig,
                    // listController: _listController,
                    width: 160,
                    labelText: colController.filterLabel,
                    hintText: colController.filterLabel,
                    resetKey: resetKey,
                    onChanged: (value) {
                      colController.filterValue = {
                        'value': value,
                        'label': value
                      };
                      if (value.isNotEmpty && !_enableSearch) {
                        setState(() {
                          _enableSearch = _enableSearchButton();
                        });
                      }
                    },
                    onEditingComplete: () async {
                      widget.onModified?.call();
                      if (colController.filterValue == null) {
                        return null;
                      }
                      if (colController.filterValue!['label'].trim().isEmpty) {
                        return null;
                      }
                      Map<String, dynamic> itemFindResult =
                          await _getItemList();
                      widget.onResult(itemFindResult);
                    },
                    onClear: () {
                      colController.filterValue = null;
                      widget.onModified?.call();
                    },
                    onModified: widget.onModified,
                    onUpdateEnableSearchButton: _enableSearchButton,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return list;
  }

  List<Widget> getItemSpecGroupList() {
    List<Widget> list = [];
    for (MdlListColController colController
        in widget.listController.listColControllerList) {
      if (colController.show == false) continue;
      // need to pull the filter value list regardless of the panel status
      // because the value list is needed to populate for the info edit panel
      // if (!_isFullPanel && !colController.pinned) continue;

      if (colController.filterGroupType == PagFilterGroupType.SPEC) {
        Widget wdiget = (colController.valueList!.isEmpty && !_filterListPulled)
            ? FutureBuilder(
                future: _getFilterValueList(colController),
                builder: (context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      if (kDebugMode) {
                        print('item spec group list waiting...');
                      }
                      return const WgtPagWait(size: 34);
                    default:
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          print(snapshot.error);
                        }
                        return getErrorTextPrompt(
                            context: context, errorText: 'list error');
                      } else {
                        return getDropDownButton(colController, _isFullPanel);
                      }
                  }
                },
              )
            : getDropDownButton(colController, _isFullPanel);
        if (_isFullPanel || colController.pinned) {
          list.add(wdiget);
        }
      }
    }

    return list;
  }

  List<Widget> getItemLocationGroupList() {
    List<Widget> list = [];

    for (MdlListColController colController
        in widget.listController.listColControllerList) {
      if (colController.show == false) continue;
      if (!_isFullPanel && !colController.pinned) continue;

      if (colController.filterGroupType == PagFilterGroupType.LOCATION) {
        // skip location filter
        if (colController.colKey == 'location_label') {
          continue;
        }
        list.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_isFullPanel) getPin(listColController: colController),
                if (_isFullPanel) horizontalSpaceTiny,
                getInputDropdown(colController, _isFullPanel)
              ],
            ),
          ),
        );
      }
    }

    return list;
  }

  List<Widget> getItemStatusGroupList() {
    List<Widget> list = [];
    for (MdlListColController item
        in widget.listController.listColControllerList) {
      if (item.show == false) continue;
      // need to pull the filter value list regardless of the panel status
      // because the value list is needed to populate for the info edit panel
      // if (!_isFullPanel && !item.pinned) continue;

      if (item.filterGroupType == PagFilterGroupType.STATUS) {
        //dropdown
        Widget wdiget = (item.valueList!.isEmpty)
            ? FutureBuilder(
                future: _getFilterValueList(item),
                builder: (context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      if (kDebugMode) {
                        print('item status group list waiting...');
                      }
                      return const WgtPagWait(size: 34);
                    default:
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          print(snapshot.error);
                        }
                        return getErrorTextPrompt(
                            context: context, errorText: 'list error');
                      } else {
                        return getDropDownButton(item, _isFullPanel);
                      }
                  }
                },
              )
            : getDropDownButton(item, _isFullPanel);
        if (_isFullPanel || item.pinned) {
          list.add(wdiget);
        }
      }
    }

    return list;
  }

  Widget getInputDropdown(MdlListColController colController, bool isFull) {
    List<Map<String, dynamic>> items = [];
    for (var item in colController.valueList ?? []) {
      items.add(item);
    }
    // TextEditingController controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          WgtInputDropdown(
            key:
                UniqueKey(), // prevent reuse of the same widget (and its state)
            hint: colController.filterLabel,
            items: items,
            // if null the widget will use its own controller
            // but if want to control the value from outside the dropdown widget,
            // you can pass a controller
            controller: colController.filterWidgetController,
            initialValue: colController.filterValue,
            isInitialValueMutable: colController.valueList!.length > 1,
            height: 50,
            width: 250,
            onSelected: (Map<String, dynamic>? item) async {
              setState(() {
                colController.filterValue = item;
                if (colController.colKey == 'site_group_label') {
                  MdlPagSiteGroupProfile? selectedSiteGroup = widget
                      .loggedInUser.selectedScope.projectProfile!
                      .getSiteGroupProfileById(item?['value']);
                  _onUpdateSiteGroup(selectedSiteGroup);
                } else if (colController.colKey == 'site_label') {
                  MdlPagSiteProfile? selectedSite = _selectedSiteGroupProfile!
                      .getSiteProfileById(item?['value']);
                  _selectedSiteProfile = _selectedSiteGroupProfile!
                      .getSiteProfileById(item?['value']);
                  _onUpdateSite(selectedSite);
                } else if (colController.colKey == 'building_label') {
                  MdlPagBuildingProfile? selectedBuilding =
                      _selectedSiteProfile!
                          .getBuildingProfileById(item?['value']);
                  _onUpdateBuilding(selectedBuilding);
                } else if (colController.colKey == 'location_group_label') {
                  _onUpdateLocationGroup(_selectedBuildingProfile!
                      .getLocationGroupProfileById(item?['value']));
                }
              });
            },
            onClear: () {
              setState(() {
                if (colController.colKey == 'site_group_label') {
                  _onClearSiteGroup();
                } else if (colController.colKey == 'site_label') {
                  _onClearSite();
                } else if (colController.colKey == 'building_label') {
                  _onClearBuilding();
                } else if (colController.colKey == 'location_group_label') {
                  _onClearLocationGroup();
                }

                _clearResult();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget getDropDownButton(MdlListColController colController, bool isFull) {
    List<Map<String, dynamic>> list = colController.valueList ?? [];
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 5),
      child: SizedBox(
        height: 55,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (isFull) getPin(listColController: colController),
            if (isFull) horizontalSpaceSmall,
            DropdownButton<Map<String, dynamic>>(
              key:
                  UniqueKey(), // prevent reuse of the same widget (and its state)
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text(colController.filterLabel,
                      style: _dropDownListHintStyle)),
              value: colController.filterValue,
              // isDense: true,
              // itemHeight: 55,
              focusColor: Theme.of(context).hoverColor,
              underline: _dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (Map<String, dynamic>? value) async {
                if (value != null) {
                  if (value == colController.filterValue) {
                    return;
                  }
                }
                setState(() {
                  colController.filterValue = value!;
                  _enableSearch = _enableSearchButton();
                });

                widget.onModified?.call();
              },
              items: list.map<DropdownMenuItem<Map<String, dynamic>>>(
                  (Map<String, dynamic> value) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value['label'],
                      style: _dropDownListTextStyle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget getOptions() {
    return Row(
      children: [
        getClearButton(),
        horizontalSpaceRegular,
        getPanelModeButton(),
      ],
    );
  }

  Widget getRowsPerPage() {
    return widget.identifySingleItem || widget.getCountOnly
        ? Container()
        : Tooltip(
            message: 'Records per page',
            waitDuration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_list,
                    size: 21, color: Theme.of(context).hintColor),
                horizontalSpaceSmall,
                DropdownButton<int>(
                  value: _selectedRowsPerPage,
                  focusColor: Theme.of(context).hoverColor,
                  underline: _dropDownUnderline,
                  // dropdownColor: Theme.of(context).colorScheme.background,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 21,
                  style: TextStyle(color: Theme.of(context).hintColor),
                  onChanged: (int? value) {
                    setState(() {
                      _selectedRowsPerPage = value!;
                    });
                  },
                  items: _rowsPerPage.map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Text(value.toString(),
                            style: _dropDownListTextStyle),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
  }

  Widget getPanelModeButton() {
    return IconButton(
      iconSize: 25,
      tooltip: 'Switch mode',
      icon: Icon(_isFullPanel ? Icons.unfold_less : Icons.unfold_more,
          color: Theme.of(context).colorScheme.primary),
      onPressed: () {
        setState(() {
          _isFullPanel = !_isFullPanel;
        });
      },
    );
  }

  Widget getClearButton() {
    return IconButton(
      iconSize: 25,
      tooltip: 'Clear search',
      icon: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.error),
      onPressed: () {
        _clearSearch();
        _iniScopesPreload();
      },
    );
  }

  Widget getSearchButton() {
    return IconButton(
      iconSize: 25,
      tooltip: 'Search',
      icon: Icon(Icons.search,
          color: _enableSearch
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).hintColor.withAlpha(75)),
      onPressed: _enableSearch
          ? () async {
              Map<String, dynamic> itemFindResult = await _getItemList();

              widget.onResult(itemFindResult);
            }
          : null,
    );
  }

  Widget getPin({
    MdlListColController? listColController,
    String? customKey,
    bool? pinned,
    bool? allowUnpin,
  }) {
    String key = customKey ?? listColController!.colKey;
    bool iniPinned = pinned ?? listColController!.pinned;

    return WgtCustomPin(
      name: '${listName}_$key',
      initialPinned: iniPinned,
      onUpdatePinned: (bool pinned) {
        if (allowUnpin != null && !allowUnpin) {
          return;
        }
        listColController!.pinned = pinned;
        _saveCustomize();
      },
    );
  }

  Widget getCollapseButton() {
    return IconButton(
      iconSize: 25,
      // tooltip: 'Hide search panel',
      icon: Icon(Symbols.expand_circle_up,
          color: Theme.of(context).colorScheme.primary),
      onPressed: () {
        setState(() {
          _showPanel = false;
          widget.onShowPanel?.call(false);
        });
      },
    );
  }
}

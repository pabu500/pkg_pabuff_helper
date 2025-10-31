import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_tariff_package_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_am_meter_group_assignment.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_group_assignment2.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_soa2.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/wgt_pag_tenant_usage_summary.dart';
import 'package:buff_helper/up_helper/enum/enum_item.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_empty_result_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/show_model_bottom_sheet.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:provider/provider.dart';

import '../../comm/comm_list.dart';
import '../../model/mdl_pag_app_config.dart';
import '../app/ems/wgt_match_payment_op_item.dart';
import '../app/fh/wgt_fh_device_health.dart';
import '../job/wgt_job_type_op_panel2.dart';
import 'wgt_item_info_edit_panel.dart';
import 'wgt_list_pane.dart';
import 'wgt_pag_item_finder_flexi.dart';
import '../app/ems/wgt_tariff_package_assignment.dart';
import '../app/ems/wgt_tenant_assignment.dart';
import 'dart:developer' as dev;

class WgtListSearchItemFlexi extends StatefulWidget {
  const WgtListSearchItemFlexi({
    super.key,
    required this.appConfig,
    required this.pagAppContext,
    required this.itemKind,
    required this.prefKey,
    required this.listContextType,
    this.itemType,
    this.listController,
    this.selectedItemInfoList,
    this.onListInfoListResult,
    this.onResult,
    this.additionalColumnConfig,
    this.itemTypeListStr,
    this.enablePaneModeSwitcher = false,
    this.getPaneWidget,
    this.getSwitcher,
    this.paneHeight = 820,
    this.finderRefreshKey,
    this.onScopeTreeUpdate,
    this.validateTreeChildren,
    this.isCompactFinder = false,
    this.isSingleItemMode = false,
    this.showList = true,
    this.width,
    this.showTimeRangePicker = false,
    this.timeRangePickerWidget,
    this.initialFilterMap = const {},
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext? pagAppContext;
  final PagItemKind itemKind;
  final dynamic itemType;
  final PagListContextType listContextType;
  final String prefKey;
  final MdlPagListController? listController;
  final List<Map<String, dynamic>>? selectedItemInfoList;
  final Function(List<MdlPagListController>)? onListInfoListResult;
  final Function(Map<String, dynamic>)? onResult;
  final List<Map<String, dynamic>>? additionalColumnConfig;
  final String? itemTypeListStr;
  final bool enablePaneModeSwitcher;
  final double paneHeight;
  final Widget Function(Map<String, dynamic>, List<Map<String, dynamic>>)?
      getPaneWidget;
  final Widget Function(
          Map<String, dynamic>, List<Map<String, dynamic>>, Function onPressed)?
      getSwitcher;
  final UniqueKey? finderRefreshKey;
  final Function? onScopeTreeUpdate;
  final Function? validateTreeChildren;
  final bool isCompactFinder;
  final bool isSingleItemMode;
  final bool showList;
  final double? width;
  final bool showTimeRangePicker;
  final Widget? timeRangePickerWidget;
  final Map<String, dynamic> initialFilterMap;

  @override
  State<WgtListSearchItemFlexi> createState() => _WgtListSearchItemFlexiState();
}

class _WgtListSearchItemFlexiState extends State<WgtListSearchItemFlexi> {
  late final MdlPagUser? loggedInUser;

  late final listPrefix = widget.itemKind.name.toLowerCase();

  bool _isFetchingListInfo = false;
  bool _isFetchingItemList = false;
  bool _showEmptyResult = false;
  String _errorText = '';

  final List<MdlPagListController> _listControllerList = [];
  late final List<Map<String, dynamic>> _entityItems = [];
  MdlPagListController? _selectedListController;

  int _totalItemCount = 0;
  int _currentPage = 1;
  int _maxRowsPerPage = 20;
  String? _sortBy;
  String? _sortOrder;
  UniqueKey? _finderRefreshKey;
  UniqueKey? _listContentRefreshKey;
  UniqueKey? _listKey;
  Map<String, dynamic> _queryMap = {};

  bool _itemUpdated = false;

  late final bool isEditableByAcl;

  final List<String> meterTypeList = [];

  int _failedPullListInfo = 0;

  bool _meterUsageColumnExists = false;
  bool _tenantUsageColumnExists = false;
  bool _viewBillColumnExists = false;
  bool _viewSoAColumnExists = false;
  bool _matchPaymentColumnExists = false;
  bool _deviceHealthColumnExists = false;

  Future<dynamic> _getListInfo() async {
    if (loggedInUser == null) {
      return;
    }

    if (_isFetchingListInfo) {
      return;
    }

    try {
      if (_listControllerList.isEmpty) {
        Map<String, dynamic> queryMap = {
          'scope': loggedInUser!.selectedScope.toScopeMap(),
          'item_kind': widget.itemKind.name,
          'item_type_list_str': widget.itemTypeListStr ?? 'NOT_SET',
          'list_context_type': widget.listContextType.name,
        };

        _isFetchingListInfo = true;

        Map<String, dynamic> data = await getListInfoList(
          widget.appConfig,
          loggedInUser,
          queryMap,
          MdlPagSvcClaim(
            userId: loggedInUser!.id,
            username: loggedInUser!.username,
            scope: '',
            target: '',
            operation: '',
          ),
        );

        if (widget.listContextType == PagListContextType.usage) {
          if (data['meter_type_list'] == null) {
            throw Exception('Failed to get meter type list');
          }
          meterTypeList.clear();
          var meterTypeListJson = data['meter_type_list'];
          for (String meterType in meterTypeListJson) {
            meterTypeList.add(meterType);
          }
        }

        if (data['list_info_list'] == null) {
          throw Exception('Failed to get list info list');
        }

        final listInfoListJson = data['list_info_list'];

        List<Map<String, dynamic>> listInfoList = [];
        if (listInfoListJson != null) {
          for (var item in listInfoListJson) {
            listInfoList.add(item);
          }
        }
        if (listInfoList.isEmpty) {
          throw Exception('list_info_list is empty');
        }

        for (var listInfoMap in listInfoList) {
          MdlPagListController listController =
              MdlPagListController.fromJson(listInfoMap);
          _listControllerList.add(listController);
        }
      }

      if (_listControllerList.isNotEmpty) {
        _selectedListController = _listControllerList[0];

        if (widget.additionalColumnConfig != null &&
            widget.additionalColumnConfig!.isNotEmpty) {
          for (var listConfigMap in widget.additionalColumnConfig!) {
            MdlListColController listColController =
                MdlListColController.fromJson(listConfigMap);

            //skip if the listConfigMap is already in the list
            bool isExist = false;
            for (var listCol
                in _selectedListController!.listColControllerList) {
              if (listCol.colKey == listColController.colKey) {
                isExist = true;
                break;
              }
            }
            if (isExist) {
              continue;
            }

            _selectedListController?.listColControllerList
                .add(listColController);
          }
        }

        for (MdlPagListController listController in _listControllerList) {
          _addPagAppContextColumns(listController);
        }
        // _addPagAppContextColumns();

        _updateCustomize();

        widget.onListInfoListResult?.call(_listControllerList);
      }
    } catch (e) {
      // if (kDebugMode) {
      dev.log(e.toString());
      // }
      _failedPullListInfo++;
      rethrow;
    } finally {
      // rebuild the finder widget after async call
      // to 'persist' the finder widget in the widget tree
      // and avoid additional rebuild due to the async call
      setState(() {
        _isFetchingListInfo = false;
      });
    }
  }

  Future<dynamic> _getItemList() async {
    if (_queryMap.isEmpty) {
      if (kDebugMode) {
        print('queryMap is empty');
      }
      return null;
    }

    setState(() {
      _isFetchingItemList = true;
      _errorText = '';
    });

    _entityItems.clear();

    Map<String, dynamic> itemFindResult = {};
    _queryMap['scope'] = loggedInUser!.selectedScope.toScopeMap();
    _queryMap['current_page'] = '$_currentPage';
    _queryMap['sort_by'] = _sortBy ?? '';
    _queryMap['sort_order'] = _sortOrder;

    try {
      itemFindResult = await fetchItemList(
        loggedInUser,
        widget.appConfig,
        _queryMap,
        MdlPagSvcClaim(
          userId: loggedInUser!.id,
          username: loggedInUser!.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      List<Map<String, dynamic>> itemList = itemFindResult['item_list'];
      for (var item in itemList) {
        _entityItems.add(item);
      }

      setState(() {
        if (_currentPage == 1) {
          _totalItemCount = itemFindResult['count'];
        }
      });

      // widget.onResult?.call({
      //   'item_list': _entityItems,
      //   'count': _totalItemCount,
      //   'current_page': _currentPage,
      // });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    } finally {
      setState(() {
        _isFetchingItemList = false;
      });
    }
  }

  void _resetFinder() {
    setState(() {
      _entityItems.clear();
      _totalItemCount = 0;
      _queryMap = {};
      _currentPage = 1;
      _sortBy = null;
      _sortOrder = 'desc';
    });
  }

  void _addPagAppContextColumns(MdlPagListController? listController) {
    if (widget.pagAppContext == null) {
      return;
    }
    if (listController == null) {
      return;
    }

    bool hasInfoViewEditColumn = false;
    for (var col in listController.listColControllerList) {
      if (col.colKey == 'info') {
        hasInfoViewEditColumn = true;
        break;
      }
    }
    bool hasOpColumn = false;
    for (var col in listController.listColControllerList) {
      if (col.colKey == 'op') {
        hasOpColumn = true;
        break;
      }
    }
    bool hasDetailColumn = false;
    for (var col in listController.listColControllerList) {
      if (col.colKey == 'detail') {
        hasDetailColumn = true;
        break;
      }
    }

    // if (_selectedListController == null) {
    //   return;
    // }

    bool addInfoViewEditColumn = true;
    bool isEmsDeviceLs = widget.pagAppContext! == appCtxEms &&
        widget.itemKind == PagItemKind.device;
    bool isEmsMeterUsage = widget.pagAppContext! == appCtxEms &&
        widget.itemKind == PagItemKind.device &&
        widget.listContextType == PagListContextType.usage;
    bool isEmsTenantUsage = widget.pagAppContext == appCtxEms &&
        widget.itemKind == PagItemKind.tenant &&
        widget.listContextType == PagListContextType.usage;
    bool isBill = widget.itemKind == PagItemKind.bill;
    bool isEsInsights = widget.pagAppContext! == appCtxEs &&
        widget.itemKind == PagItemKind.scope;
    bool isSoa = widget.listContextType == PagListContextType.soa;
    bool isPp = widget.listContextType == PagListContextType.paymentMatching;
    bool isCmDeviceLs = widget.pagAppContext! == appCtxCm &&
        widget.itemKind == PagItemKind.device;
    bool isFhDevice = widget.pagAppContext! == appCtxFh &&
        widget.itemKind == PagItemKind.device;
    bool isPaymentApply =
        widget.listContextType == PagListContextType.paymentApply;
    if (isEmsDeviceLs ||
        isEmsMeterUsage ||
        isEmsTenantUsage ||
        isEsInsights ||
        isBill ||
        isSoa ||
        isPp ||
        isCmDeviceLs ||
        isFhDevice ||
        isPaymentApply) {
      addInfoViewEditColumn = false;
    }
    if (hasInfoViewEditColumn) {
      addInfoViewEditColumn = false;
    }
    bool addOpColumn = false;
    if (widget.itemKind == PagItemKind.jobType ||
        widget.itemKind == PagItemKind.tariffPackage ||
        widget.itemKind == PagItemKind.meterGroup ||
        widget.itemKind == PagItemKind.tenant ||
        widget.listContextType == PagListContextType.paymentMatching) {
      addOpColumn = true;
    }
    if (widget.itemKind == PagItemKind.tenant &&
        widget.listContextType == PagListContextType.soa) {
      addOpColumn = false;
    }
    bool isAmDeviceMeterManager = widget.pagAppContext! == appCtxAm &&
        widget.itemKind == PagItemKind.device &&
        _selectedListController!.itemType == PagDeviceCat.meterGroup;
    if (isAmDeviceMeterManager) {
      addOpColumn = true;
    }

    bool addMeterUsageColumn = false;
    if (isEmsMeterUsage) {
      addMeterUsageColumn = true;
    }
    bool addTenantUsageColumn = false;
    if (isEmsTenantUsage) {
      addTenantUsageColumn = true;
    }
    bool addViewBillColumn = false;
    if (widget.itemKind == PagItemKind.bill &&
        widget.listContextType == PagListContextType.info) {
      addViewBillColumn = true;
    }

    bool addViewSoAColumn = false;
    if (widget.itemKind == PagItemKind.tenant &&
        widget.listContextType == PagListContextType.soa) {
      addViewSoAColumn = true;
    }
    bool addMatchPaymentColumn = false;
    if (widget.listContextType == PagListContextType.paymentMatching) {
      addMatchPaymentColumn = true;
    }
    bool addDeviceHealthColumn = false;
    if (widget.itemKind == PagItemKind.device &&
        widget.listContextType == PagListContextType.fh) {
      addDeviceHealthColumn = true;
    }

    if (hasOpColumn) {
      addOpColumn = false;
    }

    if (addInfoViewEditColumn) {
      _addInfoColumn(listController, addOpColumn);
    }
    if (addOpColumn) {
      _addOpColumn(listController);
    }

    if (addMeterUsageColumn) {
      if (!_meterUsageColumnExists) {
        _addMeterUsageColumn(listController);
      }
      _meterUsageColumnExists = true;
    }
    if (addTenantUsageColumn) {
      _addTenantUsageColumns(listController);
      _tenantUsageColumnExists = true;
    }
    if (addViewBillColumn) {
      _addViewBillColumn(listController);
      _viewBillColumnExists = true;
    }
    if (addViewSoAColumn) {
      _addViewSoAColumn(listController);
      _viewSoAColumnExists = true;
    }
    if (addMatchPaymentColumn) {
      _addMatchPaymentColumn(listController);
      _matchPaymentColumnExists = true;
    }
    if (addDeviceHealthColumn && !hasDetailColumn) {
      _addDeviceHealthColumn(listController);
      _deviceHealthColumnExists = true;
    }
  }

  void _addInfoColumn(MdlPagListController listController, bool addOpColumn) {
    Map<String, dynamic> itemScopeMap = {};

    // populate with project scope for possbile later used by MdlPagScope.fromJson
    itemScopeMap['project_id'] =
        loggedInUser!.selectedScope.projectProfile!.id.toString();
    itemScopeMap['project_name'] =
        loggedInUser!.selectedScope.projectProfile!.name;
    //add property edit column
    MdlListColController appCtxCol = MdlListColController(
      colKey: 'info',
      colTitle: 'Info',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: addOpColumn ? 45 : 35,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        bool allowEdit = true;

        if (widget.itemKind == PagItemKind.user) {
          allowEdit = loggedInUser!.id.toString() != item['id'];
        }

        return Padding(
          padding: EdgeInsets.only(right: addOpColumn ? 21 : 0),
          child: !allowEdit
              ? IconButton(
                  onPressed: null,
                  icon: Icon(
                    Symbols.lock,
                    color: Theme.of(context).hintColor.withAlpha(130),
                  ))
              : IconButton(
                  icon: Icon(
                    isEditableByAcl ? Icons.edit : Symbols.manage_search,
                    color: Theme.of(context).colorScheme.primary.withAlpha(210),
                  ),
                  onPressed: () {
                    List<Map<String, dynamic>> fieldList = [];
                    String displayNameKey = '';

                    for (MdlListColController colController
                        in _selectedListController?.listColControllerList ??
                            []) {
                      if (colController.colKey == 'id') {
                        continue;
                      }
                      if (!colController.includeColKeyAsFilter) {
                        continue;
                      }
                      if (colController.isJoinKey) {
                        // populate itemScopeMap for location filter
                        if (colController.filterGroupType ==
                            PagFilterGroupType.LOCATION) {
                          itemScopeMap[colController.colKey] =
                              item[colController.colKey];
                        }
                        // join key is not directly editable
                        // therefore exlude from the field list
                        continue;
                      }

                      if (colController.colKey == 'op_timestamp' ||
                          colController.colKey == 'username') {
                        colController.isMutable = false;
                      }

                      String widgetType =
                          // colController.editorWidgetType.name.toLowerCase();
                          colController.filterWidgetType.name.toLowerCase();
                      if (widgetType == 'select') {
                        widgetType = 'dropdown';
                      }

                      if (widgetType == 'dropdown') {
                        assert(colController.valueList != null);
                      }
                      // List<String> dropdownValueList = [];
                      List<Map<String, dynamic>> dropdownValueList = [];
                      if ((colController.valueList ?? []).isNotEmpty) {
                        for (var value in colController.valueList!) {
                          // dropdownValueList.add(value['label']);
                          dropdownValueList.add(value);
                        }
                      }

                      dynamic value;
                      if (widgetType == 'dropdown') {
                        if (item[colController.colKey] != null) {
                          for (var v in dropdownValueList) {
                            if (v['value'] == item[colController.colKey]) {
                              value = v;
                              break;
                            }
                          }
                        }
                      } else {
                        value = item[colController.colKey];
                      }

                      fieldList.add({
                        'show': colController.showColumn,
                        'show_edit_panel': colController.showEditPanel,
                        'col_key': colController.colKey,
                        'label': colController.colTitle,
                        'value': value, //item[colController.colKey],
                        'editable': colController.isMutable,
                        'show_copy': true,
                        'widget': widgetType,
                        'type': colController.filterGroupType,
                        'value_list': dropdownValueList,
                      });
                      if (colController.isDisplayNameKey) {
                        displayNameKey = colController.colKey;
                      }
                    }

                    String itemDisplayName = item[displayNameKey] ?? '';
                    // if (widget.itemKind == PagItemKind.tariffPackage) {
                    //   itemDisplayName = item['label'];
                    // }

                    Map<String, dynamic> customProperties = {};
                    if (widget.itemKind == PagItemKind.tariffPackage) {
                      String tpTypeCatStr = item['tpt_cat'] ?? '';
                      PagTariffPackageTypeCat? tpTypeCat =
                          PagTariffPackageTypeCat.byTag(tpTypeCatStr);
                      customProperties = {
                        'tpTypeCat': tpTypeCat,
                      };
                    }

                    xtShowModelBottomSheet(
                      context,
                      WgtPagItemInfoEditPanel(
                        appConfig: widget.appConfig,
                        itemKind: widget.itemKind,
                        itemIndexStr: item['id'],
                        fields: fieldList,
                        itemDisplayName:
                            itemDisplayName, //item[displayNameKey] ?? '',
                        listController: _selectedListController,
                        itemScopeMap: itemScopeMap,
                        itemInfoMap: item,
                        itemType: widget.itemType,
                        onScopeTreeUpdate: widget.onScopeTreeUpdate,
                        validateTreeChildren: widget.validateTreeChildren,
                        customProperties: customProperties,
                        onClose: () {
                          setState(() {
                            _listContentRefreshKey = UniqueKey();
                          });
                        },
                        onUpdate: () {
                          setState(() {
                            _itemUpdated = true;
                          });
                        },
                      ),
                      onClosed: () {
                        if (_itemUpdated) {
                          setState(() {
                            _listContentRefreshKey = UniqueKey();
                            _itemUpdated = false;
                          });
                        }
                      },
                    );
                  },
                ),
        );
      },
    );
    // _selectedListController?.listColControllerList.add(appCtxCol);
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _addOpColumn(MdlPagListController listController) {
    if (widget.itemKind != PagItemKind.jobType &&
        widget.itemKind != PagItemKind.tariffPackage &&
        widget.itemKind != PagItemKind.meterGroup &&
        widget.itemKind != PagItemKind.tenant &&
        widget.itemKind != PagItemKind.device) {
      return;
    }

    Map<String, dynamic> itemScopeMap = {};
    //add property edit column
    MdlListColController appCtxCol = MdlListColController(
      colKey: 'op',
      colTitle: 'Ops',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 35,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        bool allowOps = true;

        IconData opIcon = Symbols.settings_b_roll;
        switch (widget.itemKind) {
          case PagItemKind.jobType:
            opIcon = Symbols.settings_b_roll;
            break;
          case PagItemKind.tariffPackage:
            opIcon = Symbols.assignment;
            if (item['tpt_cat'] == 'system_rate') {
              // system rate is not for assignment
              allowOps = false;
            }
            break;
          case PagItemKind.meterGroup:
            opIcon = Symbols.assignment;
          case PagItemKind.tenant:
            opIcon = Symbols.assignment;
          case PagItemKind.device:
            opIcon = Symbols.assignment;
          default:
            allowOps = false;
        }

        return !allowOps
            ? IconButton(
                onPressed: null,
                icon: Icon(
                  Symbols.lock,
                  color: Theme.of(context).hintColor.withAlpha(130),
                ))
            : Padding(
                padding: const EdgeInsets.only(left: 0),
                child: IconButton(
                  icon: Icon(
                    opIcon,
                    color: Theme.of(context).colorScheme.primary.withAlpha(200),
                  ),
                  onPressed: () {
                    List<Map<String, dynamic>> fieldList = [];
                    String displayNameKey = '';

                    for (MdlListColController colController
                        in _selectedListController?.listColControllerList ??
                            []) {
                      if (colController.colKey == 'id') {
                        continue;
                      }
                      if (!colController.includeColKeyAsFilter) {
                        continue;
                      }
                      if (colController.isJoinKey) {
                        // populate itemScopeMap for location filter
                        if (colController.filterGroupType ==
                            PagFilterGroupType.LOCATION) {
                          itemScopeMap[colController.colKey] =
                              item[colController.colKey];
                        }
                        // joint key is not directly editable
                        // therefore exlude from the field list
                        continue;
                      }

                      String widgetType =
                          // colController.editorWidgetType.name.toLowerCase();
                          colController.filterWidgetType.name.toLowerCase();
                      if (widgetType == 'select') {
                        widgetType = 'dropdown';
                      }

                      if (widgetType == 'dropdown') {
                        assert(colController.valueList != null);
                      }
                      // List<String> dropdownValueList = [];
                      List<Map<String, dynamic>> dropdownValueList = [];
                      if ((colController.valueList ?? []).isNotEmpty) {
                        for (var value in colController.valueList!) {
                          // dropdownValueList.add(value['label']);
                          dropdownValueList.add(value);
                        }
                      }

                      dynamic value;
                      if (widgetType == 'dropdown') {
                        if (item[colController.colKey] != null) {
                          for (var v in dropdownValueList) {
                            if (v['value'] == item[colController.colKey]) {
                              value = v;
                              break;
                            }
                          }
                        }
                      } else {
                        value = item[colController.colKey];
                      }

                      fieldList.add({
                        'col_key': colController.colKey,
                        'label': colController.colTitle,
                        'value': value, //item[colController.colKey],
                        'editable': colController.isMutable,
                        'show_copy': true,
                        'widget': widgetType,
                        'value_list': dropdownValueList,
                      });

                      if (colController.isDisplayNameKey) {
                        displayNameKey = colController.colKey;
                      }
                    }

                    MdlPagScope? jobTypeScope;
                    if (widget.itemKind == PagItemKind.jobType) {
                      item['project_id'] = loggedInUser!
                          .selectedScope.projectProfile!.id
                          .toString();
                      item['project_name'] =
                          loggedInUser!.selectedScope.projectProfile!.name;
                      jobTypeScope = MdlPagScope.fromJson(item);
                    }

                    String? scopeLabel = jobTypeScope?.getLeafScopeLabel();

                    item['project_id'] = loggedInUser!
                        .selectedScope.projectProfile!.id
                        .toString();
                    item['project_name'] =
                        loggedInUser!.selectedScope.projectProfile!.name;
                    MdlPagScope itemScope = MdlPagScope.fromJson(item);

                    Widget opWidget = Container();
                    switch (widget.itemKind) {
                      case PagItemKind.jobType:
                        opWidget = WgtJobTypeOpPanel2(
                          appConfig: widget.appConfig,
                          loggedInUser: loggedInUser!,
                          itemDisplayName: item[displayNameKey] ?? '',
                          jobTypeName: item['name'],
                          jobTaskType: item['task_type'],
                          jobTypeScope: jobTypeScope,
                          jobScopeLabel: scopeLabel,
                          listController: _selectedListController,
                          onScopeTreeUpdate: widget.onScopeTreeUpdate,
                          onClose: () {
                            setState(() {
                              _listContentRefreshKey = UniqueKey();
                            });
                          },
                          onUpdate: () {
                            setState(() {
                              _itemUpdated = true;
                            });
                          },
                        );
                        break;
                      case PagItemKind.tariffPackage:
                        opWidget = WgtTariffPackageAssignment(
                          appConfig: widget.appConfig,
                          itemGroupIndexStr: item['id'],
                          itemName: item['name'],
                          itemLabel: item['label'],
                          meterType: item['meter_type'] ?? '',
                          tariffPackageTypeName:
                              item['tariff_package_type_name'] ?? '',
                          tariffPackageTypeLabel:
                              item['tariff_package_type_label'] ?? '',
                          itemScope: itemScope,
                          onUpdate: () {
                            setState(() {
                              _itemUpdated = true;
                            });
                          },
                        );
                      case PagItemKind.meterGroup:
                        opWidget = WgtMeterGroupAssignment2(
                          appConfig: widget.appConfig,
                          itemGroupIndexStr: item['id'],
                          itemName: item['name'],
                          itemLabel: item['label'] ?? '',
                          meterType: item['meter_type'] ?? '',
                          itemInfo: item,
                          itemScope: itemScope,
                          onUpdate: () {
                            setState(() {
                              _itemUpdated = true;
                            });
                          },
                        );
                      case PagItemKind.tenant:
                        opWidget = WgtTenantpAssignment(
                          appConfig: widget.appConfig,
                          itemGroupIndexStr: item['id'],
                          itemName: item['name'],
                          itemLabel: item['label'] ?? '',
                          itemScope: itemScope,
                          onUpdate: () {
                            setState(() {
                              _itemUpdated = true;
                            });
                          },
                        );
                      case PagItemKind.device:
                        _selectedListController?.itemType ==
                                PagDeviceCat.meterGroup
                            ? opWidget = WgtAmMeterGroupAssignment(
                                appConfig: widget.appConfig,
                                meterType: item['meter_type'] ?? '',
                                itemGroupIndexStr: item['id'],
                                itemName: item['name'],
                                itemLabel: item['label'] ?? '',
                                itemScope: itemScope,
                                onUpdate: () {
                                  setState(() {
                                    _itemUpdated = true;
                                  });
                                },
                              )
                            : Container();
                        break;
                      default:
                        opWidget = Container();
                    }

                    xtShowModelBottomSheet(
                      context,
                      opWidget,
                      onClosed: () {
                        if (_itemUpdated) {
                          setState(() {
                            _listContentRefreshKey = UniqueKey();
                            _itemUpdated = false;
                          });
                        }
                      },
                    );
                  },
                ),
              );
      },
    );
    // _selectedListController?.listColControllerList.add(appCtxCol);
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _addMeterUsageColumn(MdlPagListController listController) {
    //add property edit column
    MdlListColController appCtxCol = MdlListColController(
      colKey: 'first_reading_timestamp',
      colTitle: 'first reading time',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 150,
      colWidgetType: PagColWidgetType.TEXT,
    );
    listController.listColControllerList.add(appCtxCol);

    appCtxCol = MdlListColController(
      colKey: 'last_reading_timestamp',
      colTitle: 'last reading time',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 150,
      colWidgetType: PagColWidgetType.TEXT,
    );
    listController.listColControllerList.add(appCtxCol);

    appCtxCol = MdlListColController(
      colKey: 'first_reading_value',
      colTitle: 'first reading',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 110,
      colWidgetType: PagColWidgetType.TEXT,
      align: 'right',
      useComma: true,
    );
    listController.listColControllerList.add(appCtxCol);

    appCtxCol = MdlListColController(
      colKey: 'last_reading_value',
      colTitle: 'last reading',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 110,
      colWidgetType: PagColWidgetType.TEXT,
      align: 'right',
      useComma: true,
    );
    listController.listColControllerList.add(appCtxCol);

    appCtxCol = MdlListColController(
      colKey: 'usage',
      colTitle: 'usage',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 90,
      colWidgetType: PagColWidgetType.TEXT,
      align: 'right',
      useComma: true,
    );
    listController.listColControllerList.add(appCtxCol);
  }

  void _addTenantUsageColumns(MdlPagListController listController) {
    for (String meterType in meterTypeList) {
      MdlListColController appCtxCol = MdlListColController(
        colKey: 'usage_${meterType.toLowerCase()}',
        colTitle: 'usage_${meterType.toLowerCase()}',
        includeColKeyAsFilter: false,
        showColumn: true,
        colWidth: 90,
        colWidgetType: PagColWidgetType.TEXT,
        align: 'right',
        useComma: true,
      );
      listController.listColControllerList.insert(0, appCtxCol);
    }

    MdlListColController appCtxCol = MdlListColController(
      colKey: 'detail',
      colTitle: ' ',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 35,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        bool showDetail = false;
        final tenantUsageSummary = item['tenant_usage_summary'];
        if (tenantUsageSummary != null && tenantUsageSummary.isNotEmpty) {
          final meterGroupUsageList =
              tenantUsageSummary['meter_group_usage_list'];
          if (meterGroupUsageList != null && meterGroupUsageList.isNotEmpty) {
            final meterGroupUsageSummary0 = meterGroupUsageList.first;
            if (meterGroupUsageSummary0 != null &&
                meterGroupUsageSummary0.isNotEmpty) {
              final meterGroupUsageSummary =
                  meterGroupUsageSummary0['meter_group_usage_summary'];
              if (meterGroupUsageSummary != null &&
                  meterGroupUsageSummary.isNotEmpty) {
                final meterUsageList =
                    meterGroupUsageSummary['meter_usage_list'];
                if (meterUsageList != null && meterUsageList.isNotEmpty) {
                  final meterUsageList0 = meterUsageList.first;
                  if (meterUsageList0 != null && meterUsageList0.isNotEmpty) {
                    showDetail = true;
                  }
                }
              }
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(right: 0),
          child: IconButton(
            icon: Icon(
              Symbols.pageview,
              color: showDetail
                  ? Theme.of(context).colorScheme.primary.withAlpha(200)
                  : Theme.of(context).hintColor.withAlpha(130),
            ),
            onPressed: !showDetail
                ? null
                : () {
                    List<Map<String, dynamic>> fieldList = [];
                    String displayNameKey = '';

                    DateTime fromDatetime =
                        DateTime.tryParse(_queryMap['from_timestamp'])!;
                    DateTime toDatetime =
                        DateTime.tryParse(_queryMap['to_timestamp'])!;

                    PagEmsTypeUsageCalc emsTypeUsageCalc = PagEmsTypeUsageCalc(
                      costDecimals: 2,
                      // gst: gst,
                      // typeRates: typeRates,
                      usageFactor: {
                        'E': 1.0,
                        'W': 1.0,
                        'B': 1.0,
                        'N': 1.0,
                        'G': 1.0
                      },
                      autoUsageSummary: item['tenant_usage_summary'],
                      // subTenantUsageSummary: subTenantListUsageSummary,
                      // manualUsageList: manualUsage,
                      // lineItemList: lineItems,
                      // billBarFromMonth: billBarFromMonth,
                      //use billed trending snapshot
                      // billedTrendingSnapShot: billedTrendingSnapShot,
                    );
                    emsTypeUsageCalc.doCalc();

                    xtShowModelBottomSheet(
                      context,
                      WgtPagTenantUsageSummary(
                        costDecimals: 2,
                        appConfig: widget.appConfig,
                        loggedInUser: loggedInUser!,
                        displayContextStr: '',
                        usageCalc: emsTypeUsageCalc,
                        isBillMode: false,
                        showRenderModeSwitch: true,
                        itemType: ItemType.meter_iwow,
                        isMonthly: false,
                        fromDatetime: fromDatetime,
                        toDatetime: toDatetime,
                        tenantName: item['name'],
                        tenantLabel: item['label'],
                        tenantAccountId: item['account_number'],
                        tenantType: '',
                        tenantUsageSummary: tenantUsageSummary,
                        // subTenantListUsageSummary: subTenantListUsageSummary,
                        // manualUsages: manualUsage,
                        // lineItems: lineItems,
                        // excludeAutoUsage: _bill['exclude_auto_usage'] == 'true'
                        //     ? true
                        //     : false,
                        excludeAutoUsage: false,
                        // typeRates: typeRates,
                      ),
                      onClosed: () {},
                    );
                  },
          ),
        );
      },
    );
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _addViewBillColumn(MdlPagListController listController) {
    MdlListColController appCtxCol = MdlListColController(
      colKey: 'detail',
      colTitle: 'Bill',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 45,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        bool showDetail = true;
        return Padding(
          padding: const EdgeInsets.only(right: 0),
          child: InkWell(
            onTap: !showDetail
                ? null
                : () {
                    xtShowModelBottomSheet(
                      context,
                      WgtPagCompositeBillView(
                        costDecimals: 2,
                        appConfig: widget.appConfig,
                        loggedInUser: loggedInUser!,
                        billingRecIndexStr: item['id'],
                        defaultBillLcStatusStr: item['lc_status'],
                        modes: item['lc_status'] == 'released' ||
                                item['lc_status'] == 'pv'
                            ? const ['wgt', 'pdf']
                            : const ['wgt'],
                        genTypes: item['lc_status'] == 'released' ||
                                item['lc_status'] == 'pv'
                            ? const ['generated', 'released']
                            : const ['generated'],
                        onUpdate: () {
                          setState(() {
                            _itemUpdated = true;
                          });
                        },
                      ),
                      onClosed: () async {
                        // Map<String, dynamic> itemFindResult =
                        //     await _getItemList();
                        // widget.onResult?.call(itemFindResult);
                        if (_itemUpdated) {
                          setState(() {
                            _listContentRefreshKey = UniqueKey();
                            _itemUpdated = false;
                          });
                        }
                      },
                    );
                  },
            child: Icon(
              Symbols.request_quote,
              color: showDetail
                  ? Theme.of(context).colorScheme.primary.withAlpha(200)
                  : Theme.of(context).hintColor.withAlpha(130),
            ),
          ),
        );
      },
    );
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _addViewSoAColumn(MdlPagListController listController) {
    MdlListColController appCtxCol = MdlListColController(
      colKey: 'detail',
      colTitle: 'SoA',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 45,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        bool showDetail = true;
        return Padding(
          padding: const EdgeInsets.only(right: 0),
          child: InkWell(
            onTap: !showDetail
                ? null
                : () {
                    xtShowModelBottomSheet(
                      context,
                      WgtTenantSoA2(
                        appConfig: widget.appConfig,
                        loggedInUser: loggedInUser!,
                        pagAppContext: widget.pagAppContext!,
                        teneantInfo: item,
                      ),
                      onClosed: () {},
                    );
                  },
            child: Icon(
              Symbols.contract,
              color: showDetail
                  ? Theme.of(context).colorScheme.primary.withAlpha(200)
                  : Theme.of(context).hintColor.withAlpha(130),
            ),
          ),
        );
      },
    );
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _addMatchPaymentColumn(MdlPagListController listController) {
    MdlListColController appCtxCol = MdlListColController(
      colKey: 'detail',
      colTitle: 'Match',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 45,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        return WgtPaymentMatchOpItem(
          appConfig: widget.appConfig,
          loggedInUser: loggedInUser!,
          paymentMatchInfo: item,
          tenantInfo: {
            'tenant_id': item['tenant_id'],
            'tenant_name': item['tenant_name'],
            'tenant_label': item['tenant_label'],
          },
          regFresh: (doRefreshItem) {
            item['is_comm'] = doRefreshItem;
          },
          onUpdate: () {
            setState(() {
              _itemUpdated = true;
            });
          },
          onClosed: () async {
            if (_itemUpdated) {
              setState(() {
                _listContentRefreshKey = UniqueKey();
                _itemUpdated = false;
              });
            }
          },
        );
      },
    );
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _addDeviceHealthColumn(MdlPagListController listController) {
    PagDeviceCat? deviceCat = listController.itemType;
    assert(deviceCat != null);

    MdlListColController appCtxCol = MdlListColController(
      colKey: 'detail',
      colTitle: ' ',
      includeColKeyAsFilter: false,
      showColumn: true,
      colWidth: 35,
      colWidgetType: PagColWidgetType.CUSTOM,
      getCustomWidget: (item, fullList) {
        return Padding(
          padding: const EdgeInsets.only(right: 0),
          child: IconButton(
            icon: Icon(Symbols.pageview,
                color: Theme.of(context).colorScheme.primary.withAlpha(200)),
            iconSize: 30,
            onPressed: () {
              xtShowModelBottomSheet(
                  context,
                  WgtFhDeviceHealth(
                    appConfig: widget.appConfig,
                    loggedInUser: loggedInUser!,
                    deviceCat: deviceCat!,
                    deviceInfo: item,
                  ),
                  onClosed: () {},
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13.0, vertical: 3));
            },
          ),
        );
      },
    );
    listController.listColControllerList.insert(0, appCtxCol);
  }

  void _updateCustomize() {
    if (_selectedListController == null) {
      return;
    }
    dynamic listCustmize = readFromSharedPref(widget.prefKey);
    Map<String, dynamic> colCustomize = json.decode(listCustmize ?? '{}');

    for (MdlListColController item
        in _selectedListController?.listColControllerList ?? []) {
      if (colCustomize.containsKey(item.colKey)) {
        item.showColumn = colCustomize[item.colKey];
      }
    }
  }

  String _getListPrefix() {
    String prefix = widget.itemKind.name.toLowerCase();

    if (widget.itemType != null) {
      prefix += '_${widget.itemType}'.toLowerCase();
    }

    prefix += '_${widget.listContextType.name}';

    if (_queryMap['from_timestamp'] != null) {
      String filenameSafeFromTimestamp =
          getFilenameSafeDateTimeStrFromDateTimeStr(
              _queryMap['from_timestamp']);
      prefix += '_$filenameSafeFromTimestamp';
    }
    if (_queryMap['to_timestamp'] != null) {
      String filenameSafeToTimestamp =
          getFilenameSafeDateTimeStrFromDateTimeStr(_queryMap['to_timestamp']);
      prefix += '_$filenameSafeToTimestamp';
    }
    return prefix;
  }

  @override
  void initState() {
    super.initState();
    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
    // _finderRefreshKey = UniqueKey();
    bool isAtProjectLevel =
        loggedInUser!.selectedScope.isAtScopeType(PagScopeType.project);
    bool isAdmin = loggedInUser!.selectedRole?.isAdmin() ?? false;
    isEditableByAcl = isAdmin || isAtProjectLevel;

    if (widget.listController != null) {
      _selectedListController = widget.listController;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.finderRefreshKey != null) {
      if (_finderRefreshKey != widget.finderRefreshKey) {
        _finderRefreshKey = widget.finderRefreshKey;
        // Future.delayed(const Duration(milliseconds: 100), () async {
        //   await _getListInfo();
        // });
        _resetFinder();
      }
    }

    if (_listContentRefreshKey != null) {
      if (_listContentRefreshKey != _listKey) {
        _listKey = _listContentRefreshKey;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await _getItemList();
        });
      }
    }

    if (_failedPullListInfo > 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              getErrorTextPrompt(
                  context: context, errorText: 'Error getting list info'),
            ],
          ),
        ],
      );
    }

    bool fetchListInfo = _failedPullListInfo <= 3 &&
        _listControllerList.isEmpty &&
        !_isFetchingListInfo;

    if (widget.listController != null) {
      fetchListInfo = false;
      _selectedListController = widget.listController;
      _addPagAppContextColumns(_selectedListController!);
    }

    return SingleChildScrollView(
      // put the result widget as part of the loading widget
      // to avoid additional rebuild
      child: Column(
        children: [
          fetchListInfo
              ? FutureBuilder(
                  future: _getListInfo(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        if (kDebugMode) {
                          print('getListInfo ...');
                        }
                        return const SizedBox(
                          height: 130,
                          // width: 130,
                          child: Center(child: WgtPagWait()),
                        );
                      default:
                        if (snapshot.hasError) {
                          if (kDebugMode) {
                            print(snapshot.error);
                          }
                          return getErrorTextPrompt(
                              context: context, errorText: 'Serivce Error');
                        } else {
                          if (kDebugMode) {
                            print('FutureBuilder -> getCompletedWidget');
                          }
                          return getCompletedWidget();
                        }
                    }
                  })
              : getCompletedWidget(),
        ],
      ),
    );
  }

  Widget getCompletedWidget() {
    // assert(_selectedListController != null);
    if (widget.listController != null) {
      _selectedListController = widget.listController;
    }

    if (_selectedListController == null) {
      return Container();
    }

    return Column(children: [
      verticalSpaceTiny,
      // if (_selectedListController != null)
      WgtPagItemFinderFlexi(
        key: _finderRefreshKey, //_listContentRefreshKey,
        width: widget.width,
        loggedInUser: loggedInUser!,
        appConfig: widget.appConfig,
        itemKind: widget.itemKind,
        itemType: _selectedListController!.itemType,
        listContextType: widget.listContextType,
        listController: _selectedListController!,
        selectedItemInfoList: widget.selectedItemInfoList,
        isCompactMode: widget.isCompactFinder,
        isSingleItemMode: widget.isSingleItemMode,
        meterTypeList: meterTypeList,
        // right padding as clerance for context menu
        sidePadding: const EdgeInsets.only(left: 0, right: 60),
        showTimeRangePicker: widget.showTimeRangePicker,
        timeRangePickerWidget: widget.timeRangePickerWidget,
        initialFilterMap: widget.initialFilterMap,
        onSearching: () {
          setState(() {
            _isFetchingItemList = true;
          });
        },
        onClearSearch: () {
          _resetFinder();
        },
        onModified: () {
          _resetFinder();
        },
        onResult: (Map<String, dynamic> itemFindResult) {
          if (itemFindResult['error'] != null) {
            setState(() {
              _isFetchingItemList = false;
              _errorText = itemFindResult['error'];
            });
            return;
          }
          _errorText = '';

          if (_listControllerList.isEmpty) {
            if (itemFindResult['list_config'] == null) {
              setState(() {
                _isFetchingItemList = false;
                _errorText = 'Failed to get list config';
              });
              return;
            }

            for (var config in itemFindResult['list_config']) {
              _listControllerList.add(MdlPagListController.fromJson(config));
            }
          }

          if (_currentPage == 1) {
            _totalItemCount = itemFindResult['count'];
          }
          _entityItems.clear();
          _entityItems.addAll(itemFindResult['item_list']);

          setState(() {
            _totalItemCount = itemFindResult['count'];

            // copy the query map from the item finder
            _queryMap = itemFindResult['query_map'];

            _maxRowsPerPage = int.parse(_queryMap['max_rows_per_page'] ?? '20');

            if (_totalItemCount == 0) {
              _showEmptyResult = true;
            } else {
              _showEmptyResult = false;
            }
            _isFetchingItemList = false;
          });

          setState(() {
            _isFetchingItemList = false;
          });

          widget.onResult?.call(itemFindResult);
        },
      ),
      verticalSpaceRegular,
      _isFetchingItemList
          ? const WgtPagWait()
          : _errorText.isNotEmpty
              ? getErrorTextPrompt(context: context, errorText: _errorText)
              : _entityItems.isEmpty
                  ? _queryMap.isEmpty
                      ? Container()
                      : getEmptyResultPrompt(
                          context: context, emptyResultText: 'No result found')
                  : getResultList()
    ]);
  }

  Widget getResultList() {
    if (!widget.showList) {
      return Container();
    }
    if (_selectedListController == null) {
      return getErrorTextPrompt(
          context: context, errorText: 'List Controller not found');
    }

    if (widget.enablePaneModeSwitcher &&
        (widget.getPaneWidget == null /*|| widget.getSwitcher == null*/)) {
      return Container();
    }

    // if (widget.finderRefreshKey != null) {
    //   return Container();
    // }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 60),
        child: WgtListPane(
          appConfig: widget.appConfig,
          enablePaneModeSwitcher: widget.enablePaneModeSwitcher,
          initialItemList: _entityItems,
          queryMap: _queryMap,
          totalItemCount: _totalItemCount,
          listController: _selectedListController!,
          getPaneWidget: widget.getPaneWidget,
          getSwitcher: widget.getSwitcher ?? getPaneModeSwitcher,
          sectionName: widget.prefKey,
          paneHeight: widget.paneHeight,
          itemType: widget.itemType,
          listPrefix: _getListPrefix(),
          onResult: (Map<String, dynamic> result) {
            widget.onResult?.call(result);
          },
        ),
      ),
    );
  }

  Widget getPaneModeSwitcher(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> fullList,
    Function onPressed,
  ) {
    return InkWell(
      child: Icon(
        Symbols.pageview,
        color: Theme.of(context).colorScheme.primary.withAlpha(200),
      ),
      onTap: () {
        onPressed(item, fullList);
      },
    );
  }
}

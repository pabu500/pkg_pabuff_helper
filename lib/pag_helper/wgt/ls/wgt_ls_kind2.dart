import 'dart:convert';

import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_history.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_type_selector.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:provider/provider.dart';
import '../../def_helper/dh_device.dart';
import '../../def_helper/dh_pag_finance.dart';
import '../../model/mdl_pag_app_config.dart';
import '../../wgt/history_presentor/wgt_pag_item_history_presenter.dart';
import 'wgt_ls_item_flexi.dart';
import 'dart:developer' as dev;

class WgtListSearchKind2 extends StatefulWidget {
  const WgtListSearchKind2({
    super.key,
    required this.appConfig,
    required this.itemKind,
    required this.pagAppContext,
    required this.listContextType,
    required this.prefKey,
    this.iniItemType,
    this.selectedItemInfoList,
    this.onResult,
    this.additionalColumnConfig,
    this.onScopeTreeUpdate,
    this.isSingleItemMode = false,
    this.isCompactFinder = false,
    this.showList = true,
    this.onItemTypeSelected,
    this.width,
    this.allowChangeItemType = true,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext pagAppContext;
  final PagItemKind itemKind;
  final PagListContextType listContextType;
  final List<Map<String, dynamic>>? selectedItemInfoList;
  final Function(Map<String, dynamic>)? onResult;
  final dynamic iniItemType;
  final String prefKey;
  final List<Map<String, dynamic>>? additionalColumnConfig;
  final Function? onScopeTreeUpdate;
  final bool isSingleItemMode;
  final bool isCompactFinder;
  final bool showList;
  final Function(dynamic)? onItemTypeSelected;
  final double? width;
  final bool allowChangeItemType;

  @override
  State<WgtListSearchKind2> createState() => _WgtListSearchKind2State();
}

class _WgtListSearchKind2State extends State<WgtListSearchKind2> {
  final double paneWidth = 850;
  final double paneHeight = 830;

  late final MdlPagUser? loggedInUser;
  late final prefKey = widget.pagAppContext.route;
  late final String itemTypeListStr;

  bool _listInfoFetched = false;
  final List<MdlPagListController> _listControllerList = [];
  MdlPagListController? _selectedListController;
  String _displayNameKey = '';

  late final List<Map<String, dynamic>> _itemTypeInfoList = [];

  UniqueKey? _itemTypeRefreshKey;

  String _listTypeErrorText = '';

  void _updateItemType({dynamic itemType}) {
    dev.log('Updating item type: $itemType');
    if (itemType == null) {
      _selectedListController = null;
      widget.onItemTypeSelected?.call(null);
      setState(() {});
      return;
    }
    if (_listControllerList.isEmpty) {
      _listTypeErrorText = 'No list info available';
      setState(() {});
      return;
    }

    try {
      for (var listController in _listControllerList) {
        if (_getItemTypeStr(itemType) ==
            _getItemTypeStr(listController.itemType)) {
          _selectedListController = listController;
          break;
        }
      }
      if (_selectedListController == null) {
        throw Exception('ListConfig not found for item type: $itemType');
      }

      _displayNameKey = _selectedListController?.getDisplayNameKey() ?? '';
      if (_displayNameKey.isEmpty) {
        _displayNameKey =
            _selectedListController?.listColControllerList.first.colKey ?? '';
      }
      assert(_displayNameKey.isNotEmpty);

      // update col pref
      _loadColPref();

      widget.onItemTypeSelected?.call(_selectedListController?.itemType);

      setState(() {});
    } catch (e) {
      dev.log(e.toString());

      _listTypeErrorText = 'Error getting list type';
    }
  }

  void _updateItemTypeListStatus({dynamic itemType}) {
    for (Map<String, dynamic> itemTypeInfo in _itemTypeInfoList) {
      dynamic itemType = itemTypeInfo['item_type'];

      bool itemTypeListInfoFound = false;
      for (MdlPagListController listController in _listControllerList) {
        String listControllerItemTypeStr = '';
        String itemTypeStr = '';
        if (itemType is PagDeviceCat) {
          itemTypeStr = itemType.name;
          listControllerItemTypeStr =
              (listController.itemType as PagDeviceCat).name;
        } else if (itemType is PagScopeType) {
          itemTypeStr = itemType.name;
          listControllerItemTypeStr =
              (listController.itemType as PagScopeType).name;
        } else if (itemType is PagFinanceType) {
          itemTypeStr = itemType.name;
          listControllerItemTypeStr =
              (listController.itemType as PagFinanceType).name;
        } else {
          throw Exception('Unsupported item type: ${itemType.runtimeType}');
        }
        // if (listController.itemType == itemType) {
        if (listControllerItemTypeStr == itemTypeStr) {
          itemTypeListInfoFound = true;
          break;
        }
      }
      if (itemTypeListInfoFound) {
        itemTypeInfo['list_info_available'] = true;
      } else {
        itemTypeInfo['list_info_available'] = false;
      }
    }
  }

  String? _getItemTypePref() {
    String itemTypePrefKey = '${widget.prefKey}_${widget.itemKind.name}';
    String? itemTypeStr = readFromSharedPref(itemTypePrefKey);
    if (itemTypeStr == 'null' || itemTypeStr == null) {
      return null;
    }
    return itemTypeStr;
  }

  void _loadColPref() {
    if (widget.iniItemType != null) {
      return;
    }

    if (_selectedListController == null) {
      return;
    }
    dynamic listCustmize = readFromSharedPref(widget.prefKey);
    Map<String, dynamic> colCustomize = json.decode(listCustmize ?? '{}');

    for (MdlListColController item
        in _selectedListController!.listColControllerList) {
      if (colCustomize.containsKey(item.colKey)) {
        item.showColumn = colCustomize[item.colKey];
      }
    }
  }

  void _saveItemTypePref() {
    String? itemTypeStr = _getItemTypeStr(_selectedListController?.itemType);
    String itemTypePrefKey = '${widget.prefKey}_${widget.itemKind.name}';
    saveToSharedPref(itemTypePrefKey, itemTypeStr);
  }

  String? _getItemTypeStr(dynamic itemType) {
    if (itemType is PagDeviceCat) {
      // return getPagDeviceTypeStr(itemType);
      return itemType.name;
    } else if (itemType is PagScopeType) {
      return getPagScopeTypeStr(itemType);
    } else if (itemType is PagFinanceType) {
      return getPagFinanceTypeStr(itemType);
    } else {
      throw Exception('Unsupported item type: ${itemType.runtimeType}');
    }
  }

  @override
  void initState() {
    super.initState();
    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _itemTypeInfoList.clear();
    List<String> itemTypeList = [];
    if (loggedInUser!.selectedScope.projectProfile != null) {
      if (widget.itemKind == PagItemKind.device) {
        for (Map<String, dynamic> itemType
            in loggedInUser!.selectedScope.projectProfile!.deviceTypeInfoList) {
          String deviceTypeStr = itemType.keys.first;
          PagDeviceCat deviceType = PagDeviceCat.byValue(deviceTypeStr);
          _itemTypeInfoList.add({'item_type': deviceType});
          itemTypeList.add(deviceType.name);
        }
      } else if (widget.itemKind == PagItemKind.scope) {
        _itemTypeInfoList.add({'item_type': PagScopeType.siteGroup});
        _itemTypeInfoList.add({'item_type': PagScopeType.site});
        _itemTypeInfoList.add({'item_type': PagScopeType.building});
        _itemTypeInfoList.add({'item_type': PagScopeType.locationGroup});
        _itemTypeInfoList.add({'item_type': PagScopeType.location});

        for (Map<String, dynamic> scopeTypeInfo in _itemTypeInfoList) {
          PagScopeType scopeType = scopeTypeInfo['item_type'];
          itemTypeList.add(scopeType.name);
        }
      } else if (widget.itemKind == PagItemKind.finance) {
        _itemTypeInfoList.add({'item_type': PagFinanceType.tenantSoa});
        _itemTypeInfoList.add({'item_type': PagFinanceType.payment});

        for (Map<String, dynamic> financeTypeInfo in _itemTypeInfoList) {
          PagFinanceType financeType = financeTypeInfo['item_type'];
          itemTypeList.add(financeType.value);
        }
      } else {
        throw Exception('Unsupported item kind: ${widget.itemKind.name}');
      }
    }

    assert(_itemTypeInfoList.isNotEmpty);

    itemTypeList.sort();
    itemTypeListStr = itemTypeList.join(',');
  }

  @override
  Widget build(BuildContext context) {
    bool enablePaneModeSwitcher = false;
    if (widget.pagAppContext == appCtxEms &&
        widget.itemKind == PagItemKind.device &&
        widget.listContextType == PagListContextType.info) {
      enablePaneModeSwitcher = true;
    }
    if (widget.pagAppContext == appCtxCm &&
        widget.listContextType == PagListContextType.info) {
      enablePaneModeSwitcher = true;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          WgtItemTypeSelector(
            pagAppContext: appCtxAm,
            appConfig: widget.appConfig,
            itemKind: PagItemKind.device,
            prefKey: 'item_type',
            iniItemType: widget.iniItemType,
            allowChangeItemType: widget.allowChangeItemType,
            onGetListInfoListResult: (lisInfoList) {
              _listControllerList.clear();
              _listControllerList.addAll(lisInfoList);
              _updateItemTypeListStatus();

              _updateItemType(itemType: widget.iniItemType);

              setState(() {
                _listInfoFetched = true;
              });
            },
            onItemTypeSelected: (itemType) {
              setState(() {
                _updateItemType(itemType: itemType);
              });
            },
          ),
          verticalSpaceTiny,
          if (_selectedListController != null && _listTypeErrorText.isEmpty)
            WgtListSearchItemFlexi(
              appConfig: widget.appConfig,
              width: widget.width,
              // key: _itemTypeFreshKey,
              isCompactFinder: widget.isCompactFinder,
              isSingleItemMode: widget.isSingleItemMode,
              showList: widget.showList,
              finderRefreshKey: _itemTypeRefreshKey,
              pagAppContext: widget.pagAppContext,
              itemKind: widget.itemKind,
              // itemType: _selectedItemType,
              listController: _selectedListController,
              selectedItemInfoList: widget.selectedItemInfoList,
              prefKey: prefKey,
              listContextType: widget.listContextType,
              additionalColumnConfig: widget.additionalColumnConfig,
              itemTypeListStr: itemTypeListStr,
              enablePaneModeSwitcher: enablePaneModeSwitcher,
              getPaneWidget: getPaneWidget,
              // getSwitcher: getPaneModeSwitcher,
              onScopeTreeUpdate: widget.onScopeTreeUpdate,
              onResult: (result) {
                // Handle the result here
                widget.onResult?.call(result);
              },
            ),
        ],
      ),
    );
  }

  Widget getPaneWidget(
      Map<String, dynamic> item, List<Map<String, dynamic>> fullList) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).hintColor,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        width: paneWidth,
        height: paneHeight,
        child: getHisotryPresentor(item));
  }

  Widget getHisotryPresentor(Map<String, dynamic> item) {
    if (item.isEmpty) {
      return Center(
        child: Text(
          'Please select an item',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor.withAlpha(50),
          ),
        ),
      );
    }

    dynamic itemSubTypeStr = item['meter_type'] ?? item['sensor_type'] ?? '';
    dynamic itemSubType = item['meter_type'] != null
        ? getMeterType(itemSubTypeStr)
        : getSensorType(itemSubTypeStr);

    String displayTitle = item[_displayNameKey] ?? '-';
    if (item['location_label'] != null) {
      displayTitle = '$displayTitle @ ${item['location_label']}';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Device Reading History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        verticalSpaceSmall,
        WgtPagItemHistoryPresenter(
          key: UniqueKey(),
          appConfig: widget.appConfig,
          width: paneWidth - 21,
          height: paneHeight - 60,
          itemKind: PagItemKind.device,
          itemType: _selectedListController!.itemType,
          itemSubType: itemSubType,
          loggedInUser: loggedInUser!,
          historyType: PagItemHistoryType.DEVICE_READING,
          displayId: displayTitle,
          itemId: item['id'],
          itemIdType: ItemIdType.id,
          borderColor: Theme.of(context).hintColor.withAlpha(50),
        ),
      ],
    );
  }
}

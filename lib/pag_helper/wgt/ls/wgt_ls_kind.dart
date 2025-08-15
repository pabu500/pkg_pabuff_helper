import 'dart:convert';

import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_history.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:provider/provider.dart';
import '../../def_helper/dh_device.dart';
import '../../def_helper/dh_pag_finance_type.dart';
import '../../model/mdl_pag_app_config.dart';
import '../../wgt/history_presentor/wgt_pag_item_history_presenter.dart';
import 'wgt_ls_item_flexi.dart';

class WgtListSearchKind extends StatefulWidget {
  const WgtListSearchKind({
    super.key,
    required this.appConfig,
    required this.itemKind,
    required this.pagAppContext,
    required this.listContextType,
    required this.prefKey,
    this.itemType,
    this.selectedItemInfoList,
    this.onResult,
    this.additionalColumnConfig,
    this.onScopeTreeUpdate,
    this.isSingleItemMode = false,
    this.isCompactFinder = false,
    this.onItemTypeSelected,
    this.width,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext pagAppContext;
  final PagItemKind itemKind;
  final PagListContextType listContextType;
  final List<Map<String, dynamic>>? selectedItemInfoList;
  final Function(Map<String, dynamic>)? onResult;
  final dynamic itemType;
  final String prefKey;
  final List<Map<String, dynamic>>? additionalColumnConfig;
  final Function? onScopeTreeUpdate;
  final bool isSingleItemMode;
  final bool isCompactFinder;
  final Function(dynamic)? onItemTypeSelected;
  final double? width;

  @override
  State<WgtListSearchKind> createState() => _WgtListSearchKindState();
}

class _WgtListSearchKindState extends State<WgtListSearchKind> {
  final double paneWidth = 850;
  final double paneHeight = 830;

  late final MdlPagUser? loggedInUser;
  late final prefKey = widget.pagAppContext.route;
  late final String itemTypeListStr;

  bool _listInfoFetched = false;
  final List<MdlPagListController> _listControllerList = [];
  MdlPagListController? _selectedListController;
  String _displayNameKey = '';
  String? _labelKey;

  late final List<Map<String, dynamic>> _itemTypeInfoList = [];
  dynamic _selectedItemType;
  UniqueKey? _itemTypeRefreshKey;

  String _listTypeErrorText = '';

  void _updateItemType({dynamic itemType}) {
    _selectedListController = null;

    // NOTE: keep the order of the following 2 if
    if (itemType != null) {
      if (_selectedItemType == itemType) {
        return;
      }
    }
    if (_selectedItemType != null) {
      if (itemType != null) {
        _selectedItemType = itemType;
      }
    }
    ////////////////////////////////////////

    if (_listControllerList.isEmpty) {
      if (kDebugMode) {
        print('ListConfigList is empty');
      }
      return;
    }

    bool itemTypeFound = false;
    String itemTypeStr = '';
    if (itemType != null) {
      _selectedItemType = itemType;
      if (itemType is PagDeviceCat) {
        itemTypeStr = itemType.name;
      } else if (itemType is PagScopeType) {
        itemTypeStr = itemType.name;
      } else if (itemType is PagFinanceType) {
        itemTypeStr = itemType.name;
      } else {
        throw Exception('Unsupported item type: ${itemType.runtimeType}');
      }
      itemTypeFound = true;
    } else {
      // use the first item from _listControllerList
      dynamic itemType = _getItemTypePref() ?? _listControllerList[0].itemType;
      if (itemType is String) {
        itemTypeStr = itemType;
      } else if (itemType is PagDeviceCat) {
        itemTypeStr = itemType.value;
      } else if (itemType is PagScopeType) {
        itemTypeStr = itemType.key;
      } else if (itemType is PagFinanceType) {
        itemTypeStr = itemType.name;
      } else {
        throw Exception('Unsupported item type: ${itemType.runtimeType}');
      }
      // else if (itemType is PagDeviceCat) {
      //   itemTypeStr = itemType.value;
      // }
      // itemTypeStr = itemTypeStr.toLowerCase();

      if (widget.itemKind == PagItemKind.device) {
        _selectedItemType = PagDeviceCat.values.byName(itemTypeStr);
        itemTypeFound = true;
      } else if (widget.itemKind == PagItemKind.scope) {
        _selectedItemType = PagScopeType.byKey(itemTypeStr);
        itemTypeFound = true;
      } else if (widget.itemKind == PagItemKind.finance) {
        _selectedItemType = PagFinanceType.byValue(itemTypeStr);
        itemTypeFound = true;
      } else {
        throw Exception('Unsupported item kind: ${widget.itemKind.name}');
      }

      assert(itemTypeStr.isNotEmpty);
    }
    if (itemTypeFound) {
      _itemTypeRefreshKey = UniqueKey();
    }

    // String itemTypeStr = '';
    // if (itemType is PagDeviceType) {
    //   itemTypeStr = itemType.name;
    // } else if (itemType is PagScopeType) {
    //   itemTypeStr = itemType.name;
    // }

    try {
      for (var listController in _listControllerList) {
        // if (widget.itemKind == PagItemKind.device) {
        //   if (getPagDeviceTypeStr(listController.itemType) == itemTypeStr) {
        //     _selectedListController = listController;
        //     break;
        //   }
        // } else if (widget.itemKind == PagItemKind.scope) {
        //   if (getPagScopeTypeStr(listController.itemType) == itemTypeStr) {
        //     _selectedListController = listController;
        //     break;
        //   }
        // } else if (widget.itemKind == PagItemKind.finance) {
        //   if (getPagFinanceTypeStr(listController.itemType) == itemTypeStr) {
        //     _selectedListController = listController;
        //     break;
        //   }
        // } else {
        //   throw Exception('Unsupported item kind: ${widget.itemKind.name}');
        // }
        if (itemTypeStr == _getItemTypeStr(listController.itemType)) {
          _selectedListController = listController;
          break;
        }
      }
      if (_selectedListController == null) {
        throw Exception('ListConfig not found for item type: $itemTypeStr');
      }

      _displayNameKey = _selectedListController?.getDisplayNameKey() ?? '';
      if (_displayNameKey.isEmpty) {
        _displayNameKey =
            _selectedListController?.listColControllerList.first.colKey ?? '';
      }
      assert(_displayNameKey.isNotEmpty);

      // update col pref
      _loadColPref();

      widget.onItemTypeSelected?.call(_selectedItemType);

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _listTypeErrorText = 'Error getting list type';
    }
  }

  void _updateItemTypeListStatus() {
    for (Map<String, dynamic> itemTypeInfo in _itemTypeInfoList) {
      dynamic itemType = itemTypeInfo['item_type'];
      // if (itemType is PagDeviceCat) {
      //   itemType = itemType.name;
      // } else if (itemType is PagScopeType) {
      //   itemType = itemType.name;
      // } else if (itemType is PagFinanceType) {
      //   itemType = itemType.name;
      // } else {
      //   throw Exception('Unsupported item type: ${itemType.runtimeType}');
      // }
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
      return getPagDeviceTypeStr(itemType);
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
        _itemTypeInfoList.add({'item_type': PagFinanceType.soa});
        _itemTypeInfoList.add({'item_type': PagFinanceType.payment});

        for (Map<String, dynamic> financeTypeInfo in _itemTypeInfoList) {
          PagFinanceType financeType = financeTypeInfo['item_type'];
          itemTypeList.add(financeType.name);
        }
      } else {
        throw Exception('Unsupported item kind: ${widget.itemKind.name}');
      }
    }

    assert(_itemTypeInfoList.isNotEmpty);

    itemTypeList.sort();
    itemTypeListStr = itemTypeList.join(',');

    _selectedItemType = widget.itemType ?? _itemTypeInfoList[0]['item_type'];
  }

  @override
  Widget build(BuildContext context) {
    bool enablePaneModeSwitcher = widget.pagAppContext == appCtxEms &&
        widget.listContextType == PagListContextType.info;
    return SingleChildScrollView(
      child: Column(
        children: [
          getItemTypeList(),
          verticalSpaceTiny,
          if (_selectedItemType != null)
            WgtListSearchItemFlexi(
              appConfig: widget.appConfig,
              width: widget.width,
              // key: _itemTypeFreshKey,
              isCompactFinder: widget.isCompactFinder,
              isSingleItemMode: widget.isSingleItemMode,
              finderRefreshKey: _itemTypeRefreshKey,
              pagAppContext: widget.pagAppContext,
              itemKind: widget.itemKind,
              itemType: _selectedItemType,
              selectedItemInfoList: widget.selectedItemInfoList,
              prefKey: prefKey,
              listContextType: widget.listContextType,
              additionalColumnConfig: widget.additionalColumnConfig,
              itemTypeListStr: itemTypeListStr,
              enablePaneModeSwitcher: enablePaneModeSwitcher,
              getPaneWidget: getPaneWidget,
              // getSwitcher: getPaneModeSwitcher,
              listController: _selectedListController,
              onScopeTreeUpdate: widget.onScopeTreeUpdate,
              onListInfoListResult: (lisInfoList) {
                _listControllerList.clear();
                _listControllerList.addAll(lisInfoList);
                _updateItemTypeListStatus();
                _updateItemType();
                setState(() {
                  _listInfoFetched = true;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget getItemTypeList() {
    if (!_listInfoFetched) {
      return Container();
    }
    List<Widget> itemTypeList = [];
    if (_itemTypeInfoList.isNotEmpty) {
      for (Map<String, dynamic> itemTypeInfo in _itemTypeInfoList) {
        dynamic itemType = itemTypeInfo['item_type'];
        String itemTypeStr = '';
        String selectedItemTypeStr = '';
        if (itemType is PagDeviceCat) {
          itemTypeStr = itemType.name;
          selectedItemTypeStr = (_selectedItemType as PagDeviceCat).name;
        } else if (itemType is PagScopeType) {
          itemTypeStr = itemType.name;
          selectedItemTypeStr = (_selectedItemType as PagScopeType).name;
        } else if (itemType is PagFinanceType) {
          itemTypeStr = itemType.name;
          selectedItemTypeStr = (_selectedItemType as PagFinanceType).name;
        } else {
          throw Exception('Unsupported item type: ${itemType.runtimeType}');
        }

        Color color = itemTypeStr == selectedItemTypeStr
            ? pag3.withAlpha(230)
            : Theme.of(context)
                .colorScheme
                .secondary
                .withAlpha(210); //Theme.of(context).hintColor;

        bool listInfoAvailable = itemTypeInfo['list_info_available'] ?? false;
        if (!listInfoAvailable) {
          color = Theme.of(context).hintColor.withAlpha(50);
        }

        itemTypeList.add(
          InkWell(
            onTap: !listInfoAvailable
                ? null
                : () {
                    setState(() {
                      _updateItemType(itemType: itemType);
                    });
                    _saveItemTypePref();
                  },
            child: Tooltip(
              message: itemTypeStr,
              waitDuration: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: itemType is PagDeviceCat
                    ? Icon(
                        itemType.iconData,
                        color: Theme.of(context).colorScheme.onSecondary,
                      )
                    : itemType is PagScopeType
                        ? Icon(
                            itemType.iconData,
                            color: Theme.of(context).colorScheme.onSecondary,
                          )
                        : itemType is PagFinanceType
                            ? Icon(
                                itemType.iconData,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              )
                            : itemType is String
                                ? Text(
                                    itemType,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                    ),
                                  )
                                : Icon(
                                    Symbols.help,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                  ),
              ),
            ),
          ),
        );
      }
    } else {
      itemTypeList.add(
        Text(
          'No Item Type available',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...itemTypeList,
      ],
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

  // Widget getPaneModeSwitcher(
  //   Map<String, dynamic> item,
  //   List<Map<String, dynamic>> fullList,
  //   Function onPressed,
  // ) {
  //   return InkWell(
  //     child: Icon(
  //       Symbols.pageview,
  //       color: Theme.of(context).colorScheme.primary.withAlpha(200),
  //     ),
  //     onTap: () {
  //       onPressed(item, fullList);
  //     },
  //   );
  // }

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

    dynamic itemSubTypeStr = item['meter_type'] ?? '';
    dynamic itemSubType = getMeterType(itemSubTypeStr);

    String displayTitle = item[_displayNameKey];
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
        // Divider(
        //     height: 2,
        //     indent: 5,
        //     endIndent: 5,
        //     color: Theme.of(context).hintColor.withOpacity(0.55)),
        verticalSpaceSmall,
        WgtPagItemHistoryPresenter(
          key: UniqueKey(),
          appConfig: widget.appConfig,
          width: paneWidth - 21,
          height: paneHeight - 60,
          itemKind: PagItemKind.device,
          itemType: _selectedItemType!,
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

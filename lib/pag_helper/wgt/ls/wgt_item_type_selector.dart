import 'dart:async';
import 'dart:math';

import 'package:buff_helper/pag_helper/comm/comm_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;

class WgtItemTypeSelector extends StatefulWidget {
  const WgtItemTypeSelector({
    super.key,
    required this.pagAppContext,
    required this.appConfig,
    this.itemTypeListStr,
    this.listContextType = PagListContextType.info,
    required this.itemKind,
    required this.prefKey,
    this.iniItemType,
    this.allowChangeItemType = true,
    this.onGetListInfoListResult,
    this.onItemTypeSelected,
  });

  final MdlPagAppContext pagAppContext;
  final MdlPagAppConfig appConfig;
  final String? itemTypeListStr;
  final PagListContextType listContextType;
  final PagItemKind itemKind;
  final String prefKey;
  final dynamic iniItemType;
  final bool allowChangeItemType;
  final Function? onGetListInfoListResult;
  final Function? onItemTypeSelected;

  @override
  State<WgtItemTypeSelector> createState() => _WgtItemTypeSelectorState();
}

class _WgtItemTypeSelectorState extends State<WgtItemTypeSelector> {
  late final MdlPagUser? loggedInUser;

  bool _isFetchingListInfo = false;
  bool _listInfoFetched = false;
  int _failedPullListInfo = 0;
  String _listTypeErrorText = '';
  final List<MdlPagListController> _listControllerList = [];
  MdlPagListController? _selectedListController;
  String _displayNameKey = '';
  late final List<Map<String, dynamic>> _itemTypeInfoList = [];
  UniqueKey? _itemTypeRefreshKey;
  dynamic _selectedItemType;

  Future<dynamic> _getListInfo() async {
    if (loggedInUser == null) {
      return;
    }

    if (_isFetchingListInfo || _listInfoFetched) {
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

        if (data['list_info_list'] == null) {
          throw Exception('Failed to get list info list');
        }

        final listInfoListJson = data['list_info_list'];

        // List<Map<String, dynamic>> listInfoList = [];
        _itemTypeInfoList.clear();
        if (listInfoListJson != null) {
          for (var item in listInfoListJson) {
            _itemTypeInfoList.add(item);
          }
        }
        if (_itemTypeInfoList.isEmpty) {
          throw Exception('list_info_list is empty');
        }

        for (var listInfoMap in _itemTypeInfoList) {
          listInfoMap['item_kind'] = widget.itemKind.name;
          MdlPagListController listController =
              MdlPagListController.fromJson(listInfoMap);
          _listControllerList.add(listController);
        }
      }

      widget.onGetListInfoListResult?.call(_listControllerList);
    } catch (e) {
      dev.log(e.toString());
      _failedPullListInfo++;
      rethrow;
    } finally {
      // rebuild the finder widget after async call
      // to 'persist' the finder widget in the widget tree
      // and avoid additional rebuild due to the async call
      setState(() {
        _isFetchingListInfo = false;
        _listInfoFetched = true;
      });
    }
  }

  void _updateItemType(dynamic itemType) {
    dev.log('updating item type: $itemType');

    _selectedItemType = itemType;
    for (var listController in _listControllerList) {
      if (listController.itemType == itemType) {
        _selectedListController = listController;
        break;
      }
    }

    // setState(() {});
    widget.onItemTypeSelected?.call(_selectedItemType);
  }

  String? _getItemTypePref() {
    String itemTypePrefKey = '${widget.prefKey}_${widget.itemKind.name}';
    String? itemTypeStr = readFromSharedPref(itemTypePrefKey);
    if (itemTypeStr == 'null' || itemTypeStr == null) {
      return null;
    }
    return itemTypeStr;
  }

  void _saveItemTypePref() {
    String? itemTypeStr = getItemTypeStr(_selectedListController?.itemType);
    String itemTypePrefKey = '${widget.prefKey}_${widget.itemKind.name}';
    saveToSharedPref(itemTypePrefKey, itemTypeStr);
  }

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
    _selectedItemType = widget.iniItemType;
  }

  @override
  Widget build(BuildContext context) {
    bool fetchListInfo = _failedPullListInfo <= 3 &&
        _listControllerList.isEmpty &&
        !_isFetchingListInfo;

    if (_selectedItemType != widget.iniItemType) {
      if (!widget.allowChangeItemType) {
        _selectedItemType = widget.iniItemType;
        Timer(Duration.zero, () {
          widget.onItemTypeSelected?.call(_selectedItemType);
        });
        //   for (var listController in _listControllerList) {
        //     if (listController.itemType == _selectedItemType) {
        //       _selectedListController = listController;
        //       break;
        //     }
        //   }
      }
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
                        dev.log('getListInfo ...');

                        return const SizedBox(
                          height: 130,
                          // width: 130,
                          child: Center(child: WgtPagWait()),
                        );
                      default:
                        if (snapshot.hasError) {
                          dev.log(snapshot.error.toString());

                          return getErrorTextPrompt(
                              context: context, errorText: 'Serivce Error');
                        } else {
                          dev.log('FutureBuilder -> getCompletedWidget');

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
    return Column(children: [
      getItemTypeList(),
      if (_selectedItemType == null)
        Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: getEmptyInfoBox(),
        ),
    ]);
  }

  Widget getItemTypeList() {
    if (!_listInfoFetched) {
      return Container();
    }
    final selectedItemTypeStr = getItemTypeStr(_selectedItemType);

    List<Widget> itemTypeList = [];
    if (_itemTypeInfoList.isNotEmpty) {
      for (Map<String, dynamic> itemTypeInfo in _itemTypeInfoList) {
        final itemTypeStr = itemTypeInfo['item_type'];

        Color color = itemTypeStr == selectedItemTypeStr
            ? pag3.withAlpha(230)
            : Theme.of(context)
                .colorScheme
                .secondary
                .withAlpha(210); //Theme.of(context).hintColor;

        bool enabled = true;

        bool listInfoAvailable = itemTypeInfo['list_info_available'] ?? true;

        if (listInfoAvailable == false) {
          enabled = false;
        }
        if (!widget.allowChangeItemType) {
          if (itemTypeStr != selectedItemTypeStr) {
            enabled = false;
          }
        }

        if (!enabled) {
          color = Theme.of(context).hintColor.withAlpha(50);
        }

        dynamic itemType;
        if (widget.itemKind == PagItemKind.device) {
          itemType = PagDeviceCat.values.byName(itemTypeStr);
        } else if (widget.itemKind == PagItemKind.scope) {
          itemType = PagScopeType.byKey(itemTypeStr);
        } else if (widget.itemKind == PagItemKind.finance) {
          itemType = PagFinanceType.byValue(itemTypeStr);
        } else {
          throw Exception('Unsupported item kind: ${widget.itemKind.name}');
        }

        itemTypeList.add(
          InkWell(
            onTap: !enabled
                ? null
                : () {
                    setState(() {
                      _updateItemType(itemType);
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
                            : widget.itemKind is String
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

  Widget getEmptyInfoBox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).hintColor,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Center(
            child: Text(
              'Select an item type',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

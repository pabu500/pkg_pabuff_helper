import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../model/mdl_pag_app_config.dart';
import 'wgt_pag_edit_commit_list.dart';
import 'dart:developer' as dev;

enum ListPaneMode { list, pane }

class WgtListPane extends StatefulWidget {
  const WgtListPane({
    super.key,
    required this.appConfig,
    required this.initialItemList,
    required this.totalItemCount,
    required this.queryMap,
    required this.listController,
    this.getPaneWidget,
    this.getSwitcher,
    required this.sectionName,
    this.enablePaneModeSwitcher = false,
    this.listPrefix = 'item',
    this.initialListPaneMode = ListPaneMode.list,
    this.paneHeight,
    this.itemType,
    this.onResult,
  });

  final MdlPagAppConfig appConfig;
  final List<Map<String, dynamic>> initialItemList;
  final Map<String, dynamic> queryMap;
  final MdlPagListController listController;
  final Widget Function(Map<String, dynamic>, List<Map<String, dynamic>>)?
      getPaneWidget;
  final Widget Function(
    Map<String, dynamic>,
    List<Map<String, dynamic>>,
    Function onPressed,
  )? getSwitcher;
  final String sectionName;
  final ListPaneMode? initialListPaneMode;
  final int totalItemCount;
  final bool enablePaneModeSwitcher;
  final String listPrefix;
  final double? paneHeight;
  final dynamic itemType;
  final Function(Map<String, dynamic>)? onResult;

  @override
  State<WgtListPane> createState() => _WgtListPaneState();
}

class _WgtListPaneState extends State<WgtListPane> {
  MdlPagUser? loggedInUser;

  late ListPaneMode _listPaneMode;
  MdlListColController? _switcherCol;

  double _listWidth = 0;
  List<String> _colKeyShowList = [];
  bool _isFetchingItemList = false;
  String _errorText = '';
  late final List<Map<String, dynamic>> _entityItems = [];

  Map<String, dynamic> _queryMap = {};
  int _currentPage = 1;
  int _maxRowsPerPage = 20;
  late int _totalItemCount;
  String? _sortBy;
  String? _sortOrder;
  UniqueKey? _refreshKey;
  UniqueKey? _listKey;

  Future<dynamic> _getItemList() async {
    if (_queryMap.isEmpty) {
      dev.log('queryMap is empty');

      return null;
    }

    setState(() {
      _isFetchingItemList = true;
      _errorText = '';
    });

    _entityItems.clear();

    Map<String, dynamic> itemFindResult = {};
    _queryMap['current_page'] = '$_currentPage';
    _queryMap['sort_by'] = _sortBy ?? '';
    _queryMap['sort_order'] = _sortOrder;

    _queryMap['scope'] = loggedInUser!.selectedScope.toScopeMap();

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

      widget.onResult?.call({
        'item_list': _entityItems,
        'count': _totalItemCount,
        'current_page': _currentPage,
      });
    } catch (e) {
      dev.log(e.toString());
    } finally {
      setState(() {
        _isFetchingItemList = false;
        _refreshKey = UniqueKey();
      });
    }
  }

  // void _onSwitcherPressed() {
  //   setState(() {
  //     _listPaneMode = _listPaneMode == ListPaneMode.list
  //         ? ListPaneMode.pane
  //         : ListPaneMode.list;
  //   });
  // }

  void _updateDisplayMode(
      Map<String, dynamic> item, List<Map<String, dynamic>> fullList) {
    bool isItemSelected = item['is_selected'] ?? false;
    if (isItemSelected) {
      return;
      // item['is_selected'] = false;
    } else {
      for (Map<String, dynamic> listItem in fullList) {
        listItem['is_selected'] = false;
      }
      item['is_selected'] = true;
    }

    for (Map<String, dynamic> listItem in fullList) {
      if (listItem['is_selected']) {
        _setPaneMode();
        return;
      }
    }
    // setState(() {
    //   _listPaneMode = ListPaneMode.list;
    // });
  }

  void _setPaneMode() {
    _colKeyShowList.clear();
    double listWidth = 0;
    //get the list of columns with type as IDENTITY to show
    for (MdlListColController col
        in widget.listController.listColControllerList) {
      bool isShowCol =
          col.filterGroupType == PagFilterGroupType.IDENTITY && col.showColumn;
      bool isSwitcherCol =
          col.colKey == 'info' && col.colWidgetType == PagColWidgetType.CUSTOM;
      bool isPaneListCol = col.isPaneKey;
      if (/*isShowCol ||*/ isSwitcherCol || isPaneListCol) {
        _colKeyShowList.add(col.colKey);
        listWidth += col.colWidth;
      }

      if (isSwitcherCol) {
        _switcherCol = col;
      }
    }

    if (_colKeyShowList.isEmpty) {
      if (mounted) {
        showSnackBar(context,
            'At least 1 item identity columns must be shown to enable pane mode');
      }
      setState(() {
        _listPaneMode = ListPaneMode.list;
      });
      return;
    }

    setState(() {
      _listPaneMode = ListPaneMode.pane;
      _listWidth = listWidth + 77;
      //set col title to empty if it is switcher col
      _switcherCol?.colTitle = '';
    });
  }

  void _setListMode() {
    //clear all selected items
    for (Map<String, dynamic> item in _entityItems) {
      item['is_selected'] = false;
    }
    setState(() {
      _listPaneMode = ListPaneMode.list;
      _switcherCol?.colTitle = 'Info';
    });
  }

  @override
  void initState() {
    super.initState();
    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _entityItems.clear();
    _entityItems.addAll(widget.initialItemList);

    _totalItemCount = widget.totalItemCount;

    _queryMap = widget.queryMap;

    if (_entityItems.isNotEmpty) {
      assert(_totalItemCount != 0);
    }

    _listPaneMode = widget.initialListPaneMode!;

    if (widget.enablePaneModeSwitcher) {
      //insert switcher to list controller
      //remove existing switcher with colKey 'info'
      widget.listController.listColControllerList.removeWhere((col) =>
          col.colKey == 'info' && col.colWidgetType == PagColWidgetType.CUSTOM);
      MdlListColController switcherCol = MdlListColController(
          colKey: 'info',
          colTitle: _listPaneMode == ListPaneMode.list ? 'Info' : '',
          includeColKeyAsFilter: false,
          showColumn: true,
          colWidth: 45,
          colWidgetType: PagColWidgetType.CUSTOM,
          getCustomWidget: (item, fullList) {
            return widget.getSwitcher?.call(item, fullList, _updateDisplayMode);
          });
      widget.listController.listColControllerList.insert(0, switcherCol);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _listPaneMode == ListPaneMode.list
        ? getList(ListPaneMode.list)
        : getListPane();
  }

  Widget getList(ListPaneMode listPaneMode) {
    return SizedBox(
      height: (_listPaneMode == ListPaneMode.pane) ? widget.paneHeight : null,
      child: WgtPagEditCommitList(
        key: _refreshKey,
        appConfig: widget.appConfig,
        isFetching: _isFetchingItemList,
        loggedInUser: loggedInUser,
        listController: widget.listController,
        listItems: _entityItems,
        itemType: widget.itemType,
        selectShowColumn: true,
        sectionName: widget.sectionName,
        listPrefix: widget.listPrefix,
        showIndex: true,
        queryMap: _queryMap,
        currentPage: _currentPage,
        maxRowsPerPage: _maxRowsPerPage,
        totalCount: _totalItemCount,
        narrowPaginationBar: listPaneMode == ListPaneMode.pane,
        colKeyShowList: _colKeyShowList,
        onColCustomizeSet: listPaneMode == ListPaneMode.pane
            ? () {
                _setPaneMode();
              }
            : null,
        onPreviousPage: () async {
          setState(() {
            _currentPage--;
          });
          await _getItemList();
        },
        onNextPage: () async {
          setState(() {
            _currentPage++;
          });
          await _getItemList();
        },
        onClickPage: (page) async {
          setState(() {
            _currentPage = page;
          });
          await _getItemList();
        },
        onSort: (sortBy, sortOrder) async {
          setState(() {
            _sortBy = sortBy;
            _sortOrder = sortOrder;
          });
          await _getItemList();
        },
        onRequestRefresh: () {
          setState(() {
            _refreshKey = UniqueKey();
          });
        },
      ),
    );
  }

  Widget getListPane() {
    //find the selected item
    Map<String, dynamic> selectedItem = {};
    for (Map<String, dynamic> item in _entityItems) {
      if (item['is_selected'] ?? false) {
        selectedItem = item;
        break;
      }
    }

    // if (selectedItem.isEmpty) {
    //   return Container();
    // }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.paneHeight,
          width: _listWidth < 80 ? 80 : _listWidth,
          child: Stack(
            children: [
              getList(ListPaneMode.pane),
              Positioned(
                top: 13,
                right: 45,
                child: InkWell(
                  onTap: () {
                    //   _listPaneMode = ListPaneMode.list;
                    //   _switcherCol?.colTitle = 'Info';
                    // });
                    _setListMode();
                  },
                  child: Icon(
                    Symbols.left_panel_open,
                    color: Theme.of(context).hintColor.withAlpha(100),
                  ),
                ),
              ),
            ],
          ),
        ),
        horizontalSpaceSmall,
        widget.getPaneWidget?.call(selectedItem, _entityItems) ?? Container(),
      ],
    );
  }
}

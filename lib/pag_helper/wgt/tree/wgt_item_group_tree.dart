import 'dart:async';

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_job.dart';
import 'package:buff_helper/pag_helper/comm/comm_tariff_package.dart';
import 'package:buff_helper/pag_helper/def_helper/def_item_group.dart';
import 'package:buff_helper/pag_helper/def_helper/def_tree.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/ems/comm_ems.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_tree_element.dart';
import 'package:buff_helper/up_helper/enum/enum_item.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../comm/comm_ems.dart';
import '../../model/mdl_pag_app_config.dart';
import '../job/wgt_new_edit_sub.dart';
import '../app/ems/wgt_new_edit_tariff_rate.dart';

class WgtItemGroupTree extends StatefulWidget {
  const WgtItemGroupTree({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.groupItemId,
    required this.itemGroupType,
    required this.queryMap,
    required this.rootName,
    required this.rootLabel,
    required this.mode, // create, edit, view
    this.allowAddButton = true,
    this.maxHeight = 330,
    this.width = 360,
    this.getTreeData,
    this.groupItemList = const [],
    this.getNodeWidget,
    this.newItemWidget,
    this.newItemNameValidator,
    this.onAddItem,
    this.showCommitted = true,
    this.initalValueMap,
    this.onUpdate,
    this.addButtonLabelSuffix,
    this.validateTreeChildren,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String groupItemId;
  final PagItemGroupType itemGroupType;
  final String rootName;
  final String rootLabel;
  final String mode; // create, edit, view
  final bool allowAddButton;
  final double maxHeight;
  final double width;
  final bool showCommitted;
  final Map<String, dynamic> queryMap;
  final Future<dynamic> Function()? getTreeData;
  final List<Map<String, dynamic>> groupItemList;
  final Widget Function(PagTreeNode)? getNodeWidget;
  final Widget? newItemWidget;
  final String Function(String)? newItemNameValidator;
  final Function(Map<String, dynamic>?)? onAddItem;
  final Map<String, dynamic>? initalValueMap;
  final String? addButtonLabelSuffix;
  final Function(PagTreeNode root, List<Map<String, dynamic>>)? onUpdate;
  final String Function(List<Map<String, dynamic>> children)?
      validateTreeChildren;

  @override
  State<WgtItemGroupTree> createState() => _WgtItemGroupTreeState();
}

class _WgtItemGroupTreeState extends State<WgtItemGroupTree> {
  late final bool isBatchCommit;
  // items are last in first out (stack)
  late final bool isLIFO;

  late String _rootLabel;

  final List<Map<String, dynamic>> _groupItemList = [];
  final List<Map<String, dynamic>> _groupItemListOriginal = [];
  late final PagTreePartType? rootTreePartType;
  late final PagTreePartType? leafTreePartType;
  late final PagTreeNode? rootNode;
  late final TreeController<PagTreeNode> treeController;

  UniqueKey? _treeRefreshKey;

  TreeSearchResult<PagTreeNode>? filter;
  Pattern? searchPattern;

  bool _isFetchingTreeData = false;
  bool _isFetched = false;
  bool _isEditing = false;
  bool _isAdding = false;
  bool _isCommitting = false;
  bool _isModified = false;
  bool _isSearchingNewItemInfo = false;

  String? _editingNodeChildInfoId;

  bool _allowAddButton = false;
  String _addNewItemErrorText = '';
  String _newItemName = '';
  final String newItemHintText = 'Enter new item name';
  final String newItemLabelText = 'New Item';
  Map<String, dynamic>? _newItemInfo;
  int _newItems = 0;

  String _modifyTypeStr = '';

  late bool _showCommitted;
  String _committedMessage = '';
  String _committErrorText = '';

  final int tariffRateDecimal = 4;

  Future<Map<String, dynamic>> _commit() async {
    _committErrorText = '';
    _isCommitting = true;

    Map<String, dynamic> result = {};
    try {
      Map<String, dynamic> querrMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'group_item_id': widget.groupItemId,
        'new_items': _newItems,
        'modify_type': _modifyTypeStr,
        'group_item_list': _groupItemList,
      };
      switch (widget.itemGroupType) {
        case PagItemGroupType.userTenant:
          result = await commitUserTenantList(
            widget.appConfig,
            widget.loggedInUser,
            querrMap,
            MdlPagSvcClaim(
              username: widget.loggedInUser.username,
              userId: widget.loggedInUser.id,
              scope: '',
              target: '',
              operation: 'update',
            ),
          );
          break;
        case PagItemGroupType.jobTypeSub:
          result = await commitJobTypeSubList(
            widget.appConfig,
            widget.loggedInUser,
            querrMap,
            MdlPagSvcClaim(
              username: widget.loggedInUser.username,
              userId: widget.loggedInUser.id,
              scope: '',
              target: '',
              operation: 'update',
            ),
          );
          break;
        case PagItemGroupType.tariffPackageTariffRate:
          for (Map<String, dynamic> item in _groupItemList) {
            if (item['from_timestamp'] == null ||
                item['to_timestamp'] == null) {
              _committErrorText = 'missing from/to date time in the item info';
              return {};
            }
            // remove possible datatime elements
            // as they are not encodable to json
            item.remove('from_datetime');
            item.remove('to_datetime');
          }

          result = await commitTariffPackageTariffRateList(
            widget.appConfig,
            widget.loggedInUser,
            querrMap,
            MdlPagSvcClaim(
              username: widget.loggedInUser.username,
              userId: widget.loggedInUser.id,
              scope: '',
              target: '',
              operation: 'update',
            ),
          );
          break;
        case PagItemGroupType.tariffPackageTenant:
          result = await commitTariffPackageTenantList(
            widget.appConfig,
            querrMap,
            MdlPagSvcClaim(
              username: widget.loggedInUser.username,
              userId: widget.loggedInUser.id,
              scope: '',
              target: '',
              operation: 'update',
            ),
          );
          break;
        default:
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      result['message'] = e.toString();
      _committErrorText = 'Error committing changes';
    } finally {
      _isCommitting = false;
      _showCommitted = true;
      _isFetched = false;
      _allowAddButton = false;
      // _updateOriginal();
    }

    return result;
  }

  Future<dynamic> _fetchTreeData() async {
    if (_isFetchingTreeData) {
      return;
    }

    widget.queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();

    _isFetchingTreeData = true;

    Map<String, dynamic> result = {};
    try {
      switch (widget.itemGroupType) {
        case PagItemGroupType.userTenant:
          result = await _getUserTenantList(widget.queryMap);
          break;
        case PagItemGroupType.jobTypeSub:
          result = await _getJobTypeSubList(widget.queryMap);
          break;
        case PagItemGroupType.tariffPackageTariffRate:
          result = await _getTariffPackageTariffRateList(widget.queryMap);
          break;
        case PagItemGroupType.tariffPackageTenant:
          result = await _getTariffPackageTenantList(widget.queryMap);
          break;
        default:
          break;
      }

      if (result.isNotEmpty) {
        _groupItemList.clear();
        switch (widget.itemGroupType) {
          case PagItemGroupType.userTenant:
            for (var item in result['user_tenant_list']) {
              _groupItemList.add(item);
            }
            break;
          case PagItemGroupType.jobTypeSub:
            for (var item in result['job_type_sub_list']) {
              _groupItemList.add(item);
            }
            break;
          case PagItemGroupType.tariffPackageTariffRate:
            for (var item in result['tariff_package_tariff_rate_list']) {
              _groupItemList.add(item);
            }
            // sort by from_timestamp (String)
            // latest month placed at the bottom
            _groupItemList.sort((a, b) {
              DateTime aFrom = DateTime.parse(a['from_timestamp']);
              DateTime bFrom = DateTime.parse(b['from_timestamp']);
              return aFrom.compareTo(bFrom);
            });
            break;
          case PagItemGroupType.tariffPackageTenant:
            for (var item in result['tariff_package_tenant_list']) {
              _groupItemList.add(item);
            }
            break;
          default:
            break;
        }
      }
      _updateOriginal();
      _populateTree(rootNode!, leafTreePartType!, 1);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    } finally {
      setState(() {
        _isFetchingTreeData = false;
        _isFetched = true;
      });
    }
  }

  Future<dynamic> _getItemInfo() async {
    setState(() {
      _isSearchingNewItemInfo = true;
      _addNewItemErrorText = '';
    });

    // search _newItemName in _groupItems and
    // if found, return error
    for (var item in _groupItemList) {
      if (item['item_name'] == _newItemName || item['name'] == _newItemName) {
        _addNewItemErrorText = 'Item already exists';
        setState(() {
          _isSearchingNewItemInfo = false;
        });
        return;
      }
    }

    try {
      PagItemKind? itemKind;
      switch (widget.itemGroupType) {
        case PagItemGroupType.userTenant:
          itemKind = PagItemKind.tenant;
          break;
        case PagItemGroupType.jobTypeSub:
          itemKind = PagItemKind.jobTypeSub;
          break;
        case PagItemGroupType.tariffPackageTenant:
          itemKind = PagItemKind.tenant;
        default:
          break;
      }
      if (itemKind == null) {
        return;
      }

      Map<String, dynamic> queryMap = {
        "scope": widget.loggedInUser.selectedScope.toScopeMap(),
        "item_kind": itemKind.name,
        "item_id_type": ItemIdType.name.name,
        "item_id_value": _newItemName.trim(),
      };
      _newItemInfo = await getPagItemInfo(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'read',
        ),
      );
      if (_newItemInfo != null) {
        _groupItemList.insert(0, _newItemInfo!);
        _isModified = true;
        _modifyTypeStr = 'add';
        _newItems++;
        _showCommitted = false;
      }
      _isAdding = false;
      // _isEditing = false;

      widget.onAddItem?.call(_newItemInfo);

      rootNode!.children.clear();
      _populateTree(rootNode!, leafTreePartType!, 1);
      _treeRefreshKey = UniqueKey();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      String eMsg = e.toString();
      if (eMsg.contains('Empty') || eMsg.contains('No item record found')) {
        _addNewItemErrorText = 'No item record found';
      }
    } finally {
      setState(() {
        _isSearchingNewItemInfo = false;
      });
    }
  }

  Future<dynamic> _getUserTenantList(Map<String, dynamic> queryMap) async {
    var result = await getUserTenantList(
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
    return result;
  }

  Future<dynamic> _getJobTypeSubList(Map<String, dynamic> queryMap) async {
    var result = await getPagJobTypeSubList(
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
    return result;
  }

  Future<dynamic> _getTariffPackageTariffRateList(
      Map<String, dynamic> queryMap) async {
    var data = await getTariffPackageTariffRateInfo(
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
    return data['tariff_package_tariff_rate_info'];
  }

  Future<dynamic> _getTariffPackageTenantList(
      Map<String, dynamic> queryMap) async {
    var result = await doGetTariffPackageTenantList(
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
    return result;
  }

  Iterable<PagTreeNode> _getChildren(PagTreeNode node) {
    if (filter case TreeSearchResult<PagTreeNode> filter?) {
      return node.children.where(filter.hasMatch);
    }
    return node.children;
  }

  void _populateTree(
      PagTreeNode parantNode, PagTreePartType leafType, int level) {
    // dynamic child = node.child;
    if (parantNode.treePartType == leafType ||
        parantNode.treePartType == PagTreePartType.addButton) {
      return;
    }

    // clear children iteratively
    parantNode.children.clear();

    switch (widget.itemGroupType) {
      case PagItemGroupType.userTenant:
        for (Map<String, dynamic> tenantInfo in _groupItemList) {
          final PagTreeNode tenantNode = PagTreeNode(
            parent: parantNode,
            name: tenantInfo['name'],
            label: tenantInfo['label'],
            child: tenantInfo,
            treePartType: PagTreePartType.tenant,
            level: level,
          );
          parantNode.children.add(tenantNode);
        }
        break;
      case PagItemGroupType.jobTypeSub:
        for (Map<String, dynamic> jobTypeSubInfo in _groupItemList) {
          final PagTreeNode jobTypeSubNode = PagTreeNode(
            parent: parantNode,
            name: jobTypeSubInfo['sub_full_name'] ??
                jobTypeSubInfo['salutation'] ??
                '',
            label: jobTypeSubInfo['sub_email'],
            child: jobTypeSubInfo,
            treePartType: PagTreePartType.jobTypeSub,
            level: level,
          );
          parantNode.children.add(jobTypeSubNode);
        }
        break;
      case PagItemGroupType.tariffPackageTenant:
        for (Map<String, dynamic> tenantInfo in _groupItemList) {
          final PagTreeNode tenantNode = PagTreeNode(
            parent: parantNode,
            name: tenantInfo['name'],
            label: tenantInfo['label'],
            child: tenantInfo,
            treePartType: PagTreePartType.tenant,
            level: level,
          );
          parantNode.children.add(tenantNode);
        }
        break;
      case PagItemGroupType.tariffPackageTariffRate:
        for (Map<String, dynamic> tariffRateInfo in _groupItemList) {
          // no from/to datetime in the tariffRateInfo
          // when get tariff rate info from db
          if (tariffRateInfo['from_datetime'] == null ||
              tariffRateInfo['to_datetime'] == null) {
            if (tariffRateInfo['from_timestamp'] != null &&
                tariffRateInfo['to_timestamp'] != null) {
              DateTime fromDateTime =
                  DateTime.parse(tariffRateInfo['from_timestamp'].toString());
              DateTime toDateTime =
                  DateTime.parse(tariffRateInfo['to_timestamp'].toString());

              tariffRateInfo['from_datetime'] = fromDateTime;
              tariffRateInfo['to_datetime'] = toDateTime;
            }
          }

          DateTime fromDateTime = tariffRateInfo['from_datetime'];
          DateTime toDateTime = tariffRateInfo['to_datetime'];

          double? rate = double.tryParse(tariffRateInfo['rate']);
          String label =
              '${fromDateTime.toString().substring(0, 10)} to ${toDateTime.toString().substring(0, 10)} @Rate:${rate?.toStringAsFixed(tariffRateDecimal)}';
          final PagTreeNode tariffRateNode = PagTreeNode(
            parent: parantNode,
            name: tariffRateInfo['from_datetime'].toString(),
            label: label,
            child: tariffRateInfo,
            treePartType: PagTreePartType.tariffRate,
            level: level,
          );
          parantNode.children.add(tariffRateNode);
        }
      default:
        break;
    }

    if (widget.allowAddButton && _allowAddButton) {
      final PagTreeNode addButtonNode = PagTreeNode(
        parent: parantNode,
        name: 'add',
        label: 'Add ${widget.addButtonLabelSuffix ?? ''}',
        child: null,
        treePartType: PagTreePartType.addButton,
        level: level,
      );
      parantNode.children.add(addButtonNode);
    }

    for (final PagTreeNode child in parantNode.children) {
      _populateTree(child, leafType, level + 1);
    }
  }

  double _getHeight() {
    double nodeHeight = 35;
    double height = nodeHeight; // root node height
    height += _groupItemList.length * 35.0;
    if (widget.allowAddButton && _allowAddButton) {
      height += 35; // add button height
    }
    if (_isAdding || _editingNodeChildInfoId != null) {
      // add item height
      height += widget.itemGroupType == PagItemGroupType.jobTypeSub ? 280 : 80;
    }

    if (_committErrorText.isNotEmpty) {
      height += 50; // error text height
    } else {
      height += 50; // control height
    }

    return 10 + height + 10;
  }

  String? _validateNewItemName(String? value) {
    if (value == null) return 'Please enter a name';

    if (value.isEmpty) {
      return 'Please enter a name';
    }
    if (value.length < 5) {
      return 'Name must be at least 5 characters';
    }

    //check duplicate
    for (var item in _groupItemList) {
      if (item['name'] == value) {
        return 'Item already exists';
      }
    }

    return null;
  }

  void _updateOriginal() {
    // setState(() {
    _groupItemListOriginal.clear();
    _groupItemListOriginal.addAll(_groupItemList);
    // _rePop();
    // });
  }

  void _restoreOriginal() {
    setState(() {
      _isAdding = false;
      _allowAddButton = false;
      _isModified = false;
      _isEditing = false;
      _addNewItemErrorText = '';
      _newItemName = '';
      _isSearchingNewItemInfo = false;
      _newItemInfo = null;
      _newItems = 0;
      _groupItemList.clear();
      _groupItemList.addAll(_groupItemListOriginal);
      _rePop();
    });
  }

  void _rePop() {
    rootNode!.children.clear();
    _populateTree(rootNode!, leafTreePartType!, 1);
    _treeRefreshKey = UniqueKey();
  }

  Map<String, dynamic> _getNextMonthFromToDateTime(
      DateTime lastFromDateTime, DateTime lastToDateTime) {
    Map<String, dynamic> nextFromToDateTime = {};
    int year = lastFromDateTime.year;
    int month = lastFromDateTime.month + 1;
    if (month > 12) {
      month = 1;
      year++;
    }
    int day = lastFromDateTime.day;
    nextFromToDateTime['from_datetime'] = DateTime(year, month, day, 0, 0, 0);
    int nextMonth = month + 1;
    int nextYear = year;
    // NOTE: cycleDay edge cases
    int nextDay = day - 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear = year + 1;
    }
    nextFromToDateTime['to_datetime'] =
        DateTime(nextYear, nextMonth, nextDay, 23, 59, 59);
    return nextFromToDateTime;
  }

  @override
  void initState() {
    super.initState();

    _rootLabel = widget.rootLabel;

    if (widget.itemGroupType == PagItemGroupType.tariffPackageTariffRate) {
      isLIFO = true;
    } else {
      isLIFO = false;
    }
    if (widget.itemGroupType == PagItemGroupType.tariffPackageTariffRate &&
        widget.mode == 'create') {
      isBatchCommit = true;
    } else {
      isBatchCommit = false;
    }

    _groupItemList.addAll(widget.groupItemList);
    _groupItemListOriginal.addAll(widget.groupItemList);

    // generate child id by time
    String rootChildId = 'new_node_${DateTime.now().millisecondsSinceEpoch}';

    switch (widget.itemGroupType) {
      case PagItemGroupType.userTenant:
        rootTreePartType = PagTreePartType.user;
        leafTreePartType = PagTreePartType.tenant;
        rootNode = PagTreeNode(
          parent: null,
          name: widget.rootName,
          label: _rootLabel,
          child: {
            'id': rootChildId,
            'name': widget.rootName,
            'label': widget.rootLabel,
          },
          treePartType: rootTreePartType!,
          level: 0,
        );
        break;
      case PagItemGroupType.jobTypeSub:
        rootTreePartType = PagTreePartType.jobType;
        leafTreePartType = PagTreePartType.jobTypeSub;
        rootNode = PagTreeNode(
          parent: null,
          name: widget.rootName,
          label: _rootLabel,
          child: {
            'id': rootChildId,
            'name': widget.rootName,
            'label': widget.rootLabel,
          },
          treePartType: rootTreePartType!,
          level: 0,
        );
      case PagItemGroupType.tariffPackageTariffRate:
        rootTreePartType = PagTreePartType.tariffPackage;
        leafTreePartType = PagTreePartType.tariffRate;
        rootNode = PagTreeNode(
          parent: null,
          name: widget.rootName,
          label: _rootLabel,
          child: {
            'id': rootChildId,
            'name': widget.rootName,
            'label': widget.rootLabel,
          },
          treePartType: rootTreePartType!,
          level: 0,
        );
      case PagItemGroupType.tariffPackageTenant:
        rootTreePartType = PagTreePartType.tariffPackage;
        leafTreePartType = PagTreePartType.tenant;
        rootNode = PagTreeNode(
          parent: null,
          name: widget.rootName,
          label: _rootLabel,
          child: {
            'id': rootChildId,
            'name': widget.rootName,
            'label': widget.rootLabel,
          },
          treePartType: rootTreePartType!,
          level: 0,
        );
      default:
        break;
    }
    assert(rootTreePartType != null);
    assert(leafTreePartType != null);
    assert(rootNode != null);

    treeController = TreeController<PagTreeNode>(
      roots: [rootNode!],
      childrenProvider: _getChildren,
    )..expandAll();

    _showCommitted = widget.showCommitted;
  }

  @override
  Widget build(BuildContext context) {
    bool fetchTreeData = false;

    if (!_isFetched) {
      fetchTreeData = true;
    }

    return fetchTreeData
        ? FutureBuilder(
            future: _fetchTreeData(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const WgtPagWait();
                default:
                  if (snapshot.hasError) {
                    return getErrorTextPrompt(
                        context: context,
                        errorText: 'Error fetching tree data');
                  } else {
                    return completedWidget();
                  }
              }
            },
          )
        : completedWidget();
  }

  Widget completedWidget() {
    // if (_groupItemList.isEmpty) {
    //   return getErrorTextPrompt(
    //       context: context, errorText: 'No item group data');
    // }

    return Container(
      width: widget.width,
      height: _getHeight(),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          verticalSpaceSmall,
          Expanded(
            child: AnimatedTreeView<PagTreeNode>(
              key: _treeRefreshKey,
              treeController: treeController,
              nodeBuilder:
                  (BuildContext context, TreeEntry<PagTreeNode> entry) {
                return TreeTile(
                  entry: entry,
                  indent: 21,
                  match: filter?.matchOf(entry.node),
                  searchPattern: searchPattern,
                  getNodeWidget: getNodeWidget(),
                );
              },
              duration: const Duration(milliseconds: 10),
              //watchAnimationDurationSetting(context),
            ),
          ),
          getControl(),
          if (_committErrorText.isNotEmpty)
            getErrorTextPrompt(context: context, errorText: _committErrorText),
        ],
      ),
    );
  }

  Widget Function(PagTreeNode) getNodeWidget() {
    if (widget.getNodeWidget != null) {
      return widget.getNodeWidget!;
    }

    return (PagTreeNode node) {
      bool isAddButton = node.treePartType == PagTreePartType.addButton;

      Widget? newItemWidget;
      if (isAddButton && _isAdding) {
        // NOTE: calling getXXX will cause the widget to be rebuilt
        // so only call when needed
        switch (widget.itemGroupType) {
          case PagItemGroupType.jobTypeSub:
            newItemWidget = getJobTypeSub();
            break;
          case PagItemGroupType.tariffPackageTariffRate:
            // NOTE: only called when adding tariff rate
            // in the function there is a increment of from date time
            newItemWidget = getTariffPackageTariffRate();
            break;
          // case PagItemGroupType.tariffPackageTenant:
          //   newItemWidget = getTariffPackageTenant();
          default:
            break;
        }
      }

      Map<String, dynamic>? childInfo;
      for (var item in _groupItemList) {
        // id is from db
        // if batch commit, then id is generated by the widget
        if (item['id'] == node.child?['id']) {
          childInfo = item;
          break;
        }
      }

      bool isLastNode = false;

      // check if the node is the last in the same level
      if (node.parent != null) {
        List<PagTreeNode> children = node.parent!.children;

        if (children.length > 1) {
          PagTreeNode lastChild = children.last;
          // if the last child is add button, then previous child is the last node
          if (lastChild.treePartType == PagTreePartType.addButton) {
            isLastNode = children[children.length - 2].child == node.child;
          } else {
            isLastNode = lastChild.child == node.child;
          }
        }
      }

      bool isClickable = false;
      switch (widget.itemGroupType) {
        case PagItemGroupType.jobTypeSub:
          isClickable = _isEditing &&
              (isAddButton || node.treePartType == PagTreePartType.jobTypeSub);
          break;
        case PagItemGroupType.tariffPackageTariffRate:
          isClickable = _isEditing;
          // not for the root node (tariff package name) while in edit mode
          if (node.treePartType == rootTreePartType! && widget.mode == 'edit') {
            isClickable = false;
          }
          break;
        case PagItemGroupType.tariffPackageTenant:
          isClickable = _isEditing;
          break;
        case PagItemGroupType.userTenant:
          isClickable = _isEditing &&
              (isAddButton || node.treePartType == PagTreePartType.tenant);
        default:
          break;
      }

      bool allowRemove = true;
      if (widget.itemGroupType == PagItemGroupType.tariffPackageTariffRate) {
        // if (widget.mode != 'create' && widget.mode != 'edit') {
        if (widget.mode != 'create') {
          allowRemove = false;
        }
      }

      return isAddButton && !_isEditing
          ? Container(child: const Text('null'))
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              margin: const EdgeInsets.only(top: 3, bottom: 3, right: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: node.child?['edit_type'] == 'update'
                        ? commitColor
                        : node.child?['edit_type'] == 'add'
                            ? Colors.green.withAlpha(210)
                            : node.child?['edit_type'] == 'remove'
                                ? Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withAlpha(55)
                                : Theme.of(context).hintColor.withAlpha(80)),
              ),
              child: isAddButton && _isAdding
                  ? newItemWidget ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: widget.newItemWidget ?? getNewItemInput(),
                          ),
                          horizontalSpaceTiny,
                          InkWell(
                            onTap: _isSearchingNewItemInfo ||
                                    _validateNewItemName(_newItemName) != null
                                ? null
                                : () async {
                                    await _getItemInfo();
                                  },
                            child: Icon(
                              Symbols.search,
                              size: 21,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                  : _editingNodeChildInfoId == (node.child?['id'] ?? '-1')
                      ? getEditingNode(node)
                      : InkWell(
                          onTap:
                              // node.treePartType == rootTreePartType!
                              !isClickable
                                  ? null
                                  : () {
                                      if (isAddButton) {
                                        setState(() {
                                          if (!isBatchCommit) {
                                            _allowAddButton = false;
                                          }
                                          _isAdding = true;
                                        });
                                      } else {
                                        // if (widget.itemGroupType == PagItemGroupType.jobTypeSub)
                                        if (true) {
                                          setState(() {
                                            _editingNodeChildInfoId =
                                                node.child['id'];
                                          });
                                        }
                                      }
                                    },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                node.treePartType.iconData,
                                size: 21,
                                color: isAddButton
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).hintColor,
                              ),
                              horizontalSpaceTiny,
                              Text(
                                node.label,
                                style: TextStyle(
                                  color: childInfo?['edit_type'] == 'remove'
                                      ? Theme.of(context)
                                          .colorScheme
                                          .error
                                          .withAlpha(200)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (allowRemove &&
                                  _isEditing &&
                                  node.treePartType != rootTreePartType! &&
                                  !isAddButton &&
                                  !(isLIFO && !isLastNode) &&
                                  childInfo?['edit_type'] != 'remove')
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        // _groupItemList.remove(node.child);
                                        // node.child['edit_type'] = 'remove';
                                        if (isBatchCommit) {
                                          _groupItemList.remove(childInfo);

                                          if (widget.itemGroupType ==
                                              PagItemGroupType
                                                  .tariffPackageTariffRate) {}
                                        } else {
                                          childInfo?['edit_type'] = 'remove';
                                        }
                                        _isModified = true;
                                        _modifyTypeStr = 'remove';
                                        _showCommitted = false;
                                        _rePop();
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: Icon(
                                        Symbols.do_not_disturb_on,
                                        size: 21,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withAlpha(200),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            );
    };
  }

  Widget getEditingNode(PagTreeNode node) {
    if (node.treePartType == PagTreePartType.addButton) {
      return Container();
    }

    bool allowEditRootLabel = false;
    if (widget.itemGroupType == PagItemGroupType.tariffPackageTariffRate) {
      allowEditRootLabel = true;
    }

    if (node.treePartType == rootTreePartType! && allowEditRootLabel) {
      return getEditRootLabel();
    }

    switch (widget.itemGroupType) {
      case PagItemGroupType.jobTypeSub:
        Map<String, dynamic>? jobTypeSubInfo;
        for (var item in _groupItemList) {
          if (item['id'] == node.child['id']) {
            jobTypeSubInfo = item;
            break;
          }
        }
        return WgtNewEditSub(
          appConfig: widget.appConfig,
          readOnly: !_isEditing,
          width: widget.width - 65,
          jobTypeIdStr: widget.groupItemId,
          initialValueMap: jobTypeSubInfo,
          onUpdate: (editedJobTypeSubInfo) {
            setState(() {
              // _isEditing = true;
              jobTypeSubInfo?.addAll(editedJobTypeSubInfo);
              jobTypeSubInfo?['edit_type'] = 'update';
              // _groupItemList.remove(node.child);
              // _groupItemList.insert(0, editedJobTypeSubInfo);
              _isModified = true;
              _modifyTypeStr = 'update';
              _showCommitted = false;
              _editingNodeChildInfoId = null;

              _rePop();
            });
          },
          onClose: () {
            setState(() {
              _editingNodeChildInfoId = null;
            });
          },
        );
      case PagItemGroupType.tariffPackageTariffRate:
        Map<String, dynamic>? tariffRateInfo;
        for (var item in _groupItemList) {
          if (item['id'] == node.child['id']) {
            tariffRateInfo = item;
            break;
          }
        }
        return WgtNewEditTariffRate(
          appConfig: widget.appConfig,
          readOnly: !_isEditing,
          width: widget.width - 65,
          groupItemId: widget.groupItemId,
          tariffPackageMeterType: widget.initalValueMap?['meter_type'],
          initialValueMap: tariffRateInfo,
          onUpdate: (editedTariffRateInfo) {
            setState(() {
              tariffRateInfo?.addAll(editedTariffRateInfo);
              tariffRateInfo?['edit_type'] = 'update';
              _isModified = true;
              _modifyTypeStr = 'update';
              _showCommitted = false;
              _editingNodeChildInfoId = null;

              _rePop();
            });
          },
          onClose: () {
            setState(() {
              _editingNodeChildInfoId = null;
            });
          },
        );
      default:
        break;
    }

    return Container();
  }

  Widget getEditRootLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: SizedBox(
        width: widget.width - 65,
        child: WgtTextField(
          appConfig: widget.appConfig,
          hintText: 'Enter new root label',
          labelText: 'Root Label',
          initialValue: _rootLabel,
          onChanged: (value) {
            _rootLabel = value;
          },
          validator: (value) {
            if (value == null) return 'Please enter a label';

            if (value.isEmpty) {
              return 'Please enter a label';
            }
            if (value.length < 5) {
              return 'Label must be at least 5 characters';
            }

            return null;
          },
          onEditingComplete: () {
            setState(() {
              // _isEditing = false;
              // _isAdding = false;
              _editingNodeChildInfoId = null;
              rootNode!.label = _rootLabel;
            });
          },
        ),
      ),
    );
  }

  Widget getJobTypeSub() {
    if (widget.itemGroupType != PagItemGroupType.jobTypeSub) {
      return Container();
    }

    return WgtNewEditSub(
      appConfig: widget.appConfig,
      width: widget.width - 65,
      jobTypeIdStr: widget.groupItemId,
      onInsert: (newJobTypeSubInfo) {
        setState(() {
          newJobTypeSubInfo['edit_type'] = 'add';
          _groupItemList.insert(0, newJobTypeSubInfo);
          _isModified = true;
          _modifyTypeStr = 'add';
          _newItems++;
          _showCommitted = false;

          _isAdding = false;
          _rePop();
        });
      },
      onClose: () {
        setState(() {
          _isAdding = false;
          _allowAddButton = true;
        });
      },
    );
  }

  Widget getTariffPackageTariffRate() {
    if (widget.itemGroupType != PagItemGroupType.tariffPackageTariffRate) {
      return Container();
    }
    if (!_isAdding) {
      return Container();
    }

    Map<String, dynamic> initialValueMap = {};

    if (_groupItemList.isEmpty) {
      dynamic cycleDay = widget.initalValueMap?['cycle_day'];
      if (cycleDay is! int) {
        cycleDay = int.tryParse(cycleDay.toString());
      }
      assert(cycleDay != null);

      int timezone = widget.loggedInUser.selectedScope.getProjectTimezone();
      DateTime newFromDateTime = getTargetLocalDatetimeNow(timezone);
      int year = newFromDateTime.year;
      int month = newFromDateTime.month - 2;
      int day = cycleDay!;
      newFromDateTime = DateTime(year, month, day, 0, 0, 0);
      int nextMonth = month + 1;
      int nextYear = year;
      // NOTE: cycleDay edge cases
      int nextDay = cycleDay - 1;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear = year + 1;
      }
      DateTime newToDateTime =
          DateTime(nextYear, nextMonth, nextDay, 23, 59, 59);

      initialValueMap['from_datetime'] = newFromDateTime;
      initialValueMap['to_datetime'] = newToDateTime;
    } else {
      // from/to datetime is not present in the tariffRateInfo from db
      if (_groupItemList.last['from_datetime'] == null ||
          _groupItemList.last['to_datetime'] == null) {
        if (_groupItemList.last['from_timestamp'] != null &&
            _groupItemList.last['to_timestamp'] != null) {
          DateTime? fromDateTime = DateTime.tryParse(
              _groupItemList.last['from_timestamp'].toString());
          DateTime? toDateTime =
              DateTime.tryParse(_groupItemList.last['to_timestamp'].toString());

          assert(fromDateTime != null && toDateTime != null,
              'fromDateTime or toDateTime is null');

          _groupItemList.last['from_datetime'] = fromDateTime;
          _groupItemList.last['to_datetime'] = toDateTime;
        }
      }
      DateTime lastFromDateTime = _groupItemList.last['from_datetime'];
      DateTime lastToDateTime = _groupItemList.last['to_datetime'];
      initialValueMap = _getNextMonthFromToDateTime(
        lastFromDateTime,
        lastToDateTime,
      );
    }

    return WgtNewEditTariffRate(
      appConfig: widget.appConfig,
      width: widget.width - 65,
      groupItemId: widget.groupItemId,
      initialValueMap: initialValueMap, //nextTariffRateInfo,
      tariffPackageMeterType: widget.initalValueMap?['meter_type'],
      onUpdate: (newTariffRateInfo) {
        setState(() {
          newTariffRateInfo['edit_type'] = 'update';
          // _groupItemList.insert(0, newTariffRateInfo);

          // gen random id
          String id = DateTime.now().millisecondsSinceEpoch.toString();
          newTariffRateInfo['id'] = id;
          _groupItemList.add(newTariffRateInfo);
          _isModified = true;
          _modifyTypeStr = 'update';
          _newItems++;
          _showCommitted = false;

          _isAdding = false;
          _rePop();
        });
      },
      onClose: () {
        setState(() {
          _isAdding = false;
          _allowAddButton = true;
        });
      },
    );
  }

  Widget getNewItemInput() {
    return Wrap(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        child: SizedBox(
          width: widget.width - 105,
          child: WgtTextField(
            appConfig: widget.appConfig,
            hintText: newItemHintText,
            labelText: newItemLabelText,
            onChanged: (value) {
              _newItemName = value;
            },
            validator: widget.newItemNameValidator ?? _validateNewItemName,
            onEditingComplete: () async {
              _getItemInfo();
            },
          ),
        ),
      ),
      _addNewItemErrorText.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _addNewItemErrorText,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          : const SizedBox(),
    ]);
  }

  Widget getControl({String errorText = ''}) {
    if (_committErrorText.isNotEmpty) {
      return Container();
    }
    if (_editingNodeChildInfoId != null) {
      return Container();
    }

    bool enableCommit = false;
    bool showClear = false;

    if (_isModified || _isAdding || _isEditing) {
      enableCommit = true;
      showClear = true;
    }

    // tariff rate is batch add instead of single add
    bool addToList = false;
    if (isBatchCommit) {
      enableCommit = false;
      addToList = true;
    }

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          horizontalSpaceSmall,
          SizedBox(
            width: 35,
            child: showClear
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _restoreOriginal();
                    },
                  )
                : Container(),
          ),
          Expanded(child: Container()),
          if (_showCommitted)
            Row(
              children: [
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _committedMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          Expanded(child: Container()),
          _isEditing
              ? IconButton(
                  icon: Icon(Icons.check,
                      color: enableCommit
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  onPressed:
                      // add to list
                      addToList
                          ? () {
                              String validateResult = widget
                                      .validateTreeChildren
                                      ?.call(_groupItemList) ??
                                  'valid';
                              if (validateResult != 'valid') {
                                setState(() {
                                  _addNewItemErrorText = validateResult;
                                });
                                return;
                              }
                              setState(() {
                                _isEditing = false;
                                _isAdding = false;
                                _allowAddButton = false;
                                _editingNodeChildInfoId = null;
                                _rePop();
                              });

                              widget.onUpdate?.call(rootNode!, _groupItemList);
                            }
                          :
                          // commit to db
                          !enableCommit || _isCommitting
                              ? null
                              : () async {
                                  String validateResult = widget
                                          .validateTreeChildren
                                          ?.call(_groupItemList) ??
                                      'valid';
                                  if (validateResult != 'valid') {
                                    setState(() {
                                      _committErrorText = validateResult;
                                    });
                                    return;
                                  }
                                  if (!_isModified) {
                                    setState(() {
                                      _isEditing = false;
                                      _isAdding = false;
                                      _allowAddButton = false;
                                      _editingNodeChildInfoId = null;
                                      _rePop();
                                    });
                                    return;
                                  }

                                  Map<String, dynamic>? result =
                                      await _commit();

                                  setState(() {
                                    _isEditing = false;
                                    _isAdding = false;
                                    _isModified = false;
                                    _editingNodeChildInfoId = null;

                                    _committedMessage =
                                        result['message'] ?? 'Change committed';
                                  });
                                },
                )
              : IconButton(
                  icon: Icon(Icons.edit, color: Theme.of(context).hintColor),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _allowAddButton = true;
                      _showCommitted = false;
                      _rePop();
                    });
                  },
                ),
          horizontalSpaceSmall,
        ],
      ),
    );
  }
}

import 'package:buff_helper/pag_helper/def/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../comm/comm_tenant.dart';
import '../comm/comm_tenant_ops.dart';
import '../model/mdl_pag_app_config.dart';

class WgtTenantpAssignment extends StatefulWidget {
  const WgtTenantpAssignment({
    super.key,
    required this.appConfig,
    required this.itemGroupIndexStr,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    this.onScopeTreeUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String itemGroupIndexStr;
  final String itemName;
  final String itemLabel;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;

  @override
  State<WgtTenantpAssignment> createState() => _WgtTenantpAssignmentState();
}

class _WgtTenantpAssignmentState extends State<WgtTenantpAssignment> {
  late final MdlPagUser? loggedInUser;

  final double width = 395.0;

  bool _isFetching = false;
  bool _isFetched = false;
  bool _modified = false;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  List<Map<String, dynamic>>? _itemGroupScopeMatchingItemList;
  // final List<Map<String, dynamic>> _filteredItemList = [];

  final TextEditingController _itemNamefilterController =
      TextEditingController();
  String _itemNameFilterStr = '';
  final TextEditingController _itemLabelFilterController =
      TextEditingController();
  String _itemLabelFilterStr = '';

  Future<void> _doAutoPopulate() async {
    if (_isFetching) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.itemGroupIndexStr,
    };

    _isFetching = true;
    try {
      final data = await doGetScopeMeterGroupList(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: loggedInUser!.username,
          userId: loggedInUser!.id,
          scope: '',
          target: '',
          operation: 'read',
        ),
      );
      final itemGroupScopeItemAssignment =
          data['item_group_scope_item_assignment'];
      if (itemGroupScopeItemAssignment == null ||
          itemGroupScopeItemAssignment.isEmpty) {
        throw Exception('No item found for this item group');
      }
      // list of items that are matching the item group scope
      final itemGroupScopeMatchingItemList =
          itemGroupScopeItemAssignment['item_group_scope_matching_item_list'];
      if (itemGroupScopeMatchingItemList == null) {
        throw Exception('item_group_scope_matching_item_list is null');
      }

      _itemGroupScopeMatchingItemList = List<Map<String, dynamic>>.from(
        itemGroupScopeMatchingItemList,
      );
      // sort by label
      _itemGroupScopeMatchingItemList!.sort((a, b) {
        String labelA = a['label'] ?? '';
        String labelB = b['label'] ?? '';
        return labelA.compareTo(labelB);
      });

      for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
        // add assignment info
        itemInfo['assigned'] = false;
        if (itemInfo['mg_tenant_id'] == widget.itemGroupIndexStr) {
          itemInfo['assigned'] = true;
        }
      }
      // sort assigned items to the top
      _itemGroupScopeMatchingItemList!.sort((a, b) {
        String assignedA = a['assigned'] ? '1' : '0';
        String assignedB = b['assigned'] ? '1' : '0';
        return assignedB.compareTo(assignedA);
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    } finally {
      setState(() {
        _isFetching = false;
        _isFetched = true;
      });
    }
  }

  Future<void> _doCommit() async {
    if (_isCommitting) {
      return;
    }
    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.itemGroupIndexStr,
      'item_assignment_list': _itemGroupScopeMatchingItemList,
    };
    try {
      _isCommitting = true;

      final data = await commitTenantMeterGroupList(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: loggedInUser!.username,
          userId: loggedInUser!.id,
          scope: '',
          target: '',
          operation: 'update',
        ),
      );

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      // clear assginment info from the item list
      // for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
      //   itemInfo.remove('assignment_info');
      //   itemInfo.remove('assigned_new');
      //   itemInfo.remove('is_fetching');
      // }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        _commitErrorText = 'Commit Error';
      });
    } finally {
      setState(() {
        _isCommitting = false;
        _isCommitted = true;
        _modified = false;
      });
    }
  }

  bool _checkModified() {
    bool modified = false;
    for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList ?? []) {
      if (item['assigned_new'] != null) {
        if (item['assigned'] != item['assigned_new']) {
          modified = true;
          break;
        }
      }
    }
    setState(() {
      _modified = modified;
    });
    return modified;
  }

  @override
  void initState() {
    super.initState();

    loggedInUser = Provider.of<PagUserProvider>(
      context,
      listen: false,
    ).currentUser;
  }

  @override
  void dispose() {
    _itemNamefilterController.dispose();
    _itemLabelFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 500,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Symbols.assignment_ind, color: Colors.transparent),
              getItemGroupInfo(),
              IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const Divider(),
          verticalSpaceTiny,
          getOpRow(),
          verticalSpaceSmall,
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: getAssignmentOpList(),
          ),
        ],
      ),
    );
  }

  Widget getAssignmentOpList() {
    bool fetchData = false;
    if (!_isFetched) {
      fetchData = true;
    }
    return fetchData
        ? FutureBuilder(
            future: _doAutoPopulate(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const WgtPagWait();
                default:
                  if (snapshot.hasError) {
                    return getErrorTextPrompt(
                      context: context,
                      errorText: 'Error fetching item group data',
                    );
                  } else {
                    return completedWidget();
                  }
              }
            },
          )
        : completedWidget();
  }

  Widget completedWidget() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: getScopeItemList(),
    );
  }

  Widget getOpRow() {
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
      color: Theme.of(context).colorScheme.primary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: 180,
            height: 39,
            child: TextField(
              controller: _itemNamefilterController,
              readOnly: _isCommitting ||
                  _isCommitted ||
                  {_itemGroupScopeMatchingItemList ?? []}.isEmpty,
              decoration: InputDecoration(
                  hintText: 'Meter Group Name',
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .hintColor) // prefixIcon: Icon(Icons.search),
                  ),
              onChanged: (value) {
                setState(() {
                  _itemNameFilterStr = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        horizontalSpaceSmall,
        // virtical separator
        Container(
          width: 1,
          height: 39,
          color: Theme.of(context).hintColor.withAlpha(50),
        ),
        horizontalSpaceSmall,
        InkWell(
          onTap: !_modified ||
                  _isCommitting ||
                  _isCommitted ||
                  (_itemGroupScopeMatchingItemList ?? []).isEmpty
              ? null
              : () async {
                  await _doCommit();
                },
          child: _isCommitted && _commitErrorText.isEmpty
              ? Text(
                  '✓ Committed',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _commitErrorText.isNotEmpty
                  ? getErrorTextPrompt(
                      context: context,
                      errorText: _commitErrorText,
                    )
                  : _isCommitting
                      ? const WgtPagWait(size: 21)
                      : Icon(
                          Icons.cloud_upload,
                          color: _modified
                              ? commitColor
                              : Theme.of(context).hintColor,
                        ),
        ),
        // if (_hasTptMismatchAssignmentError)
        //   Container(
        //     margin: const EdgeInsets.only(left: 10),
        //     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        //     decoration: boxDecoration.copyWith(color: Colors.transparent),
        //     child: Text(
        //       '✘ TPT Mismatch Error',
        //       style: TextStyle(color: Theme.of(context).colorScheme.error),
        //     ),
        //   ),
      ],
    );
  }

  Widget getItemGroupInfo() {
    String itemGroupScopeLabel = widget.itemScope.getLeafScopeLabel();
    PagScopeType itemScopeType = widget.itemScope.getScopeType();
    Widget scopeIcon = getScopeIcon(context, itemScopeType, size: 21);
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Assignment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
        ),
        horizontalSpaceSmall,
        Text(
          widget.itemName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        horizontalSpaceSmall,
        Text(
          widget.itemLabel.isNotEmpty ? widget.itemLabel : '-',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        horizontalSpaceSmall,
        Container(
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              scopeIcon,
              horizontalSpaceTiny,
              Text(itemGroupScopeLabel),
            ],
          ),
        ),
        horizontalSpaceSmall,
        // Container(
        //   decoration: boxDecoration,
        //   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        //   child: Text(widget.tariffPackageTypeLabel),
        // ),
      ],
    );
  }

  bool _showItem(Map<String, dynamic> item) {
    if (_itemNameFilterStr.isNotEmpty || _itemLabelFilterStr.isNotEmpty) {
      String? name = item['name'];
      String? label = item['label'];
      bool nameMatches =
          name != null && name.toLowerCase().contains(_itemNameFilterStr);
      bool labelMatches =
          label != null && label.toLowerCase().contains(_itemLabelFilterStr);
      return nameMatches || labelMatches;
    }
    return true; // Include item if no filter is applied
  }

  Widget getScopeItemList() {
    if (_itemGroupScopeMatchingItemList == null ||
        _itemGroupScopeMatchingItemList!.isEmpty) {
      return const Center(child: Text('No item found for this item group'));
    }
    List<Widget> itemWidgetList = [];
    int index = 0;

    for (Map<String, dynamic> itemInfo
        in _itemGroupScopeMatchingItemList ?? []) {
      bool showItem = _showItem(itemInfo);
      if (!showItem) {
        continue; // Skip this item if it doesn't match the filter
      }
      Widget tile = getItemRow(itemInfo, ++index);
      itemWidgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: tile,
        ),
      );
    }

    return ListView.builder(
      // shrinkWrap: true,
      itemExtent: 35,
      itemCount: itemWidgetList.length,
      itemBuilder: (context, index) {
        return itemWidgetList[index];
      },
    );
  }

  Widget getItemRow(Map<String, dynamic> itemInfo, int index) {
    String tenantName = itemInfo['name'] ?? 'Unknown Item';
    String tenantLabel = itemInfo['label'] ?? '';
    bool assigned = itemInfo['assigned'] ?? false;

    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );

    TextStyle disabledTextStyle = TextStyle(
      color: Theme.of(context).hintColor.withAlpha(150),
    );

    bool disabled = false; //_hasTptMismatchAssignmentError;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              index.toString(),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
        horizontalSpaceSmall,
        Container(
          width: 120,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SelectableText(
            tenantName,
            style: disabled ? disabledTextStyle : null,
          ),
        ),
        horizontalSpaceSmall,
        Container(
          width: 160,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SelectableText(
            tenantLabel.isNotEmpty ? tenantLabel : '-',
            style: disabled ? disabledTextStyle : null,
          ),
        ),
        horizontalSpaceTiny,
        Checkbox(
          value: itemInfo['assigned_new'] ?? itemInfo['assigned'],
          onChanged: disabled
              ? null
              : (bool? value) {
                  setState(() {
                    if (value == null) return;
                    itemInfo['assigned_new'] = value;
                    if (itemInfo['assigned'] != itemInfo['assigned_new']) {
                      _modified = true;
                    }
                  });
                  _checkModified();
                },
        ),
      ],
    );
  }
}

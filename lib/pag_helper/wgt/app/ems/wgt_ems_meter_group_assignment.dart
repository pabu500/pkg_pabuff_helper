import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_meter_group_assignment_item.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;

import '../../../../up_helper/exceptions.dart';
import '../../../comm/comm_ex.dart';
import '../../../comm/comm_meter_group.dart';
import '../../../comm/pag_be_api_base.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

class WgtEmsMeterGroupAssignment extends StatefulWidget {
  const WgtEmsMeterGroupAssignment({
    super.key,
    required this.appConfig,
    required this.strItemGroupIndex,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    required this.meterType,
    this.itemInfo,
    this.onScopeTreeUpdate,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String strItemGroupIndex;
  final String itemName;
  final String itemLabel;
  final String meterType;
  final Map<String, dynamic>? itemInfo;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtEmsMeterGroupAssignment> createState() =>
      _WgtEmsMeterGroupAssignmentState();
}

class _WgtEmsMeterGroupAssignmentState
    extends State<WgtEmsMeterGroupAssignment> {
  late final MdlPagUser? loggedInUser;

  final double width = 395.0;

  bool _isScopeMatchingListFetching = false;
  bool _isScopeMathingItemListFetched = false;
  bool _modified = false;
  String _fetchErrorText = '';

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  List<Map<String, dynamic>>? _itemGroupScopeMatchingItemList;
  // List<Map<String, dynamic>>? _itemGroupItemList;
  List<Map<String, dynamic>>? _scopeMismatchItemList;

  // String? _selectedMeterIndexStr;
  bool _isFetchingAllAssignmentInfo = false;
  bool _isAllAssignmentInfoFetched = false;

  final TextEditingController _itemSnFilterController = TextEditingController();
  String _itemSnFilterStr = '';

  UniqueKey? _mgAssignmentItemKey;

  Future<void> _doAutoPopulate() async {
    if (_isScopeMatchingListFetching) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.strItemGroupIndex,
    };

    _isScopeMatchingListFetching = true;
    try {
      final result = await doGetScopeMeterList(
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
      // list of items that are matching the item group scope
      final itemGroupScopeMatchingItemList =
          result['item_group_scope_matching_item_list'];
      if (itemGroupScopeMatchingItemList == null) {
        throw Exception('item_group_scope_matching_item_list is null');
      }
      final scopeMismatchItemList = result['scope_mismatch_item_list'];
      if (scopeMismatchItemList == null) {
        throw Exception('scope_mismatch_item_list is null');
      }
      _itemGroupScopeMatchingItemList = List<Map<String, dynamic>>.from(
        itemGroupScopeMatchingItemList,
      );
      _scopeMismatchItemList =
          List<Map<String, dynamic>>.from(scopeMismatchItemList);

      // sort by label
      _itemGroupScopeMatchingItemList!.sort((a, b) {
        String labelA = a['label'] ?? '';
        String labelB = b['label'] ?? '';
        return labelA.compareTo(labelB);
      });
      for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
        // itemInfo['assigned'] = false;
        String meterType = itemInfo['meter_type'] ?? '';
        bool hasMeterTypeMismatch = meterType != widget.meterType;
        itemInfo['meter_type_mismatch'] = hasMeterTypeMismatch;
      }
    } catch (e) {
      dev.log(e.toString());
      _fetchErrorText =
          getErrorText(e, defaultErrorText: 'Error fetching item group data');
      rethrow;
    } finally {
      setState(() {
        _isScopeMatchingListFetching = false;
        _isScopeMathingItemListFetched = true;
      });
    }
  }

  // for ems, meter to meter group assignment should involve tenant assignment as well
  Future<void> _getMeterAssignment(Map<String, dynamic> itemInfo) async {
    if (itemInfo['is_fetching'] ?? false) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'meter_id': itemInfo['meter_id'],
    };

    itemInfo['is_fetching'] = true;
    try {
      final result = await ex(
        endpoint: PagUrlBase.eptPagGetMeterTenantAssignment,
        crudType: 'read',
        opStr: 'get meter assignment',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          username: loggedInUser!.username,
          userId: loggedInUser!.id,
          scope: '',
          target: '',
          operation: 'read',
        ),
      );
      final meterTenantAssignmentList = result;
      itemInfo['assignment'] = meterTenantAssignmentList;
      itemInfo['info_fetched'] = true;
    } catch (e) {
      dev.log(e.toString());

      rethrow;
    } finally {
      setState(() {
        itemInfo['is_fetching'] = false;
      });
    }
  }

  Future<void> _doCommit() async {
    if (_isCommitting) {
      return;
    }
    // filter out items that are not modified
    final List<Map<String, dynamic>> assignmentList =
        _itemGroupScopeMatchingItemList!
            .where((item) =>
                item['updated_meter_assignment_to_this_meter_group'] != null)
            // .where((item) => item['percentage_new'] != item['percentage'])
            .toList();
    if ((_scopeMismatchItemList ?? []).isNotEmpty) {
      assignmentList.clear();
      assignmentList.addAll(_scopeMismatchItemList!
          .where((item) =>
              item['updated_meter_assignment_to_this_meter_group'] != null)
          .toList());
    }
    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.strItemGroupIndex,
      'item_assignment_list': assignmentList,
    };
    try {
      _isCommitting = true;

      final result = await commitMeterGroupMeterList(
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

      // clear assginment info from the item list
      for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
        itemInfo.remove('assignment');
        // itemInfo.remove('assignment_new');
        itemInfo.remove('updated_meter_assignment_to_this_meter_group');
        itemInfo.remove('is_fetching');
        itemInfo.remove('info_fetched');
      }
    } catch (e) {
      dev.log(e.toString());
      setState(() {
        _commitErrorText = getErrorText(e, defaultErrorText: 'Commit error');
      });
    } finally {
      setState(() {
        _isCommitting = false;
        _isCommitted = true;
        _modified = false;
        // _selectedMeterIndexStr = null;
        _mgAssignmentItemKey =
            UniqueKey(); // reset the key to force rebuild of the assignment item widget
      });
    }
  }

  bool _checkModified({String assignmentErrorMessage = ''}) {
    bool modified = false;
    if (assignmentErrorMessage.isNotEmpty) {
      return false; // if there is an assignment error, do not consider it modified
    }
    if ((_scopeMismatchItemList ?? []).isNotEmpty) {
      for (Map<String, dynamic> item in _scopeMismatchItemList!) {
        if (item['updated_meter_assignment_to_this_meter_group'] != null) {
          String percentageNew =
              item['updated_meter_assignment_to_this_meter_group']
                      ?['percentage'] ??
                  '';
          if (percentageNew.isNotEmpty) {
            modified = true;
            break;
          }
        }
      }
    } else {
      for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList ?? []) {
        if (item['updated_meter_assignment_to_this_meter_group'] != null) {
          String percentageNew =
              item['updated_meter_assignment_to_this_meter_group']
                      ?['percentage'] ??
                  '';
          if (percentageNew.isNotEmpty) {
            modified = true;
            break;
          }
        }
      }
    }
    setState(() {
      _modified = modified;
    });
    return modified;
  }

  bool _showItem(Map<String, dynamic> item) {
    if (_itemSnFilterStr.isNotEmpty) {
      String? sn = item['meter_sn'];
      bool snMatches = (sn ?? '').isNotEmpty &&
          (sn ?? '').toLowerCase().contains(_itemSnFilterStr);
      return snMatches;
    }

    return true; // Include item if no filter is applied
  }

  Future<void> _checkAllAssignments() async {
    if (_isFetchingAllAssignmentInfo) return;

    final queryMap = <String, dynamic>{
      'scope': loggedInUser!.selectedScope.toScopeMap(),
    };
    setState(() {
      _isFetchingAllAssignmentInfo = true;
      _isAllAssignmentInfoFetched = false;
    });

    for (var itemInfo in _itemGroupScopeMatchingItemList ?? []) {
      queryMap['tenant_id'] = itemInfo['tenant_id'];
      queryMap['payment_amount'] = itemInfo['amount'];
      queryMap['value_timestamp'] = itemInfo['value_timestamp'];
      queryMap['lc_status'] = itemInfo['lc_status'];

      itemInfo['is_comm']?.call(true, false);

      bool showResult = false;
      try {
        await _getMeterAssignment(itemInfo);
      } catch (e) {
        dev.log('Error fetching assignment for item ${itemInfo['id']}: $e');
      } finally {
        itemInfo['is_comm']?.call(false, showResult);
      }
    }

    // sort meters assigned to this meter group to the top
    dev.log('Sorting meter group assignments');
    _sortItemGroupScopeMatchingItemList();

    setState(() {
      _isFetchingAllAssignmentInfo = false;
      _isAllAssignmentInfoFetched = true;
    });
  }

  void _sortItemGroupScopeMatchingItemList() {
    for (var item in _itemGroupScopeMatchingItemList ?? []) {
      final assignmentInfo = item['assignment'];
      if (assignmentInfo == null) {
        dev.log('No assignment info for item: ${item['id']}, skipping.');
        continue;
      }
      final meterMeterGroupAssignment =
          assignmentInfo['meter_meter_group_assignment'];
      if (meterMeterGroupAssignment == null) {
        dev.log(
            'No meter meter group assignment for item: ${item['id']}, skipping.');
        continue;
      }
      for (var tenantAssignment in meterMeterGroupAssignment) {
        // Process each tenant assignment
        final tenantInfo = tenantAssignment['tenant_info'];
        if (tenantInfo == null) {
          continue;
        }
        String tenantName = tenantInfo['name'] ?? '';
        if (tenantName == widget.itemInfo?['tenant_name']) {
          // move it to the top
          _itemGroupScopeMatchingItemList?.remove(item);
          _itemGroupScopeMatchingItemList?.insert(0, item);
        }
      }
    }
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
          const Divider(thickness: 0.5),
          verticalSpaceTiny,
          getOpRow(),
          verticalSpaceSmall,
          Text(
            'List of meters matching the scope of this meter group:',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
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
    if (!_isScopeMathingItemListFetched) {
      fetchData = true;
    }
    if (_fetchErrorText.isNotEmpty) {
      return getErrorTextPrompt(
        context: context,
        errorText: _fetchErrorText,
      );
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
                      errorText: 'Error fetching tree data',
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
    double listHeight = 500;
    if (_scopeMismatchItemList?.isNotEmpty ?? false) {
      listHeight = (_scopeMismatchItemList ?? []).length * 120.0;
    }
    return Container(
      height: listHeight + 150,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: (_scopeMismatchItemList ?? []).isNotEmpty
          ?
          // resolve scope mismatch item list
          getScopeMismatchItemList(listHeight)
          : getScopeItemList(),
    );
  }

  Widget getScopeMismatchItemList(double listHeight) {
    List<Widget> itemWidgetList = [];
    int index = 0;

    for (Map<String, dynamic> itemInfo in (_scopeMismatchItemList ?? [])) {
      itemWidgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
          child: WgtMeterGroupAssignmentItem(
            key: _mgAssignmentItemKey,
            appConfig: widget.appConfig,
            loggedInUser: loggedInUser!,
            itemInfo: itemInfo,
            strItemGroupIndex: widget.strItemGroupIndex,
            getMeterAssignment: _getMeterAssignment,
            onModified: (assignmentErrorMessage) {
              _checkModified(assignmentErrorMessage: assignmentErrorMessage);
            },
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.error, width: 5),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        children: [
          Text(
              'The following list contains the meter(s) with mismatched scope to the meter group',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 18)),
          Text('Clear this scope mismatch list before assignment op',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 18)),
          verticalSpaceSmall,
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              // shrinkWrap: true,
              // itemExtent: 35,
              itemCount: itemWidgetList.length,
              itemBuilder: (context, index) {
                return itemWidgetList[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getOpRow() {
    bool tooManyRows = false;
    if ((_itemGroupScopeMatchingItemList != null) &&
        _itemGroupScopeMatchingItemList!.length > 20) {
      tooManyRows = true;
    }
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
      color: Theme.of(context).colorScheme.primary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: tooManyRows
              ? 'Too many rows to check all assignments, please filter the list first'
              : _isAllAssignmentInfoFetched
                  ? 'All assignment info fetched'
                  : 'Check assignment info for all meters',
          waitDuration: const Duration(milliseconds: 500),
          child: WgtCommButton(
            label: 'Check All Assignments',
            height: 35,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: 15,
            ),
            onPressed: (_itemGroupScopeMatchingItemList ?? []).isEmpty ||
                    _isAllAssignmentInfoFetched ||
                    tooManyRows
                ? null
                : () async {
                    await _checkAllAssignments();
                  },
          ),
        ),
        horizontalSpaceSmall,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: 180,
            height: 39,
            child: TextField(
              controller: _itemSnFilterController,
              readOnly: _isCommitting ||
                  _isCommitted ||
                  {_itemGroupScopeMatchingItemList ?? []}.isEmpty,
              decoration: InputDecoration(
                  hintText: 'Meter S/N',
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .hintColor) // prefixIcon: Icon(Icons.search),
                  ),
              onChanged: (value) {
                setState(() {
                  _itemSnFilterStr = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        horizontalSpaceSmall,
        InkWell(
          onTap: !_modified ||
                  _isCommitting ||
                  _isCommitted ||
                  ((_scopeMismatchItemList ?? []).isEmpty &&
                      (_itemGroupScopeMatchingItemList ?? []).isEmpty)
              ? null
              : () async {
                  await _doCommit();
                  widget.onUpdate?.call();
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
      ],
    );
  }

  Widget getItemGroupInfo() {
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor, width: 1.5),
      borderRadius: BorderRadius.circular(5),
    );
    PagTenantLcStatus? lcStatus =
        PagTenantLcStatus.byValue(widget.itemInfo?['tenant_lc_status'] ?? '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Assignment ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
              ),
            ),
            Icon(PagItemKind.meterGroup.iconData, size: 21),
            horizontalSpaceTiny,
            Container(
              decoration: boxDecoration.copyWith(
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                widget.itemName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            horizontalSpaceSmall,
            SelectableText(
              widget.itemLabel.isNotEmpty ? widget.itemLabel : '-',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            horizontalSpaceSmall,
            getScopeLabel(context, widget.itemScope),
            horizontalSpaceSmall,
            Container(
              // width: 20,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(widget.meterType,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            horizontalSpaceSmall,
          ],
        ),
        if ((widget.itemInfo?['tenant_label'] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Row(
              children: [
                Text(
                  'Assigned to ',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Icon(PagItemKind.tenant.iconData,
                    size: 18, color: Theme.of(context).hintColor),
                horizontalSpaceTiny,
                SelectableText(
                  '${widget.itemInfo?['tenant_name']}',
                  style: const TextStyle(fontSize: 16),
                ),
                horizontalSpaceTiny,
                SelectableText(
                  '${widget.itemInfo?['tenant_label']}',
                  style: const TextStyle(fontSize: 16),
                ),
                horizontalSpaceTiny,
                PagTenantLcStatus.getTagWidget(lcStatus),
              ],
            ),
          )
      ],
    );
  }

  Widget getScopeItemList() {
    if (_itemGroupScopeMatchingItemList == null ||
        _itemGroupScopeMatchingItemList!.isEmpty) {
      return const Center(child: Text('No item found for this item group'));
    }
    List<Widget> itemWidgetList = [];
    int index = 0;
    for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
      bool showItem = _showItem(itemInfo);
      itemInfo['index'] = ++index;
      if (!showItem) {
        continue; // Skip this item if it doesn't match the filter
      }
      itemWidgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
          child: WgtMeterGroupAssignmentItem(
            key: _mgAssignmentItemKey,
            appConfig: widget.appConfig,
            loggedInUser: loggedInUser!,
            itemInfo: itemInfo,
            strItemGroupIndex: widget.strItemGroupIndex,
            getMeterAssignment: _getMeterAssignment,
            onModified: (assignmentErrorMessage) {
              _checkModified(assignmentErrorMessage: assignmentErrorMessage);
            },
          ),
        ),
      );
    }

    return ListView.builder(
      // shrinkWrap: true,
      // itemExtent: 35,
      itemCount: itemWidgetList.length,
      itemBuilder: (context, index) {
        return itemWidgetList[index];
      },
    );
  }
}

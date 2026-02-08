import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
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
import 'dart:developer' as dev;

import '../../../comm/comm_meter_group.dart';
import '../../../comm/comm_tenant.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

class WgtMeterGroupAssignment2 extends StatefulWidget {
  const WgtMeterGroupAssignment2({
    super.key,
    required this.appConfig,
    required this.itemGroupIndexStr,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    required this.meterType,
    this.itemInfo,
    this.onScopeTreeUpdate,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String itemGroupIndexStr;
  final String itemName;
  final String itemLabel;
  final String meterType;
  final Map<String, dynamic>? itemInfo;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtMeterGroupAssignment2> createState() =>
      _WgtMeterGroupAssignment2State();
}

class _WgtMeterGroupAssignment2State extends State<WgtMeterGroupAssignment2> {
  late final MdlPagUser? loggedInUser;

  final double width = 395.0;

  bool _isScopeMatchingListFetching = false;
  bool _isScopeMathingItemListFetched = false;
  bool _modified = false;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  List<Map<String, dynamic>>? _itemGroupScopeMatchingItemList;
  // List<Map<String, dynamic>>? _itemGroupItemList;

  // String? _selectedMeterIndexStr;
  bool _isFetchingAllAssignmentInfo = false;
  bool _isAllAssignmentInfoFetched = false;

  final TextEditingController _itemSnFilterController = TextEditingController();
  String _itemSnFilterStr = '';

  Future<void> _doAutoPopulate() async {
    if (_isScopeMatchingListFetching) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.itemGroupIndexStr,
    };

    _isScopeMatchingListFetching = true;
    try {
      final data = await doGetScopeMeterList(
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
      // list of items that are actually assigned to this item group
      final itemGroupItemList =
          itemGroupScopeItemAssignment['item_group_item_list'];
      if (itemGroupItemList == null) {
        throw Exception('item_group_item_list is null');
      }
      _itemGroupScopeMatchingItemList = List<Map<String, dynamic>>.from(
        itemGroupScopeMatchingItemList,
      );
      // _itemGroupItemList = List<Map<String, dynamic>>.from(itemGroupItemList);
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

      rethrow;
    } finally {
      setState(() {
        _isScopeMatchingListFetching = false;
        _isScopeMathingItemListFetched = true;
      });
    }
  }

  Future<void> _getMeterAssignment(Map<String, dynamic> itemInfo) async {
    if (itemInfo['is_fetching'] ?? false) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'meter_id': itemInfo['id'],
    };

    itemInfo['is_fetching'] = true;
    try {
      final data = await getMeterTenantAssignment(
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
      final meterTenantAssignment = data['meter_tenant_assignment'];
      if (meterTenantAssignment == null) {
        throw Exception('meter_tenant_assignment is null');
      }
      itemInfo['assignment_info'] = data;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
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
            .where((item) => item['assigned_new'] != null)
            .toList();
    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.itemGroupIndexStr,
      'item_assignment_list': assignmentList,
    };
    try {
      _isCommitting = true;

      final data = await commitMeterGroupMeterList(
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
      for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
        itemInfo.remove('assignment_info');
        itemInfo.remove('assigned_new');
        itemInfo.remove('is_fetching');
      }
    } catch (e) {
      dev.log(e.toString());
      setState(() {
        _commitErrorText = 'Commit Error';
      });
    } finally {
      setState(() {
        _isCommitting = false;
        _isCommitted = true;
        _modified = false;
        // _selectedMeterIndexStr = null;
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
      final assignmentInfo = item['assignment_info'];
      if (assignmentInfo == null) {
        dev.log('No assignment info for item: ${item['id']}, skipping.');
        continue;
      }
      final meterTenantAssignment = assignmentInfo['meter_tenant_assignment'];
      if (meterTenantAssignment == null) {
        dev.log(
            'No meter tenant assignment for item: ${item['id']}, skipping.');
        continue;
      }
      for (var tenantAssignment in meterTenantAssignment) {
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
    return Container(
      height: 500,
      // width: 500,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: getScopeItemList(),
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
            onPressed: _isAllAssignmentInfoFetched || tooManyRows
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
                  (_itemGroupScopeMatchingItemList ?? []).isEmpty
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
            SelectableText(
              widget.itemName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            appConfig: widget.appConfig,
            loggedInUser: loggedInUser!,
            itemInfo: itemInfo,
            itemGroupIndexStr: widget.itemGroupIndexStr,
            getMeterAssignment: _getMeterAssignment,
            onModified: () {
              _checkModified();
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

class WgtMeterGroupAssignmentItem extends StatefulWidget {
  const WgtMeterGroupAssignmentItem({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.itemInfo,
    required this.getMeterAssignment,
    required this.itemGroupIndexStr,
    this.regFresh,
    this.onModified,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> itemInfo;
  final String itemGroupIndexStr;
  final void Function(void Function(bool isComm, bool isEnabled))? regFresh;
  final Future<void> Function(Map<String, dynamic> itemInfo) getMeterAssignment;
  final void Function()? onModified;

  @override
  State<WgtMeterGroupAssignmentItem> createState() =>
      _WgtMeterGroupAssignmentItemState();
}

class _WgtMeterGroupAssignmentItemState
    extends State<WgtMeterGroupAssignmentItem> {
  bool _assignmentInfoFetched = false;
  bool _isComm = false;
  bool _isEnabled = false;

  void _refresh(bool isComm, bool isEnabled) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isComm = isComm;
      _isEnabled = isEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.regFresh?.call(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    // return widget;
    return _isComm
        ? const WgtPagWait(size: 21)
        : InkWell(
            onTap: !_isEnabled ? null : () {},
            child: getAssignmentRow(widget.itemInfo),
          );
  }

  Widget getAssignmentRow(Map<String, dynamic> itemInfo) {
    int index = itemInfo['index'] ?? 0;
    String itemName = itemInfo['name'] ?? '-';
    String itemLabel = itemInfo['label'] ?? '-';
    String meterSn = itemInfo['meter_sn'] ?? '-';
    bool assigned = itemInfo['assigned'] ?? false;

    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );

    TextStyle disabledTextStyle = TextStyle(
      color: Theme.of(context).hintColor.withAlpha(150),
    );

    bool disabled = false; //_hasTptMismatchAssignmentError;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Align(
                alignment: Alignment.centerRight,
                child: SelectableText(
                  index.toString(),
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
            horizontalSpaceTiny,
            Icon(PagDeviceCat.meter.iconData,
                color: Theme.of(context).hintColor, size: 18),
            horizontalSpaceTiny,
            Container(
              width: 135,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                itemName,
                style: disabled ? disabledTextStyle : null,
              ),
            ),
            horizontalSpaceSmall,
            Container(
              width: 135,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                meterSn,
                style: disabled ? disabledTextStyle : null,
              ),
            ),
            horizontalSpaceSmall,
            Container(
              width: 160,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                itemLabel,
                style: disabled ? disabledTextStyle : null,
              ),
            ),
            horizontalSpaceTiny,
            getAssignmentBox(itemInfo),
          ],
        ),
        if (true) getAssignmentMap(),
      ],
    );
  }

  Widget getAssignmentBox(Map<String, dynamic> itemInfo) {
    final assignmentInfo = itemInfo['assignment_info'];
    bool hasAssignmentInfo = assignmentInfo != null;
    bool needToCheck = !hasAssignmentInfo;

    double barWidth = 190;
    double maxAssignedWidth = barWidth - 2;
    double totalTenantPercentage = 0.0;
    String tooltipMessage = '';
    double percentageAssignedToThisItemGroup = 0.0;
    final List<Map<String, dynamic>> tenantAssignmentList = [];
    final List<Map<String, dynamic>> assignmentBarList = [];
    if (hasAssignmentInfo) {
      final meterGroupAssignmentList =
          assignmentInfo['meter_tenant_assignment'];
      // sort terminated tenants to the end
      meterGroupAssignmentList.sort((a, b) {
        final tenantInfoA = a['tenant_info'];
        final tenantInfoB = b['tenant_info'];
        final lcStatusA =
            tenantInfoA != null ? (tenantInfoA['lc_status'] ?? '') : '';
        final lcStatusB =
            tenantInfoB != null ? (tenantInfoB['lc_status'] ?? '') : '';
        final statusA = PagTenantLcStatus.byValue(lcStatusA);
        final statusB = PagTenantLcStatus.byValue(lcStatusB);
        if (statusA == PagTenantLcStatus.terminated &&
            statusB != PagTenantLcStatus.terminated) {
          return 1; // A comes after B
        } else if (statusA != PagTenantLcStatus.terminated &&
            statusB == PagTenantLcStatus.terminated) {
          return -1; // A comes before B
        } else {
          return 0; // No change in order
        }
      });
      for (var meterGroupAssignment in meterGroupAssignmentList) {
        final tenantInfo = meterGroupAssignment['tenant_info'];
        final tenantLcStatusStr =
            tenantInfo != null ? (tenantInfo['lc_status'] ?? '') : '';
        final tenantLcStatus = PagTenantLcStatus.byValue(tenantLcStatusStr);
        if (tenantLcStatus == PagTenantLcStatus.terminated) {
          continue; // skip terminated tenants
        }

        Map<String, dynamic> barInfo = {};

        if (meterGroupAssignment['meter_group_id'] ==
            widget.itemGroupIndexStr) {
          percentageAssignedToThisItemGroup =
              double.tryParse(meterGroupAssignment['percentage']) ?? 0.0;
          barInfo['mg_self_percentage'] = percentageAssignedToThisItemGroup;
        }

        bool isAssignedToTenant = tenantInfo != null && tenantInfo.isNotEmpty;
        if (isAssignedToTenant) {
          tenantAssignmentList.add(tenantInfo);
          double? meterPercentage =
              double.tryParse(meterGroupAssignment['percentage']);
          totalTenantPercentage += meterPercentage ?? 0.0;
          barInfo['tenant_id'] = tenantInfo['id'];
          barInfo['tenant_name'] = tenantInfo['name'];
          barInfo['tenant_label'] = tenantInfo['label'] ?? '';
          barInfo['tenant_lc_status'] = tenantInfo['lc_status'] ?? '';
          barInfo['tenant_percentage'] = meterPercentage ?? 0.0;
        }
        assignmentBarList.add(barInfo);
      }

      if (tenantAssignmentList.isEmpty) {
        tooltipMessage = 'Not assigned to any tenant';
      }
    }

    String assignmentError = '';
    if (totalTenantPercentage > 100.00001) {
      assignmentError = 'overflow';
      tooltipMessage = '[ Total tenant percentage exceeds 100% ]\n';
      for (Map<String, dynamic> barInfo in assignmentBarList) {
        double? tenantPercentage = barInfo['tenant_percentage'];
        if (tenantPercentage != null) {
          String tenantName = barInfo['tenant_name'] ?? 'Unknown Tenant';
          tooltipMessage +=
              '$tenantName - ${tenantPercentage.toStringAsFixed(2)}%\n';
        }
      }
    }

    List<Widget> assignmentBarWidgets = [];
    if (assignmentError.isNotEmpty) {
      assignmentBarWidgets.add(
        Tooltip(
          message: tooltipMessage,
          child: Container(
            width: maxAssignedWidth,
            color: Theme.of(context).colorScheme.error,
            child: const Center(
              child: Text(
                'Assignment Error',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ),
      );
    } else {
      for (Map<String, dynamic> barInfo in assignmentBarList) {
        double? tenantPercentage = barInfo['tenant_percentage'];
        if (tenantPercentage != null) {
          String tenantLcStatus = barInfo['tenant_lc_status'] ?? '';
          PagTenantLcStatus? lcStatus =
              PagTenantLcStatus.byValue(tenantLcStatus);
          if (lcStatus == PagTenantLcStatus.terminated) {
            continue; // skip terminated tenants
          }

          String tenantName = barInfo['tenant_name'] ?? 'Unknown Tenant';
          String tenantLabel = barInfo['tenant_label'] ?? '';

          double assignedWidth =
              (tenantPercentage / 100.0) * maxAssignedWidth; // Calculate width

          Widget barWidget = Tooltip(
            message:
                '$tenantName ${tenantLabel.isNotEmpty ? "($tenantLabel)" : ""} - $tenantPercentage%',
            child: InkWell(
              onTap: true
                  ? null
                  : () {
                      if (itemInfo['is_fetching'] ?? false) {
                        return;
                      }

                      setState(() {
                        // _selectedMeterIndexStr = itemInfo['id'];
                      });
                    },
              child: Container(
                width: assignedWidth,
                color: Colors.grey.shade700,
                child: Center(
                  child: Row(
                    children: [
                      horizontalSpaceTiny,
                      Icon(PagItemKind.tenant.iconData,
                          size: 17, color: Colors.white),
                      horizontalSpaceTiny,
                      Text(
                        tenantName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          assignmentBarWidgets.add(barWidget);
        }
      }
    }

    if (assignmentBarWidgets.isEmpty) {
      if (percentageAssignedToThisItemGroup > 0.0) {
        assignmentBarWidgets.add(
          Tooltip(
            message: 'Assigned to this item group - '
                '${percentageAssignedToThisItemGroup.toStringAsFixed(2)}%',
            child: Container(
              width:
                  percentageAssignedToThisItemGroup / 100.0 * maxAssignedWidth,
              color: Theme.of(context).colorScheme.primary,
              child: const Center(
                child: Text(
                  'this meter group (unassigned)',
                  // 'this meter group',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (assignmentBarWidgets.isEmpty) {
      // to ensure the checkbox is aligned properly
      assignmentBarWidgets.add(Container());
    }

    bool disabled =
        totalTenantPercentage > 99.99999 || itemInfo['is_fetching'] == true;

    bool checked = itemInfo['assigned_new'] ??
        itemInfo['assigned'] ??
        percentageAssignedToThisItemGroup > 0.0;

    if (itemInfo['assigned_new'] == true && itemInfo['assigned'] == false) {
      assignmentBarWidgets.add(
        Tooltip(
          message: 'Assigned to this item group',
          child: Container(
            width: maxAssignedWidth,
            color: commitColor,
            child: const Center(
              child: Text(
                'this meter group',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ),
      );
    }
    if (itemInfo['assigned_new'] == false) {
      assignmentBarWidgets.clear();
      assignmentBarWidgets.add(
        Tooltip(
          message: 'Unassigned from this item group',
          child: Container(
            width: maxAssignedWidth,
            color: Theme.of(context).colorScheme.error,
            child: const Center(
              child: Text(
                'this meter group',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ),
      );
    }

    double margin = 45;
    return SizedBox(
      width: barWidth + margin,
      // height: 26,
      child: needToCheck
          ? WgtCommButton(
              label: 'Check Assignment',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 13.5,
              ),
              width: barWidth + margin,
              onPressed: () async {
                if (itemInfo['is_fetching'] ?? false) {
                  return;
                }
                if (itemInfo['assignment_info'] == null) {
                  await widget.getMeterAssignment(itemInfo);
                }

                setState(() {
                  // _selectedMeterIndexStr = itemInfo['id'];
                });
              },
            )
          : Tooltip(
              message: tooltipMessage,
              waitDuration: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  Container(
                    height: 25,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Theme.of(context).hintColor),
                    ),
                    child: Row(
                      children: [
                        ...assignmentBarWidgets,
                        const Spacer(),
                      ],
                    ),
                  ),
                  horizontalSpaceTiny,
                  Checkbox(
                    value:
                        checked, //itemInfo['assigned_new'] ?? itemInfo['assigned'],
                    onChanged: disabled
                        ? null
                        : (bool? value) {
                            setState(() {
                              if (value == null) return;
                              itemInfo['assigned_new'] = value;
                              if (itemInfo['assigned_new'] == true) {
                                itemInfo['percentage'] =
                                    100.0; // Set to 100% if assigned
                              }
                              // if (itemInfo['assigned_new'] == false) {
                              //   itemInfo['assignment_info'] = null;
                              // }
                              // _checkModified();
                              widget.onModified?.call();
                            });
                          },
                  ),
                ],
              ),
            ),
    );
  }

  Widget getAssignmentMap() {
    Map<String, dynamic>? assignmentInfo = widget.itemInfo['assignment_info'];
    if (assignmentInfo == null) {
      if (_assignmentInfoFetched) {
        return getErrorTextPrompt(
            context: context, errorText: 'Error: Assignment info not found');
      } else {
        return Container();
      }
    }
    final meterTeantAssignmentList = assignmentInfo['meter_tenant_assignment'];
    if (meterTeantAssignmentList == null || meterTeantAssignmentList.isEmpty) {
      return Text(
        'This meter has not been assigned to any meter group',
        style: TextStyle(color: Theme.of(context).hintColor),
      );
    }
    List<Widget> assignmentWidgetList = [];
    int assignedToActiveTenantCount = 0;
    for (Map<String, dynamic> assignment in meterTeantAssignmentList ?? []) {
      String meterName = assignment['meter_name'] ?? '';
      String meterLabel = assignment['meter_label'] ?? '';
      String meterSn = assignment['meter_sn'] ?? '';
      String meterGroupName = assignment['meter_group_name'] ?? '';
      String meterGroupLabel = assignment['meter_group_label'] ?? '';
      double percentage =
          double.tryParse(assignment['percentage'] ?? '0.0') ?? 0.0;

      final tenantInfo = assignment['tenant_info'];
      String tenantName = tenantInfo?['name'] ?? '';
      String tenantLabel = tenantInfo?['label'] ?? '';
      String tenantLcStatus = tenantInfo?['lc_status'] ?? '';
      PagTenantLcStatus? tenantLcStatusEnum =
          PagTenantLcStatus.byValue(tenantLcStatus);
      // tenantLcStatusEnum ??= PagTenantLcStatus.normal;
      if (tenantInfo != null) {
        if (tenantLcStatusEnum == PagTenantLcStatus.normal ||
            tenantLcStatusEnum == PagTenantLcStatus.onboarding ||
            tenantLcStatusEnum == PagTenantLcStatus.offboarding) {
          assignedToActiveTenantCount++;
        }
      }

      bool meterGroupIsAssignedToActiveTenant = false;
      if (assignedToActiveTenantCount != 0) {
        meterGroupIsAssignedToActiveTenant = true;
      }

      if (assignedToActiveTenantCount > 1) {
        return getErrorTextPrompt(
          context: context,
          errorText:
              'Error: Multiple active tenants assigned to this meter group',
        );
      }

      Widget assignmentWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PagItemKind.meterGroup.iconData,
                color: Theme.of(context).hintColor, size: 18),
            horizontalSpaceTiny,
            SizedBox(
              width: 135,
              child: Text(
                meterGroupName,
                style: TextStyle(
                    color: meterGroupIsAssignedToActiveTenant
                        ? Colors.greenAccent
                        : Theme.of(context).hintColor),
              ),
            ),
            horizontalSpaceTiny,
            SizedBox(
              width: 60,
              child: Text(
                '${percentage.toStringAsFixed(2)}%',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
            Icon(Symbols.arrow_right,
                size: 18, color: Theme.of(context).hintColor),
            Icon(PagItemKind.tenant.iconData,
                color: Theme.of(context).hintColor, size: 18),
            horizontalSpaceTiny,
            Tooltip(
              message: tenantLabel,
              child: SizedBox(
                width: 170,
                child: tenantName.isEmpty
                    ? Text(
                        '-',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      )
                    : SelectableText(
                        tenantName,
                        style: TextStyle(
                          color: tenantLcStatusEnum.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
      assignmentWidgetList.add(assignmentWidget);
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...assignmentWidgetList,
        ],
      ),
    );
  }
}

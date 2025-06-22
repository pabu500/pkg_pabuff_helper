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

import '../comm/comm_meter_group.dart';
import '../comm/comm_tenant.dart';
import '../model/mdl_pag_app_config.dart';
import 'wgt_comm_button.dart';

class WgtMeterGroupAssignment extends StatefulWidget {
  const WgtMeterGroupAssignment({
    super.key,
    required this.appConfig,
    required this.itemGroupIndexStr,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    required this.meterType,
    this.onScopeTreeUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String itemGroupIndexStr;
  final String itemName;
  final String itemLabel;
  final String meterType;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;

  @override
  State<WgtMeterGroupAssignment> createState() =>
      _WgtMeterGroupAssignmentState();
}

class _WgtMeterGroupAssignmentState extends State<WgtMeterGroupAssignment> {
  late final MdlPagUser? loggedInUser;

  final double width = 395.0;

  bool _isFetching = false;
  bool _isFetched = false;
  bool _modified = false;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  List<Map<String, dynamic>>? _itemGroupScopeMatchingItemList;
  List<Map<String, dynamic>>? _itemGroupItemList;

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
      _itemGroupItemList = List<Map<String, dynamic>>.from(itemGroupItemList);
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

  Future<void> _doGetMeterAssignment(Map<String, dynamic> itemInfo) async {
    if (itemInfo['is_fetching'] ?? false) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'meter_id': itemInfo['id'],
    };

    itemInfo['is_fetching'] = true;
    try {
      final data = await doGetMeterTenantAssignment(
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
      final meterAssignment = data['meter_assignment'];
      if (meterAssignment == null) {
        throw Exception('meter_assignment is null');
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
    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.itemGroupIndexStr,
      'item_assignment_list': _itemGroupScopeMatchingItemList,
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
        Container(
          // width: 20,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(widget.meterType),
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

  Widget getScopeItemList() {
    if (_itemGroupScopeMatchingItemList == null ||
        _itemGroupScopeMatchingItemList!.isEmpty) {
      return const Center(child: Text('No item found for this item group'));
    }
    List<Widget> itemWidgetList = [];
    int index = 0;
    for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
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
    String tenantName = itemInfo['name'] ?? 'Unknown Tenant';
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
          width: 100,
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
        getAssignmentBox(itemInfo),
      ],
    );
  }

  Widget getAssignmentBox(Map<String, dynamic> itemInfo) {
    final assignmentInfo = itemInfo['assignment_info'];
    bool hasAssignmentInfo = assignmentInfo != null;
    bool needToCheck = !hasAssignmentInfo;

    double barWidth = 180;
    double maxAssignedWidth = barWidth - 2;
    double totalTenantPercentage = 0.0;
    String tooltipMessage = '';
    double percentageAssignedToThisItemGroup = 0.0;
    final List<Map<String, dynamic>> tenantAssignmentList = [];
    final List<Map<String, dynamic>> assignmentBarList = [];
    if (hasAssignmentInfo) {
      final meterGroupAssignmentList = assignmentInfo['meter_assignment'];
      for (var meterGroupAssignment in meterGroupAssignmentList) {
        Map<String, dynamic> barInfo = {};
        if (meterGroupAssignment['meter_group_id'] ==
            widget.itemGroupIndexStr) {
          percentageAssignedToThisItemGroup =
              double.tryParse(meterGroupAssignment['percentage']) ?? 0.0;
          barInfo['mg_self_percentage'] = percentageAssignedToThisItemGroup;
        }

        final tenantInfo = meterGroupAssignment['tenant_info'];
        bool isAssignedToTenant = tenantInfo != null && tenantInfo.isNotEmpty;
        if (isAssignedToTenant) {
          tenantAssignmentList.add(tenantInfo);
          double? meterPercentage =
              double.tryParse(meterGroupAssignment['percentage']);
          totalTenantPercentage += meterPercentage ?? 0.0;
          barInfo['tenant_id'] = tenantInfo['id'];
          barInfo['tenant_name'] = tenantInfo['name'];
          barInfo['tenant_label'] = tenantInfo['label'] ?? '';
          barInfo['tenant_percentage'] = meterPercentage ?? 0.0;
        }
        assignmentBarList.add(barInfo);
      }

      if (tenantAssignmentList.isEmpty) {
        tooltipMessage = 'Not assigned to any tenant';
      }
    }

    List<Widget> assignmentBarWidgets = [];
    for (Map<String, dynamic> barInfo in assignmentBarList) {
      double? tenantPercentage = barInfo['tenant_percentage'];
      if (tenantPercentage != null) {
        String tenantName = barInfo['tenant_name'] ?? 'Unknown Tenant';
        String tenantLabel = barInfo['tenant_label'] ?? '';
        double assignedWidth =
            (tenantPercentage / 100.0) * maxAssignedWidth; // Calculate width

        Widget barWidget = Tooltip(
          message:
              '$tenantName ${tenantLabel.isNotEmpty ? "($tenantLabel)" : ""} - $tenantPercentage%',
          child: Container(
            width: assignedWidth,
            color: Colors.grey.shade700,
            child: Center(
              child: Text(
                tenantName,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        );
        assignmentBarWidgets.add(barWidget);
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
        totalTenantPercentage >= 100.0 || itemInfo['is_fetching'] == true;

    bool checked = itemInfo['assigned_new'] ??
        itemInfo['assigned'] ??
        percentageAssignedToThisItemGroup > 0.0;

    if (itemInfo['assigned_new'] == true) {
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
      height: 26,
      child: needToCheck
          ? WgtCommButton(
              label: 'Check Assignment',
              labelStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
              width: barWidth + margin,
              onPressed: () async {
                if (itemInfo['is_fetching'] ?? false) {
                  return;
                }
                await _doGetMeterAssignment(itemInfo);
              },
            )
          : Tooltip(
              message: tooltipMessage,
              waitDuration: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  Container(
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
                              _checkModified();
                            });
                          },
                  ),
                ],
              ),
            ),
    );
  }
}

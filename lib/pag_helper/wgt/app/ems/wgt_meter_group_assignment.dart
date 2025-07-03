import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/scope_helper.dart';
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

import '../../../comm/comm_meter_group.dart';
import '../../../comm/comm_tenant.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

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

  String? _selectedMeterIndexStr;

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
        _selectedMeterIndexStr = null;
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
          child: tile,
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

  Widget getItemRow(Map<String, dynamic> itemInfo, int index) {
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
            horizontalSpaceSmall,
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
              width: 120,
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
        if (_selectedMeterIndexStr == itemInfo['id']) getAssignmentMap(),
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
      final meterGroupAssignmentList =
          assignmentInfo['meter_tenant_assignment'];
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

    String assignmentError = '';
    if (totalTenantPercentage > 100.0) {
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
          String tenantName = barInfo['tenant_name'] ?? 'Unknown Tenant';
          String tenantLabel = barInfo['tenant_label'] ?? '';
          double assignedWidth =
              (tenantPercentage / 100.0) * maxAssignedWidth; // Calculate width

          Widget barWidget = Tooltip(
            message:
                '$tenantName ${tenantLabel.isNotEmpty ? "($tenantLabel)" : ""} - $tenantPercentage%',
            child: InkWell(
              onTap: _selectedMeterIndexStr == itemInfo['id']
                  ? null
                  : () {
                      if (itemInfo['is_fetching'] ?? false) {
                        return;
                      }

                      setState(() {
                        _selectedMeterIndexStr = itemInfo['id'];
                      });
                    },
              child: Container(
                width: assignedWidth,
                color: Colors.grey.shade700,
                child: Center(
                  child: Text(
                    tenantName,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
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
      // height: 26,
      child: needToCheck
          ? WgtCommButton(
              label: 'Check Assignment',
              labelStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13.5,
              ),
              width: barWidth + margin,
              onPressed: () async {
                if (itemInfo['is_fetching'] ?? false) {
                  return;
                }
                if (itemInfo['assignment_info'] == null) {
                  await _doGetMeterAssignment(itemInfo);
                }

                setState(() {
                  _selectedMeterIndexStr = itemInfo['id'];
                  // _checkModified();
                  // if (widget.onScopeTreeUpdate != null) {
                  //   widget.onScopeTreeUpdate!();
                  // }
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
                              _checkModified();
                            });
                          },
                  ),
                ],
              ),
            ),
    );
  }

  Widget getAssignmentMap() {
    if (_itemGroupScopeMatchingItemList == null ||
        _itemGroupScopeMatchingItemList!.isEmpty) {
      return Container();
    }
    // if (_itemGroupItemList == null || _itemGroupItemList!.isEmpty) {
    //   return Container();
    // }
    if (_selectedMeterIndexStr == null) {
      return Container();
    }

    Map<String, dynamic>? itemInfo;
    for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList!) {
      if (item['id'] == _selectedMeterIndexStr) {
        itemInfo = item;
        break;
      }
    }
    if (itemInfo == null) {
      return getErrorTextPrompt(
          context: context, errorText: 'Error: Item not found');
    }
    Map<String, dynamic>? assignmentInfo = itemInfo['assignment_info'];
    if (assignmentInfo == null) {
      return getErrorTextPrompt(
          context: context, errorText: 'Error: Assignment info not found');
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
          PagTenantLcStatus.byTag(tenantLcStatus);
      tenantLcStatusEnum ??= PagTenantLcStatus.normal;
      if (tenantInfo != null) {
        if (tenantLcStatusEnum == PagTenantLcStatus.normal ||
            tenantLcStatusEnum == PagTenantLcStatus.onbarding ||
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

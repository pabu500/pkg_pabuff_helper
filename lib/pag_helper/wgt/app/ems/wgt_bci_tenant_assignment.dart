import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../xt_ui/wdgt/datetime/wgt_date_picker.dart';
import '../../../comm/comm_billing_cost_item.dart';
import '../../../def_helper/dh_pag_tariff.dart';
import '../../../model/mdl_pag_app_config.dart';
import 'dart:developer' as dev;

class WgtBciTenantAssignment extends StatefulWidget {
  const WgtBciTenantAssignment({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.itemGroupIndexStr,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    // required this.tariffPackageTypeName,
    // required this.tariffPackageTypeLabel,
    required this.itemInfo,
    this.onScopeTreeUpdate,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;
  final String itemGroupIndexStr;
  final String itemName;
  final String itemLabel;
  final Map<String, dynamic> itemInfo;
  // final String tariffPackageTypeName;
  // final String tariffPackageTypeLabel;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtBciTenantAssignment> createState() => _WgtBciTenantAssignmentState();
}

class _WgtBciTenantAssignmentState extends State<WgtBciTenantAssignment> {
  final DateTime leftMostDate =
      DateTime.now().subtract(const Duration(days: 365 * 5));
  final DateTime rightMostDate =
      DateTime.now().add(const Duration(days: 365 * 5));

  final double width = 395.0;

  bool _isFetching = false;
  bool _isFetched = false;
  bool _modified = false;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  // List<Map<String, dynamic>>? _tariffPackageTenantList;
  List<Map<String, dynamic>>? _itemGroupScopeMatchingItemList;

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
      'scope': widget.loggedInUser!.selectedScope.toScopeMap(),
      'billing_cost_item_id': widget.itemGroupIndexStr,
    };

    _isFetching = true;
    try {
      final result = await doGetBciScopeTenantList(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser!.username,
          userId: widget.loggedInUser!.id,
          scope: '',
          target: '',
          operation: 'read',
        ),
      );
      final bciScopeMatchingTenantList =
          result['bci_scope_matching_tenant_list'];

      if (bciScopeMatchingTenantList == null) {
        throw Exception(
            'No scope matching tenant found for this billing cost item');
      }
      _itemGroupScopeMatchingItemList =
          List<Map<String, dynamic>>.from(bciScopeMatchingTenantList);
      // sort by label
      _itemGroupScopeMatchingItemList!.sort((a, b) {
        String labelA = a['tenant_label'] ?? '';
        String labelB = b['tenant_label'] ?? '';
        return labelA.compareTo(labelB);
      });

      for (Map<String, dynamic> tenant in _itemGroupScopeMatchingItemList!) {
        bool isassignedThisBci = tenant['is_assigned_to_this_bci'] == 'true';

        tenant['assigned'] = false;
        if (isassignedThisBci) {
          tenant['assigned'] = true;
        }
      }
    } catch (e) {
      dev.log(e.toString());

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
    // filter out items that are not modified
    final List<Map<String, dynamic>> assignmentList =
        _itemGroupScopeMatchingItemList!
            .where((tenant) => tenant['assigned_new'] != null)
            .toList();
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser!.selectedScope.toScopeMap(),
      'tariff_package_id': widget.itemGroupIndexStr,
      'tenant_assignment_list': assignmentList,
    };
    try {
      _isCommitting = true;

      final data = await commitBciTenantList(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser!.username,
          userId: widget.loggedInUser!.id,
          scope: '',
          target: '',
          operation: 'update',
        ),
      );

      if (data['error'] != null) {
        throw Exception(data['error']);
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
      });
    }
  }

  bool _showItem(Map<String, dynamic> item) {
    if (_itemNameFilterStr.isNotEmpty) {
      String? name = item['tenant_name'];
      bool nameMatches = (name ?? '').isNotEmpty &&
          (name ?? '').toLowerCase().contains(_itemNameFilterStr);
      return nameMatches;
    }
    if (_itemLabelFilterStr.isNotEmpty) {
      String? label = item['tenant_label'];
      bool labelMatches = (label ?? '').isNotEmpty &&
          (label ?? '').toLowerCase().contains(_itemLabelFilterStr);
      return labelMatches;
    }
    return true; // Include item if no filter is applied
  }

  bool _checkModified() {
    bool assignmentModified = false;
    for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList ?? []) {
      if (item['assigned_new'] != null) {
        if (item['assigned'] != item['assigned_new']) {
          assignmentModified = true;
          break;
        }
      }
    }
    bool effectiveDateModified = false;
    for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList ?? []) {
      // only assigned items can modify effective date
      if (item['assigned'] == true && item['assigned_new'] != false) {
        // if (item['tbci__effective_from_timestamp_new'] != null) {
        if (item['tbci_effective_from_timestamp'] !=
            item['tbci__effective_from_timestamp_new']) {
          effectiveDateModified = true;
          break;
        }
        // }
        // if (item['tbci__effective_to_timestamp_new'] != null) {
        if (item['tbci_effective_to_timestamp'] !=
            item['tbci__effective_to_timestamp_new']) {
          effectiveDateModified = true;
          break;
          // }
        }
      }
    }
    setState(() {
      _modified = assignmentModified || effectiveDateModified;
    });
    return assignmentModified || effectiveDateModified;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Symbols.assignment_ind, color: Colors.transparent),
              getBciInfo(),
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
          )
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
                  hintText: 'Tenant Name',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: 180,
            height: 39,
            child: TextField(
              controller: _itemLabelFilterController,
              readOnly: _isCommitting ||
                  _isCommitted ||
                  {_itemGroupScopeMatchingItemList ?? []}.isEmpty,
              decoration: InputDecoration(
                  hintText: 'Tenant Label',
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .hintColor) // prefixIcon: Icon(Icons.search),
                  ),
              onChanged: (value) {
                setState(() {
                  _itemLabelFilterStr = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        horizontalSpaceSmall,
        InkWell(
          onTap: (_itemGroupScopeMatchingItemList ?? []).isEmpty
              ? null
              : () {
                  setState(() {
                    for (Map<String, dynamic> tenant
                        in _itemGroupScopeMatchingItemList!) {
                      tenant['assigned_new'] = true;
                      if (tenant['assigned'] != tenant['assigned_new']) {
                        _modified = true;
                      }
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: boxDecoration,
            child: Text(
              'Select All',
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
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
              ? Text('✓ Committed',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary))
              : _commitErrorText.isNotEmpty
                  ? getErrorTextPrompt(
                      context: context, errorText: _commitErrorText)
                  : _isCommitting
                      ? const WgtPagWait(size: 21)
                      : Icon(Icons.cloud_upload,
                          color: _modified
                              ? commitColor
                              : Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget getBciInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Assignment',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Theme.of(context).hintColor),
        ),
        horizontalSpaceSmall,
        Icon(PagTariff.billingCostItem.iconData, size: 21),
        horizontalSpaceTiny,
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
        getScopeLabel(context, widget.itemScope),
      ],
    );
  }

  Widget getScopeItemList() {
    if (_itemGroupScopeMatchingItemList == null ||
        _itemGroupScopeMatchingItemList!.isEmpty) {
      return const Center(
        child: Text('No tenant found for this tariff package'),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          child: tile,
        ),
      );
    }

    return ListView.builder(
      itemExtent: 35,
      itemCount: itemWidgetList.length,
      itemBuilder: (context, index) {
        return itemWidgetList[index];
      },
    );
  }

  Widget getItemRow(Map<String, dynamic> itemInfo, int index) {
    String tenantName = itemInfo['tenant_name'] ?? 'Unknown Tenant';
    String tenantLabel = itemInfo['tenant_label'] ?? '';
    bool assigned = itemInfo['assigned'] ?? false;

    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );

    TextStyle disabledTextStyle =
        TextStyle(color: Theme.of(context).hintColor.withAlpha(150));

    bool disabled = itemInfo['assigned_to_another_tp_name'] != null;

    String disabledText = '';
    if (itemInfo['assigned'] == true &&
        itemInfo['assigned_to_this_tenant'] != true) {
      disabled = true;
      disabledText = 'Already assigned to: $tenantLabel';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 21,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              index.toString(),
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ),
        horizontalSpaceSmall,
        Container(
          width: 200,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SelectableText(tenantName,
              style: disabled ? disabledTextStyle : null),
        ),
        horizontalSpaceSmall,
        Container(
          width: 350,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SelectableText(tenantLabel.isNotEmpty ? tenantLabel : '-',
              style: disabled ? disabledTextStyle : null),
        ),
        horizontalSpaceTiny,
        getEffectiveDateRange(itemInfo),
        Tooltip(
          message: disabled ? disabledText : '',
          child: Checkbox(
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
                    widget.onScopeTreeUpdate?.call();
                  },
          ),
        ),
      ],
    );
  }

  Widget getEffectiveDateRange(Map<String, dynamic> itemInfo) {
    String effectiveFromTimestamp =
        itemInfo['tbci__effective_from_timestamp_new'] ??
            itemInfo['tbci_effective_from_timestamp'] ??
            '';
    String effectiveToTimestamp =
        itemInfo['tbci__effective_to_timestamp_new'] ??
            itemInfo['tbci_effective_to_timestamp'] ??
            '';
    DateTime? effectiveFromDateTime;
    DateTime? effectiveToDateTime;
    if (effectiveFromTimestamp.isNotEmpty) {
      effectiveFromDateTime = DateTime.tryParse(effectiveFromTimestamp);
    }
    if (effectiveToTimestamp.isNotEmpty) {
      effectiveToDateTime = DateTime.tryParse(effectiveToTimestamp);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: WgtDatePicker(
            // key: _timePickerFromKey,
            iconSize: 18,
            enabled: itemInfo['assigned_new'] == true ||
                (itemInfo['assigned'] == true &&
                    itemInfo['assigned_new'] != false),
            defaultFirstDate: leftMostDate,
            defaultLastDate: effectiveToDateTime ?? rightMostDate,
            initialDate: effectiveFromDateTime,
            labelFontSize: 15,
            timeZone: widget.loggedInUser!.selectedScope.getProjectTimezone(),
            label: 'Eff. From Date',
            onDateChanged: (DateTime selectedDate) {
              setState(() {
                effectiveFromDateTime = DateTime(selectedDate.year,
                    selectedDate.month, selectedDate.day, 0, 0, 0, 0);
                itemInfo['tbci__effective_from_timestamp_new'] =
                    effectiveFromDateTime?.toIso8601String();
                _checkModified();
              });
            },
            onDateCleared: () {
              setState(() {
                effectiveFromDateTime = null;
                itemInfo['tbci__effective_from_timestamp_new'] = '';
                _checkModified();
              });
            },
          ),
        ),
        horizontalSpaceTiny,
        SizedBox(
          width: 150,
          child: WgtDatePicker(
            // key: _timePickerToKey,
            iconSize: 18,
            enabled: itemInfo['assigned_new'] == true ||
                (itemInfo['assigned'] == true &&
                    itemInfo['assigned_new'] != false),
            defaultFirstDate: effectiveFromDateTime ?? leftMostDate,
            defaultLastDate: effectiveToDateTime ?? rightMostDate,
            initialDate: effectiveToDateTime,
            labelFontSize: 15,
            timeZone: widget.loggedInUser!.selectedScope.getProjectTimezone(),
            label: 'Eff. To Date',
            onDateChanged: (DateTime selectedDate) {
              setState(() {
                effectiveToDateTime = DateTime(selectedDate.year,
                        selectedDate.month, selectedDate.day, 0, 0, 0, 0)
                    .add(const Duration(days: 1));
                itemInfo['tbci__effective_to_timestamp_new'] =
                    effectiveToDateTime?.toIso8601String();
                _checkModified();
              });
            },
            onDateCleared: () {
              setState(() {
                effectiveToDateTime = null;
                itemInfo['tbci__effective_to_timestamp_new'] = '';
                _checkModified();
              });
            },
          ),
        ),
      ],
    );
  }
}

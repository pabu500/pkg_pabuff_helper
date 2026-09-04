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

import '../../../comm/comm_tariff_package.dart';
import '../../../def_helper/dh_pag_item.dart';
import '../../../model/mdl_pag_app_config.dart';
import 'dart:developer' as dev;

class WgtTariffPackageAssignment extends StatefulWidget {
  const WgtTariffPackageAssignment({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.itemGroupIndexStr,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    required this.meterType,
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
  final String meterType;
  final Map<String, dynamic> itemInfo;
  // final String tariffPackageTypeName;
  // final String tariffPackageTypeLabel;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtTariffPackageAssignment> createState() =>
      _WgtTariffPackageAssignmentState();
}

class _WgtTariffPackageAssignmentState
    extends State<WgtTariffPackageAssignment> {
  final double width = 395.0;

  bool _isFetching = false;
  bool _isFetched = false;
  bool _hasTptMismatchAssignmentError = false;
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
  final TextEditingController _accountNumberFilterController =
      TextEditingController();
  String _accountNumberFilterStr = '';

  Future<void> _doAutoPopulate() async {
    if (_isFetching) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser!.selectedScope.toScopeMap(),
      'tariff_package_id': widget.itemGroupIndexStr,
    };

    _isFetching = true;
    try {
      final data = await doGetTariffPackageScopeTenantList(
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
      final tpAssignment = data['tariff_package_assignment'];
      if (tpAssignment == null || tpAssignment.isEmpty) {
        throw Exception('No tenant found for this tariff package');
      }
      final tpScopeMatchingTenantList =
          tpAssignment['tariff_package_scope_matching_tenant_list'];

      if (tpScopeMatchingTenantList == null) {
        throw Exception(
            'No scope matching tenant found for this tariff package');
      }
      _itemGroupScopeMatchingItemList =
          List<Map<String, dynamic>>.from(tpScopeMatchingTenantList);

      for (Map<String, dynamic> tenant in _itemGroupScopeMatchingItemList!) {
        String tenantMeterTypeTpKey =
            'tp_name_${widget.meterType.toLowerCase()}';
        String tenantMeterTypeTpTypeName =
            tenant['tpt_name_${widget.meterType.toLowerCase()}'] ??
                'Unknown TPT';

        String? tpName = tenant[tenantMeterTypeTpKey];
        bool isUnassigned = tpName == null;

        bool isAsignedToOtherTps = tpName != null && tpName != widget.itemName;
        final tptName = tenant['tpt_name_${widget.meterType.toLowerCase()}'] ??
            'Unknown TPT';

        bool hasTptMismatch = tenantMeterTypeTpTypeName != tptName;

        tenant['assigned'] = false;
        if (!isUnassigned && !isAsignedToOtherTps) {
          tenant['assigned'] = true;
        }
        tenant['assigned_to_current_tp'] =
            !isUnassigned && !isAsignedToOtherTps;
        if (isAsignedToOtherTps) {
          tenant['assigned_to_another_tp_name'] = tpName;
          tenant['assigned'] = true;
        }
        tenant['tpt_mismatch'] = hasTptMismatch;
        bool tptMismatchAssignmentError =
            !isUnassigned && hasTptMismatch && !isAsignedToOtherTps;
        tenant['tpt_mismatch_assignment_error'] = tptMismatchAssignmentError;

        if (tptMismatchAssignmentError) {
          _hasTptMismatchAssignmentError = true;
        }
      }

      // Keep assignments to this package at the top and assignments to other
      // packages at the bottom. Pending checkbox changes deliberately do not
      // re-sort the list so the row being edited stays in view.
      _itemGroupScopeMatchingItemList!.sort((a, b) {
        int assignmentRank(Map<String, dynamic> tenant) {
          if (tenant['assigned_to_current_tp'] == true) {
            return 0;
          }
          if (tenant['assigned_to_another_tp_name'] != null) {
            return 2;
          }
          return 1;
        }

        final rankComparison = assignmentRank(a).compareTo(assignmentRank(b));
        if (rankComparison != 0) {
          return rankComparison;
        }

        final labelA = (a['label'] ?? '').toString().toLowerCase();
        final labelB = (b['label'] ?? '').toString().toLowerCase();
        return labelA.compareTo(labelB);
      });
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

      final data = await commitTariffPackageTenantList(
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
    final name = (item['name'] ?? '').toString().toLowerCase();
    final label = (item['label'] ?? '').toString().toLowerCase();
    final accountNumber =
        (item['account_number'] ?? '').toString().toLowerCase();

    return (_itemNameFilterStr.isEmpty || name.contains(_itemNameFilterStr)) &&
        (_itemLabelFilterStr.isEmpty || label.contains(_itemLabelFilterStr)) &&
        (_accountNumberFilterStr.isEmpty ||
            accountNumber.contains(_accountNumberFilterStr));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _itemNamefilterController.dispose();
    _itemLabelFilterController.dispose();
    _accountNumberFilterController.dispose();
    super.dispose();
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
              getTpInfo(),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: 150,
            height: 39,
            child: TextField(
              controller: _accountNumberFilterController,
              readOnly: _isCommitting ||
                  _isCommitted ||
                  {_itemGroupScopeMatchingItemList ?? []}.isEmpty,
              decoration: InputDecoration(
                hintText: 'Tenant Account No.',
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
              ),
              onChanged: (value) {
                setState(() {
                  _accountNumberFilterStr = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        horizontalSpaceSmall,
        InkWell(
          onTap: (_itemGroupScopeMatchingItemList ?? []).isEmpty ||
                  _hasTptMismatchAssignmentError
              ? null
              : () {
                  setState(() {
                    for (Map<String, dynamic> tenant
                        in _itemGroupScopeMatchingItemList!) {
                      if (tenant['tpt_mismatch']) {
                        continue;
                      }
                      tenant['assigned_new'] = true;
                      if (tenant['assigned'] != tenant['assigned_new']) {
                        _modified = true;
                      }
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: _hasTptMismatchAssignmentError
                ? boxDecoration.copyWith(
                    color:
                        Theme.of(context).colorScheme.secondary.withAlpha(130))
                : boxDecoration,
            child: Text(
              'Select All',
              style: TextStyle(
                color: _hasTptMismatchAssignmentError
                    ? Theme.of(context).hintColor
                    : null,
              ),
            ),
          ),
        ),
        horizontalSpaceSmall,
        InkWell(
          onTap: !_modified ||
                  _isCommitting ||
                  _isCommitted ||
                  (_itemGroupScopeMatchingItemList ?? []).isEmpty ||
                  _hasTptMismatchAssignmentError
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
                          color: _modified && !_hasTptMismatchAssignmentError
                              ? commitColor
                              : Theme.of(context).hintColor),
        ),
        if (_hasTptMismatchAssignmentError)
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: boxDecoration.copyWith(color: Colors.transparent),
            child: Text(
              '✘ TPT Mismatch Error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget getTpInfo() {
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor, width: 1.5),
      borderRadius: BorderRadius.circular(5),
    );
    final tptLabel = widget.itemInfo['tpt_label'] ?? 'Unknown TPT';
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
        Icon(PagItemKind.tariff.iconData, size: 21),
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
        // Container(
        //   decoration: boxDecoration,
        //   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       scopeIcon,
        //       horizontalSpaceTiny,
        //       Text(tariffPackageScopeLabel),
        //     ],
        //   ),
        // ),
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
        Container(
          // width: 60,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(tptLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
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
    String tenantName = itemInfo['name'] ?? 'Unknown Tenant';
    String tenantLabel = itemInfo['label'] ?? '';
    String tenantAccountNumber = (itemInfo['account_number'] ?? '').toString();

    String? meterTypeTptLabel =
        itemInfo['tpt_label_${widget.meterType.toLowerCase()}'];
    if (meterTypeTptLabel == null) {
      // if (kDebugMode) {
      // meter type tpt is not assigned for this tenant
      dev.log('meterTypeTptLabel is null for ${widget.meterType} in itemInfo');
      // }
      // return const SizedBox.shrink();
    }
    // assert(meterTypeTptLabel.isNotEmpty);

    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );

    TextStyle disabledTextStyle =
        TextStyle(color: Theme.of(context).hintColor.withAlpha(150));

    bool disabled =
        // meterTypeTptLabel == null ||
        _hasTptMismatchAssignmentError ||
            itemInfo['assigned_to_another_tp_name'] != null ||
            itemInfo['tpt_mismatch'] ||
            itemInfo['tpt_mismatch_assignment_error'];

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
          width: 180,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Tooltip(
            message: tenantLabel,
            child: Text(
              tenantLabel.isNotEmpty ? tenantLabel : '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: disabled ? disabledTextStyle : null,
            ),
          ),
        ),
        horizontalSpaceSmall,
        Container(
          width: 150,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SelectableText(
            tenantAccountNumber.isNotEmpty ? tenantAccountNumber : '-',
            maxLines: 1,
            style: disabled ? disabledTextStyle : null,
          ),
        ),
        horizontalSpaceSmall,
        Tooltip(
          message:
              // meterTypeTptLabel == null
              //     ? 'Tpt is not set for the tenant'
              //     :
              itemInfo['tpt_mismatch_assignment_error']
                  ? 'TP Type Mismatch Error'
                  : itemInfo['tpt_mismatch'] &&
                          (itemInfo['assigned_to_another_tp_name'] == null)
                      ? 'TP Type Mismatch'
                      : '',
          child: Container(
            width: 90,
            decoration: itemInfo['tpt_mismatch_assignment_error']
                ? boxDecoration.copyWith(
                    border:
                        Border.all(color: Theme.of(context).colorScheme.error))
                : itemInfo['tpt_mismatch'] &&
                        (itemInfo['assigned_to_another_tp_name'] == null)
                    ? boxDecoration.copyWith(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.error))
                    : boxDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(meterTypeTptLabel ?? '-',
                style: disabled ? disabledTextStyle : null),
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
                  widget.onScopeTreeUpdate?.call();
                },
        ),
        itemInfo['assigned_to_another_tp_name'] != null
            ? Tooltip(
                message:
                    'Assigned to another tariff package: ${itemInfo['assigned_to_another_tp_name']}',
                child: const Icon(
                  Symbols.info,
                  color: Colors.blue,
                  size: 18,
                ),
              )
            : const SizedBox(width: 18),
      ],
    );
  }
}

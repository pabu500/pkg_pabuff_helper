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

import '../comm/comm_tariff_package.dart';
import '../model/mdl_pag_app_config.dart';

class WgtTariffPackageAssignment extends StatefulWidget {
  const WgtTariffPackageAssignment({
    super.key,
    required this.appConfig,
    required this.itemGroupIndexStr,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    required this.meterType,
    required this.tariffPackageTypeName,
    required this.tariffPackageTypeLabel,
    this.onScopeTreeUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String itemGroupIndexStr;
  final String itemName;
  final String itemLabel;
  final String meterType;
  final String tariffPackageTypeName;
  final String tariffPackageTypeLabel;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;

  @override
  State<WgtTariffPackageAssignment> createState() =>
      _WgtTariffPackageAssignmentState();
}

class _WgtTariffPackageAssignmentState
    extends State<WgtTariffPackageAssignment> {
  late final MdlPagUser? loggedInUser;

  final double width = 395.0;

  bool _isFetching = false;
  bool _isFetched = false;
  bool _hasTptMismatchAssignmentError = false;
  bool _modified = false;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  // List<Map<String, dynamic>>? _tariffPackageTenantList;
  List<Map<String, dynamic>>? _tariffPackageScopeMatchingTenantList;

  Future<void> _doAutoPopulate() async {
    if (_isFetching) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'tariff_package_id': widget.itemGroupIndexStr,
    };

    _isFetching = true;
    try {
      final data = await doGetScopeTenantList(
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
      _tariffPackageScopeMatchingTenantList =
          List<Map<String, dynamic>>.from(tpScopeMatchingTenantList);
      // sort by label
      _tariffPackageScopeMatchingTenantList!.sort((a, b) {
        String labelA = a['label'] ?? '';
        String labelB = b['label'] ?? '';
        return labelA.compareTo(labelB);
      });

      for (Map<String, dynamic> tenant
          in _tariffPackageScopeMatchingTenantList!) {
        String tenantMeterTypeTpKey =
            'tp_name_${widget.meterType.toLowerCase()}';
        String tenantMeterTypeTpTypeName =
            tenant['tpt_name_${widget.meterType.toLowerCase()}'] ?? '';

        String? tpName = tenant[tenantMeterTypeTpKey];
        bool isUnassigned = tpName == null;

        bool isAsignedToOtherTps = tpName != null && tpName != widget.itemName;
        bool hasTptMismatch =
            tenantMeterTypeTpTypeName != widget.tariffPackageTypeName;
        tenant['assigned'] = false;
        if (!isUnassigned && !isAsignedToOtherTps) {
          tenant['assigned'] = true;
        }
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
      'tariff_package_id': widget.itemGroupIndexStr,
      'tenant_assignment_list': _tariffPackageScopeMatchingTenantList,
    };
    try {
      _isCommitting = true;

      final data = await commitTariffPackageTenantList(
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

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
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
      child: getScopeTenantList(),
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
          onTap: (_tariffPackageScopeMatchingTenantList ?? []).isEmpty ||
                  _hasTptMismatchAssignmentError
              ? null
              : () {
                  setState(() {
                    for (Map<String, dynamic> tenant
                        in _tariffPackageScopeMatchingTenantList!) {
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
                  (_tariffPackageScopeMatchingTenantList ?? []).isEmpty ||
                  _hasTptMismatchAssignmentError
              ? null
              : () async {
                  await _doCommit();
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
    String tariffPackageScopeLabel = widget.itemScope.getLeafScopeLabel();
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
              fontWeight: FontWeight.bold, color: Theme.of(context).hintColor),
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
              Text(tariffPackageScopeLabel),
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
        Container(
          // width: 60,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(widget.tariffPackageTypeLabel),
        ),
      ],
    );
  }

  Widget getScopeTenantList() {
    if (_tariffPackageScopeMatchingTenantList == null ||
        _tariffPackageScopeMatchingTenantList!.isEmpty) {
      return const Center(
        child: Text('No tenant found for this tariff package'),
      );
    }
    List<Widget> tenantWidgets = [];
    int index = 0;
    for (Map<String, dynamic> tenant
        in _tariffPackageScopeMatchingTenantList!) {
      Widget tile = getTenantRow(tenant, ++index);
      tenantWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          child: tile,
        ),
      );
    }

    return ListView.builder(
      itemExtent: 35,
      itemCount: tenantWidgets.length,
      itemBuilder: (context, index) {
        return tenantWidgets[index];
      },
    );
  }

  Widget getTenantRow(Map<String, dynamic> itemInfo, int index) {
    String tenantName = itemInfo['name'] ?? 'Unknown Tenant';
    String tenantLabel = itemInfo['label'] ?? '';
    bool assigned = itemInfo['assigned'] ?? false;

    String? meterTypeTptLabel =
        itemInfo['tpt_label_${widget.meterType.toLowerCase()}'];
    if (meterTypeTptLabel == null) {
      if (kDebugMode) {
        // meter type tpt is not assigned for this tenant
        print(
            'Error: meterTypeTptLabel is null for ${widget.meterType} in itemInfo: $itemInfo');
      }
      return const SizedBox.shrink();
    }
    assert(meterTypeTptLabel.isNotEmpty);

    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );

    TextStyle disabledTextStyle =
        TextStyle(color: Theme.of(context).hintColor.withAlpha(150));

    bool disabled = _hasTptMismatchAssignmentError ||
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
          width: 350,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SelectableText(tenantLabel.isNotEmpty ? tenantLabel : '-',
              style: disabled ? disabledTextStyle : null),
        ),
        horizontalSpaceSmall,
        Tooltip(
          message: itemInfo['tpt_mismatch_assignment_error']
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
                        border: Border.all(color: Colors.yellow.withAlpha(130)))
                    : boxDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(meterTypeTptLabel,
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

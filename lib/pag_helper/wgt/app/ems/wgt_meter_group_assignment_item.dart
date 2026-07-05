import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../xt_ui/wdgt/info/get_error_text_prompt.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../def_helper/dh_device.dart';
import '../../../def_helper/dh_pag_tenant.dart';
import '../../../def_helper/pag_item_helper.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';
import '../../wgt_comm_button.dart';
import '../ems/wgt_meter_assignment_op.dart';

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
  // bool _assignmentInfoFetched = false;
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
    String itemName = itemInfo['meter_name'] ?? '-';
    String itemLabel = itemInfo['meter_label'] ?? '-';
    String meterSn = itemInfo['meter_sn'] ?? '-';
    // bool assigned = itemInfo['assigned'] ?? false;

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
              width: 150,
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
        if (true) getAssignmentMap(itemInfo),
      ],
    );
  }

  Widget getAssignmentBox(Map<String, dynamic> itemInfo) {
    final assignmentInfo = itemInfo['assignment'];
    bool infoFetched = itemInfo['info_fetched'] ?? false;
    bool hasAssignmentInfo = assignmentInfo != null;
    bool needToCheck = !hasAssignmentInfo && !infoFetched;

    double barWidth = 195;
    double margin = 150;

    if (needToCheck) {
      return WgtCommButton(
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
          if (itemInfo['assignment'] == null) {
            await widget.getMeterAssignment(itemInfo);
          }

          setState(() {
            // _selectedMeterIndexStr = itemInfo['id'];
          });
        },
      );
    }

    return WgtMeterAssignmentOp(
      appConfig: widget.appConfig,
      strMeterGroupId: widget.itemGroupIndexStr,
      meterInfo: itemInfo,
      onPercentageChanged: (newPercentage) {
        Map<String, dynamic> assignmentNew = itemInfo['assignment_new'] ?? {};
        assignmentNew['percentage'] = newPercentage.toString();
        assignmentNew['meter_group_id'] = widget.itemGroupIndexStr;
        assignmentNew['meter_id'] = itemInfo['id'];

        setState(() {
          // itemInfo['assigned_new'] = newPercentage > 0.0;
          // itemInfo['percentage_new'] = newPercentage;
          itemInfo['assignment_new'] = assignmentNew;

          widget.onModified?.call();
        });
      },
    );
  }

  Widget getAssignmentMap(Map<String, dynamic> itemInfo) {
    bool infoFetched = itemInfo['info_fetched'] ?? false;
    if (!infoFetched) {
      return Container();
    }
    final assignment = itemInfo['assignment'];
    // if (assignment == null || assignment.isEmpty) {
    //   if (_assignmentInfoFetched) {
    //     return getErrorTextPrompt(
    //         context: context, errorText: 'Error: Assignment info not found');
    //   } else {
    //     return Container();
    //   }
    // }
    final meterTeantAssignmentList = assignment;
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

      bool isThisMeterGroup =
          assignment['meter_group_id'] == widget.itemGroupIndexStr;

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
            Tooltip(
              message: isThisMeterGroup ? 'This meter group' : '',
              waitDuration: const Duration(milliseconds: 500),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isThisMeterGroup
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).hintColor.withAlpha(50)),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                child: SizedBox(
                  width: 150,
                  child: SelectableText(
                    meterGroupName,
                    style: TextStyle(
                        color:
                            //  meterGroupIsAssignedToActiveTenant
                            //     ? Colors.greenAccent.withAlpha(210)
                            //     :
                            Theme.of(context).hintColor),
                  ),
                ),
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
                width: 175,
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

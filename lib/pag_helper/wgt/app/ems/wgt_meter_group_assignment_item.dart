import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../xt_ui/style/evs2_colors.dart';
import '../../../../xt_ui/wdgt/info/get_error_text_prompt.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../def_helper/dh_device.dart';
import '../../../def_helper/dh_pag_tenant.dart';
import '../../../def_helper/dh_scope.dart';
import '../../../def_helper/pag_item_helper.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';
import '../../../model/scope/mdl_pag_scope.dart';
import '../../wgt_comm_button.dart';
import '../ems/wgt_meter_assignment_op.dart';

class WgtMeterGroupAssignmentItem extends StatefulWidget {
  const WgtMeterGroupAssignmentItem({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.itemInfo,
    required this.getMeterAssignment,
    required this.strItemGroupIndex,
    this.regFresh,
    this.onModified,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> itemInfo;
  final String strItemGroupIndex;
  final void Function(void Function(bool isComm, bool isEnabled))? regFresh;
  final Future<void> Function(Map<String, dynamic> itemInfo) getMeterAssignment;
  final void Function(String)? onModified;

  @override
  State<WgtMeterGroupAssignmentItem> createState() =>
      _WgtMeterGroupAssignmentItemState();
}

class _WgtMeterGroupAssignmentItemState
    extends State<WgtMeterGroupAssignmentItem> {
  late Map<String, dynamic> _itemInfo;

  bool _isComm = false;
  bool _isEnabled = false;

  bool _showScope = false;

  MdlPagScope? _itemScope;

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

    _itemInfo = widget.itemInfo;

    String? itemLocationId = _itemInfo['item_location_id'];
    String? itemLocationName = _itemInfo['item_location_name'];
    String? itemLocationLabel = _itemInfo['item_location_label'];

    String? itemLocationGroupId = _itemInfo['item_location_group_id'];
    String? itemLocationGroupName = _itemInfo['item_location_group_name'];
    String? itemLocationGroupLabel = _itemInfo['item_location_group_label'];

    String? itemBuildingId = _itemInfo['item_building_id'];
    String? itemBuildingName = _itemInfo['item_building_name'];
    String? itemBuildingLabel = _itemInfo['item_building_label'];

    String? itemSiteId = _itemInfo['item_site_id'];
    String? itemSiteName = _itemInfo['item_site_name'];
    String? itemSiteLabel = _itemInfo['item_site_label'];

    String? itemSiteGroupId = _itemInfo['item_site_group_id'];
    String? itemSiteGroupName = _itemInfo['item_site_group_name'];
    String? itemSiteGroupLabel = _itemInfo['item_site_group_label'];

    Map<String, dynamic> itemScopeInfo = {
      'location_id': itemLocationId,
      'location_name': itemLocationName,
      'location_label': itemLocationLabel,
      'location_group_id': itemLocationGroupId,
      'location_group_name': itemLocationGroupName,
      'location_group_label': itemLocationGroupLabel,
      'building_id': itemBuildingId,
      'building_name': itemBuildingName,
      'building_label': itemBuildingLabel,
      'site_id': itemSiteId,
      'site_name': itemSiteName,
      'site_label': itemSiteLabel,
      'site_group_id': itemSiteGroupId,
      'site_group_name': itemSiteGroupName,
      'site_group_label': itemSiteGroupLabel,
      'project_id': _itemInfo['project_id'],
      'project_name': _itemInfo['project_name'],
    };
    _itemScope = MdlPagScope.fromJson(itemScopeInfo);
    assert(_itemScope != null, 'Failed to create scope from item info');
  }

  @override
  Widget build(BuildContext context) {
    // return widget;
    return _isComm
        ? const WgtPagWait(size: 21)
        : InkWell(
            onTap: !_isEnabled ? null : () {},
            child: getAssignmentRow(),
          );
  }

  Widget getAssignmentRow() {
    int index = _itemInfo['index'] ?? 0;
    String itemName = _itemInfo['meter_name'] ?? '-';
    String itemLabel = _itemInfo['meter_label'] ?? '-';
    String meterSn = _itemInfo['meter_sn'] ?? '-';
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
            Tooltip(
              message: 'Show/Hide Scope',
              waitDuration: const Duration(milliseconds: 500),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showScope = !_showScope;
                  });
                },
                child: Icon(
                  _showScope ? Symbols.expand_less : Symbols.expand_more,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
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
            getAssignmentBox(),
          ],
        ),
        if (_showScope && _itemScope != null)
          Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [getScopeLabel(context, _itemScope!)],
            ),
          ),
        if (true) getAssignmentMap(),
      ],
    );
  }

  Widget getAssignmentBox() {
    Map<String, dynamic> itemInfo = _itemInfo;
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
      strMeterGroupId: widget.strItemGroupIndex,
      meterInfo: itemInfo,
      onPercentageChanged: (newPercentage, assignmentErrorMessage) {
        final assignment = itemInfo['assignment'] ?? [];

        // find the assignment to this meter group
        Map<String, dynamic> assignmentToThisMeterGroup = assignment.firstWhere(
          (assignment) =>
              assignment['meter_group_id'] == widget.strItemGroupIndex,
          orElse: () => {},
        );
        assert(assignmentToThisMeterGroup.isNotEmpty,
            'Assignment to this meter group not found');

        // update the assignment to this meter group with the new percentage
        Map<String, dynamic> updatedAssignmentToThisMeterGroup = {};
        updatedAssignmentToThisMeterGroup.addAll(assignmentToThisMeterGroup);
        updatedAssignmentToThisMeterGroup['percentage'] =
            newPercentage.toString();

        setState(() {
          itemInfo['updated_meter_assignment_to_this_meter_group'] =
              updatedAssignmentToThisMeterGroup;
          itemInfo['assignment_error_message'] = assignmentErrorMessage;

          widget.onModified?.call(assignmentErrorMessage);
        });
      },
    );
  }

  Widget getAssignmentMap() {
    bool infoFetched = _itemInfo['info_fetched'] ?? false;
    if (!infoFetched) {
      return Container();
    }
    bool isCurrentMeterGroupAssignmentUpdated =
        _itemInfo['updated_meter_assignment_to_this_meter_group'] != null;
    final assignmentList = _itemInfo['assignment'];
    String assignmentErrorMessage = _itemInfo['assignment_error_message'] ?? '';
    if (_itemInfo['updated_meter_assignment_to_this_meter_group'] != null) {
      // replace the assginment of the current meter group with the updated assignment
      final updatedAssignment =
          _itemInfo['updated_meter_assignment_to_this_meter_group'];
      if (assignmentList is List) {
        int index = assignmentList.indexWhere((assignment) =>
            assignment['meter_group_id'] == widget.strItemGroupIndex);
        if (index != -1) {
          assignmentList[index] = updatedAssignment;
        } else {
          assignmentList.add(updatedAssignment);
        }
      }
    }
    // if (assignment == null || assignment.isEmpty) {
    //   if (_assignmentInfoFetched) {
    //     return getErrorTextPrompt(
    //         context: context, errorText: 'Error: Assignment info not found');
    //   } else {
    //     return Container();
    //   }
    // }
    final meterTeantAssignmentList = assignmentList;
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
          assignment['meter_group_id'] == widget.strItemGroupIndex;

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
                          ? assignmentErrorMessage.isNotEmpty
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary
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
                style: TextStyle(
                  color:
                      isCurrentMeterGroupAssignmentUpdated && isThisMeterGroup
                          ? assignmentErrorMessage.isNotEmpty
                              ? Theme.of(context).colorScheme.error
                              : commitColor.withAlpha(210)
                          : Theme.of(context).hintColor,
                ),
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

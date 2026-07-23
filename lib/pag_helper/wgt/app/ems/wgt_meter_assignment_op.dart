import 'package:flutter/material.dart';

import '../../../../xt_ui/style/evs2_colors.dart';
import '../../../../xt_ui/wdgt/input/wgt_text_field2.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../def_helper/dh_pag_tenant.dart';
import '../../../model/mdl_pag_app_config.dart';

class WgtMeterAssignmentOp extends StatefulWidget {
  final MdlPagAppConfig appConfig;
  final String strMeterGroupId;
  final Map<String, dynamic> meterInfo;
  final void Function(double, String) onPercentageChanged;

  const WgtMeterAssignmentOp({
    super.key,
    required this.appConfig,
    required this.strMeterGroupId,
    required this.meterInfo,
    required this.onPercentageChanged,
  });

  @override
  State<WgtMeterAssignmentOp> createState() => _WgtMeterAssignmentOpState();
}

class _WgtMeterAssignmentOpState extends State<WgtMeterAssignmentOp> {
  final double barWidth = 195;
  final double opWidth = 150;

  double? _percentAssignedToThisGroup;
  double? _percentAssignedToThisGroupNew;

  double? _totalPercentAssignedToThisMeter;

  UniqueKey? _inputRefreshKey;

  final List<Widget> assignmentBarWidgetList = [];

  bool _disableOp = false;
  bool _currentMeterGroupAssignedToTenant = false;

  String _disabledMessage = '';
  bool _hasAssignmentError = false;
  String _assignmentErrorMsg = '';

  void _loadAssignmentBar() {
    assignmentBarWidgetList.clear();
    _totalPercentAssignedToThisMeter = 0;
    _currentMeterGroupAssignedToTenant = false;
    _disableOp = false;
    _hasAssignmentError = false;
    _assignmentErrorMsg = '';
    _disabledMessage = '';

    final assignmentInfo = widget.meterInfo['assignment'];
    // bool infoFetched = widget.meterInfo['info_fetched'] ?? false;
    // bool hasAssignmentInfo = assignmentInfo != null && assignmentInfo.isNotEmpty;
    // bool needToCheck = !hasAssignmentInfo && !infoFetched;

    double maxAssignedWidth = barWidth - 2;

    // if (hasAssignmentInfo) {
    final meterGroupAssignmentList = assignmentInfo ?? [];

    String barMessage = '';

    // if there is a new meter percentage assigned to this group,
    // and this meter is not in the assignment list, add it to the list
    // so that the bar can show the new percentage assigned to this group
    if (_percentAssignedToThisGroupNew != null) {
      bool assignmentListContainsThisMeter = meterGroupAssignmentList.any(
        (assignment) => assignment['meter_group_id'] == widget.strMeterGroupId,
      );
      if (!assignmentListContainsThisMeter) {
        meterGroupAssignmentList.add({
          'meter_group_id': widget.strMeterGroupId,
          'meter_group_name': 'Current Meter Group',
          'meter_group_label': '',
          'percentage': _percentAssignedToThisGroupNew.toString(),
        });
      }
    }

    for (var meterGroupAssignment in meterGroupAssignmentList) {
      Map<String, dynamic> barInfo = {};

      bool isCurrentMeterGroup =
          meterGroupAssignment['meter_group_id'] == widget.strMeterGroupId;

      if (isCurrentMeterGroup) {
        _percentAssignedToThisGroup ??=
            double.tryParse(meterGroupAssignment['percentage']) ?? 0.0;
        // barInfo['mg_self_percentage'] = _percentAssignedToThisGroup;
      }

      String meterGroupName = meterGroupAssignment['meter_group_name'] ?? '';
      String meterGroupLabel = meterGroupAssignment['meter_group_label'] ?? '';

      double? meterPercentage =
          double.tryParse(meterGroupAssignment['percentage']);
      if (isCurrentMeterGroup && _percentAssignedToThisGroupNew != null) {
        meterPercentage = _percentAssignedToThisGroupNew;
      }

      double barWidth = (meterPercentage ?? 0.0) / 100.0 * maxAssignedWidth;

      final tenantInfo = meterGroupAssignment['tenant_info'];
      bool isAssignedToTenant = tenantInfo != null && tenantInfo.isNotEmpty;

      // // do not count unassigned meter groups in the total percentage
      // // assigned to this meter
      // // so that percentage assigned to unassigned meter groups
      // // is available for assignment to other tenants
      // if (!isAssignedToTenant) {
      //   continue; // skip unassigned meter groups
      // }

      if (isAssignedToTenant) {
        final tenantLcStatusStr = tenantInfo['lc_status'] ?? '';
        final tenantLcStatus = PagTenantLcStatus.byValue(tenantLcStatusStr);

        // NOTE: not counting terminated and MFD tenants
        // in the total percentage assigned to this meter
        // so percentage assigned to terminated or MFD tenants
        // is available for assignment to other tenants
        if (tenantLcStatus == PagTenantLcStatus.terminated ||
            tenantLcStatus == PagTenantLcStatus.mfd) {
          continue; // skip terminated tenants
        }
      }

      _totalPercentAssignedToThisMeter =
          (_totalPercentAssignedToThisMeter ?? 0.0) + (meterPercentage ?? 0.0);
      if (_totalPercentAssignedToThisMeter! > 100.0) {
        _hasAssignmentError = true;
        _assignmentErrorMsg =
            'Total percentage assigned to this meter exceeds 100%';
        _disableOp = true;
      } else if (_totalPercentAssignedToThisMeter! > 99.9999999) {
        if (!isCurrentMeterGroup) {
          _disableOp = true;
          _disabledMessage =
              'Total percentage assigned to this meter is 100%, cannot assign more';
        }
      } else {
        _hasAssignmentError = false;
        _assignmentErrorMsg = '';
        _disableOp = false;
      }

      // bool isAssignedToTenant = tenantInfo != null && tenantInfo.isNotEmpty;
      if (isAssignedToTenant) {
        // tenantAssignmentList.add(tenantInfo);
        if (isCurrentMeterGroup) {
          _currentMeterGroupAssignedToTenant = true;
        }

        // totalPercentAssignedToTenant += meterPercentage ?? 0.0;
        String tenantName = tenantInfo['name'] ?? 'Unknown Tenant';
        String tenantLabel = tenantInfo['label'] ?? '';
        barInfo['tenant_id'] = tenantInfo['id'];
        barInfo['tenant_name'] = tenantName;
        barInfo['tenant_label'] = tenantLabel;
        barInfo['tenant_lc_status'] = tenantInfo['lc_status'] ?? '';
        barInfo['tenant_percentage'] = meterPercentage ?? 0.0;
      }

      barMessage = '$meterPercentage% -> $meterGroupName ($meterGroupLabel) ';

      if (isAssignedToTenant) {
        String tenantName = barInfo['tenant_name'];
        String tenantLabel = barInfo['tenant_label'];
        if (tenantName.isNotEmpty) {
          barMessage = '$barMessage\n-> $tenantName ($tenantLabel)';
        }
      }

      Color barColor = Colors.grey.shade700;
      if (isCurrentMeterGroup) {
        // this is the current meter group, use selfColor
        barColor = Colors.blue; // selfColor;
        if (_percentAssignedToThisGroupNew != null) {
          barColor = commitColor;
        }
      }

      Widget barWidget = Tooltip(
        message: barMessage,
        child: Container(
          width: barWidth,
          color: barColor,
        ),
      );
      assignmentBarWidgetList.add(barWidget);
      // }

      // when
      // 1. this mg is not assigned to any tenant, and
      // 2. there is a percentage assigned to this mg, and
      // 3. there is an assignment error (total percentage > 100%)
      // allow op (to remove this meter from this mg) when
      if (!_currentMeterGroupAssignedToTenant &&
          _percentAssignedToThisGroup != null &&
          _hasAssignmentError) {
        _disableOp = false;
        _disabledMessage =
            'please remove this meter from this meter group to fix the assignment error';
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _loadAssignmentBar();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _assignmentErrorMsg,
      waitDuration: const Duration(milliseconds: 500),
      child: SizedBox(
        width: barWidth + opWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 25,
              width: barWidth,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Theme.of(context).hintColor),
              ),
              child: _totalPercentAssignedToThisMeter != null &&
                      _totalPercentAssignedToThisMeter! > 100
                  ? Tooltip(
                      message: _assignmentErrorMsg,
                      waitDuration: const Duration(milliseconds: 500),
                      child: Container(
                        width: barWidth,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : Row(
                      children: [
                        ...assignmentBarWidgetList,
                        const Spacer(),
                      ],
                    ),
            ),
            horizontalSpaceSmall,
            Tooltip(
              message: _disabledMessage,
              waitDuration: const Duration(milliseconds: 500),
              child: SizedBox(
                width: 95,
                height: 30,
                child: WgtTextField(
                  key: _inputRefreshKey,
                  appConfig: widget.appConfig,
                  enabled: !_disableOp,
                  initialValue: _percentAssignedToThisGroupNew
                          ?.toStringAsFixed(3) ??
                      _percentAssignedToThisGroup?.toStringAsFixed(3) ??
                      // _totalPercentAssignedToThisMeter?.toStringAsFixed(3) ??
                      '0.000',
                  decoration: InputDecoration(
                    hintText: 'percentage',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    suffixText: '%',
                    suffixStyle: TextStyle(color: Theme.of(context).hintColor),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
                  ),
                  onChanged: (value) {
                    setState(() {
                      double? newPercentage = double.tryParse(value);
                      if (newPercentage != null && newPercentage > 100.0) {
                        newPercentage = 100.0;
                      }
                      _percentAssignedToThisGroupNew = newPercentage;
                      if (((_percentAssignedToThisGroupNew ?? 0.0) -
                                  (_percentAssignedToThisGroup ?? 0.0))
                              .abs() <
                          0.00001) {
                        _percentAssignedToThisGroupNew = null;
                      }
                      // _inputRefreshKey = UniqueKey();
                      // _loadAssignmentBar();
                      // if (newPercentage != null) {
                      //   widget.onPercentageChanged(newPercentage);
                      // }
                    });
                  },
                  onEditingComplete: () {
                    setState(() {
                      // if (((_percentAssignedToThisGroupNew ?? 0.0) -
                      //             (_percentAssignedToThisGroup ?? 0.0))
                      //         .abs() <
                      //     0.00001) {
                      //   _percentAssignedToThisGroupNew = null;
                      // }
                      _loadAssignmentBar();
                      _inputRefreshKey = UniqueKey();
                      FocusScope.of(context).unfocus();
                      if (_percentAssignedToThisGroupNew != null) {
                        widget.onPercentageChanged(
                            _percentAssignedToThisGroupNew ?? 0.0,
                            _assignmentErrorMsg);
                      }
                    });
                  },
                ),
              ),
            ),
            horizontalSpaceSmall,
            Tooltip(
              message: _percentAssignedToThisGroupNew == null
                  ? ''
                  : 'Reset to previous value',
              waitDuration: const Duration(milliseconds: 500),
              child: InkWell(
                // reset
                onTap: _percentAssignedToThisGroupNew == null
                    ? null
                    : () {
                        setState(() {
                          _percentAssignedToThisGroupNew = null;
                          _loadAssignmentBar();
                          widget.onPercentageChanged(
                              _percentAssignedToThisGroup ?? 0.0,
                              _assignmentErrorMsg);
                        });
                      },
                child: Icon(
                  Icons.refresh,
                  size: 20,
                  color: _percentAssignedToThisGroupNew == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../xt_ui/style/evs2_colors.dart';
import '../../../../xt_ui/wdgt/input/wgt_text_field2.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../def_helper/dh_ems_meter_allocation.dart';
import '../../../model/mdl_pag_app_config.dart';

class WgtMeterAssignmentOp extends StatefulWidget {
  final MdlPagAppConfig appConfig;
  final String strMeterGroupId;
  final Map<String, dynamic> meterInfo;
  final void Function(double, String) onPercentageChanged;
  final bool readOnly;
  final Map<String, dynamic>? currentTenantInfo;

  const WgtMeterAssignmentOp({
    super.key,
    required this.appConfig,
    required this.strMeterGroupId,
    required this.meterInfo,
    required this.onPercentageChanged,
    this.readOnly = false,
    this.currentTenantInfo,
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
    _disableOp = false;
    _hasAssignmentError = false;
    _assignmentErrorMsg = '';
    _disabledMessage = '';

    final assignments = List<Map<String, dynamic>>.from(
      widget.meterInfo['assignment'] ?? [],
    );
    final current = assignments
        .where(
          (assignment) =>
              assignment['meter_group_id']?.toString() ==
              widget.strMeterGroupId,
        )
        .firstOrNull;
    _percentAssignedToThisGroup ??=
        meterAllocationPercentage(current?['percentage']) ?? 0;
    final currentTenant = widget.currentTenantInfo ?? current?['tenant_info'];
    _currentMeterGroupAssignedToTenant = meterAllocationHasActiveTenant(
      currentTenant,
    );

    // Build a preview without changing the fetched allocations.
    final preview = assignments
        .map((assignment) => Map<String, dynamic>.from(assignment))
        .toList();
    if (current == null) {
      preview.add({
        'meter_group_id': widget.strMeterGroupId,
        'meter_group_name': 'Current Meter Group',
        'percentage': '0',
        'tenant_info': currentTenant,
      });
    }
    for (final assignment in preview) {
      final isCurrent =
          assignment['meter_group_id']?.toString() == widget.strMeterGroupId;
      if (isCurrent) {
        assignment['percentage'] =
            _percentAssignedToThisGroupNew ?? _percentAssignedToThisGroup;
        assignment['tenant_info'] = currentTenant;
      }
      final percentage = meterAllocationPercentage(assignment['percentage']);
      if (percentage == null ||
          !meterAllocationHasActiveTenant(assignment['tenant_info'])) {
        continue;
      }
      _totalPercentAssignedToThisMeter =
          _totalPercentAssignedToThisMeter! + percentage;
      final tenant = assignment['tenant_info'];
      assignmentBarWidgetList.add(
        Tooltip(
          message:
              '$percentage% -> ${assignment['meter_group_name'] ?? ''}\n'
              '-> ${tenant['name'] ?? ''} (${tenant['label'] ?? ''})',
          child: Container(
            width: percentage.clamp(0, 100) / 100 * (barWidth - 2),
            color: isCurrent
                ? _percentAssignedToThisGroupNew == null
                      ? Colors.blue
                      : commitColor
                : Colors.grey.shade700,
          ),
        ),
      );
    }

    _hasAssignmentError = _totalPercentAssignedToThisMeter! > 100.000001;
    // Existing over-allocation must remain editable so it can be reduced.
    // An inactive group can be edited even when active allocations use 100%.
    if (_currentMeterGroupAssignedToTenant &&
        _percentAssignedToThisGroupNew == null &&
        _percentAssignedToThisGroup! == 0 &&
        _totalPercentAssignedToThisMeter! >= 99.999999) {
      _disableOp = true;
      _disabledMessage = 'This meter is fully allocated to active tenants';
    }
    if (_hasAssignmentError &&
        _currentMeterGroupAssignedToTenant &&
        _percentAssignedToThisGroupNew != null &&
        _percentAssignedToThisGroupNew! > _percentAssignedToThisGroup!) {
      _assignmentErrorMsg =
          'Total percentage assigned to active tenants exceeds 100%';
    }
    if (widget.readOnly) {
      _disableOp = true;
      _disabledMessage = 'Meter group assignments are read-only';
    }
  }

  @override
  void initState() {
    super.initState();

    _percentAssignedToThisGroupNew = meterAllocationPercentage(
      widget
          .meterInfo['updated_meter_assignment_to_this_meter_group']?['percentage'],
    );
    _loadAssignmentBar();
    if (_percentAssignedToThisGroupNew == _percentAssignedToThisGroup) {
      _percentAssignedToThisGroupNew = null;
    }
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
              child:
                  _totalPercentAssignedToThisMeter != null &&
                      _totalPercentAssignedToThisMeter! > 100.000001
                  ? Tooltip(
                      message:
                          'Total percentage assigned to active tenants exceeds 100%',
                      waitDuration: const Duration(milliseconds: 500),
                      child: Container(
                        width: barWidth,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : Row(children: [...assignmentBarWidgetList, const Spacer()]),
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
                  initialValue:
                      _percentAssignedToThisGroupNew?.toStringAsFixed(3) ??
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: 3,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      double? newPercentage = meterAllocationPercentage(value);
                      if (newPercentage != null && newPercentage > 100.0) {
                        newPercentage = 100.0;
                      }
                      if (newPercentage != null && newPercentage < 0) {
                        newPercentage = 0;
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
                      widget.onPercentageChanged(
                        _percentAssignedToThisGroupNew ??
                            _percentAssignedToThisGroup ??
                            0,
                        _assignmentErrorMsg,
                      );
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
                          _inputRefreshKey = UniqueKey();
                          _loadAssignmentBar();
                          widget.onPercentageChanged(
                            _percentAssignedToThisGroup ?? 0.0,
                            _assignmentErrorMsg,
                          );
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

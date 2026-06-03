import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_bci_assignment.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_meter_group_assignment.dart';
import 'package:flutter/material.dart';

import '../../../../xt_ui/style/evs2_colors.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/scope/mdl_pag_scope.dart';

class WgtTenantItemAssignment extends StatefulWidget {
  const WgtTenantItemAssignment({
    super.key,
    required this.appConfig,
    required this.strItemGroupIndex,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    this.onScopeTreeUpdate,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String strItemGroupIndex;
  final String itemName;
  final String itemLabel;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtTenantItemAssignment> createState() =>
      _WgtTenantItemAssignmentState();
}

class _WgtTenantItemAssignmentState extends State<WgtTenantItemAssignment> {
  final List<String> tenantItemList = ['Meter Group', 'Billing Cost Item'];

  String? _selectedTenantItem;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // select item
            getTenantItemButtons(),
            verticalSpaceSmall,
            getAssignmentItemView(),
          ],
        ));
  }

  Widget getTenantItemButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: tenantItemList.map((tenantItem) {
        bool isSelected = tenantItem == _selectedTenantItem;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTenantItem = tenantItem;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? commitColor.withAlpha(210)
                    : Theme.of(context).primaryColor.withAlpha(210),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                tenantItem,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget getAssignmentItemView() {
    if (_selectedTenantItem == null) {
      return Container();
    }
    switch (_selectedTenantItem) {
      case 'Meter Group':
        return WgtTenantMeterGroupAssignment(
          appConfig: widget.appConfig,
          strItemGroupIndex: widget.strItemGroupIndex,
          itemName: widget.itemName,
          itemLabel: widget.itemLabel,
          itemScope: widget.itemScope,
          onScopeTreeUpdate: widget.onScopeTreeUpdate,
          onUpdate: widget.onUpdate,
        );
      case 'Billing Cost Item':
        return WgtTenantBciAssignment(
          appConfig: widget.appConfig,
          strItemGroupIndex: widget.strItemGroupIndex,
          itemName: widget.itemName,
          itemLabel: widget.itemLabel,
          itemScope: widget.itemScope,
          onScopeTreeUpdate: widget.onScopeTreeUpdate,
          onUpdate: widget.onUpdate,
        );
      default:
        return Container();
    }
  }
}

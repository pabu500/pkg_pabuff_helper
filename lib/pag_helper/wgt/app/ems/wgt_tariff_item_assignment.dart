import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_tenant_bci_assignment.dart';
import 'package:flutter/material.dart';

import '../../../../xt_ui/style/evs2_colors.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';
import '../../../model/scope/mdl_pag_scope.dart';
import 'wgt_tariff_package_assignment.dart';

class WgtTariffItemAssignment extends StatefulWidget {
  const WgtTariffItemAssignment({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.itemInfo,
    required this.strItemGroupIndex,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    this.onScopeTreeUpdate,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> itemInfo;
  final String strItemGroupIndex;
  final String itemName;
  final String itemLabel;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtTariffItemAssignment> createState() =>
      _WgtTariffItemAssignmentState();
}

class _WgtTariffItemAssignmentState extends State<WgtTariffItemAssignment> {
  final List<String> tariffItemList = ['Meter Group', 'Billing Cost Item'];

  String? _selectedTariffItem;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // select item
            getTariffItemButtons(),
            verticalSpaceSmall,
            getAssignmentItemView(),
          ],
        ));
  }

  Widget getTariffItemButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: tariffItemList.map((tariffItem) {
        bool isSelected = tariffItem == _selectedTariffItem;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTariffItem = tariffItem;
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
                tariffItem,
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
    if (_selectedTariffItem == null) {
      return Container();
    }
    switch (_selectedTariffItem) {
      case 'Tariff Package':
        return WgtTariffPackageAssignment(
          appConfig: widget.appConfig,
          loggedInUser: widget.loggedInUser,
          itemGroupIndexStr: widget.strItemGroupIndex,
          meterType: '',
          itemInfo: widget.itemInfo,
          itemName: widget.itemName,
          itemLabel: widget.itemLabel,
          itemScope: widget.itemScope,
          onScopeTreeUpdate: widget.onScopeTreeUpdate,
          onUpdate: widget.onUpdate,
        );
      case 'Billing Cost Item':
        return WgtTenantBciAssignment(
          appConfig: widget.appConfig,
          loggedInUser: widget.loggedInUser,
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

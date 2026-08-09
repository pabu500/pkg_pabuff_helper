import 'package:buff_helper/pag_helper/def_helper/dh_pag_tariff.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_type_selector.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../model/mdl_pag_app_config.dart';
import 'wgt_create_billing_cost_item.dart';
import 'wgt_create_tariff_package.dart';

class WgtCreateTariffItem extends StatefulWidget {
  const WgtCreateTariffItem({
    super.key,
    required this.appConfig,
    this.itemTypeEnum,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final PagTariff? itemTypeEnum;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final Function? onCreated;

  @override
  State<WgtCreateTariffItem> createState() => _CreateTariffItemState();
}

class _CreateTariffItemState extends State<WgtCreateTariffItem> {
  dynamic _selectedItemType;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceTiny,
          WgtItemTypeSelector(
            pagAppContext: appCtxAm,
            appConfig: widget.appConfig,
            itemKind: PagItemKind.tariff,
            prefKey: 'create_tariff_item_type',
            enabledItemTypeList: widget.itemTypeEnum?.value != null
                ? [widget.itemTypeEnum!.value]
                : [
                    PagTariff.tariffPackage.value,
                    // PagTariff.tariffPackageType,
                    // PagTariff.tariffRate,
                    PagTariff.billingCostItem.value,
                  ],
            onItemTypeSelected: (itemType) {
              setState(() {
                _selectedItemType = itemType;
              });
            },
          ),
          verticalSpaceSmall,
          getCreateTariffForm(itemType: _selectedItemType),
          verticalSpaceMedium,
        ],
      ),
    );
  }

  Widget getCreateTariffForm({required dynamic itemType}) {
    if (itemType == null) {
      return const SizedBox.shrink();
    }
    if (itemType is! PagTariff) {
      return const SizedBox.shrink();
    }
    if (itemType == PagTariff.tariffPackage) {
      return WgtCreateTariffPackage(
        appConfig: widget.appConfig,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagTariff.billingCostItem) {
      return WgtCreateBillingCostItem(
        appConfig: widget.appConfig,
        onCreated: widget.onCreated,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

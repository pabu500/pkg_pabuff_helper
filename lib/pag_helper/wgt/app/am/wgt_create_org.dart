import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_type_selector.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/wgt/app/am/wgt_create_amgr.dart';

import '../../../model/mdl_pag_app_config.dart';
import 'wgt_create_bank.dart';

class WgtCreateOrg extends StatefulWidget {
  const WgtCreateOrg({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.itemTypeEnum,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final PagOrgType? itemTypeEnum;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final Function? onCreated;

  @override
  State<WgtCreateOrg> createState() => _CreateOrgState();
}

class _CreateOrgState extends State<WgtCreateOrg> {
  // late MdlPagUser? _loggedInUser;

  dynamic _selectedItemType;

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;
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
            itemKind: PagItemKind.org,
            enabledItemTypeList: widget.itemTypeEnum != null
                ? [widget.itemTypeEnum!.value]
                : [
                    PagOrgType.amgr.value,
                    PagOrgType.landlord.value,
                    PagOrgType.bank.value,
                  ],
            prefKey: 'create_org_item_type',
            onItemTypeSelected: (itemType) {
              setState(() {
                _selectedItemType = itemType;
              });
            },
          ),
          verticalSpaceSmall,
          getCreateOrgForm(itemType: _selectedItemType),
        ],
      ),
    );
  }

  Widget getCreateOrgForm({required dynamic itemType}) {
    if (itemType == null) {
      return const SizedBox.shrink();
    }
    if (itemType is! PagOrgType) {
      return const SizedBox.shrink();
    }
    if (itemType == PagOrgType.amgr) {
      return WgtCreateAmgr(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagOrgType.landlord) {
      // return const WgtCreateLandlord();
      return const SizedBox.shrink();
    } else if (itemType == PagOrgType.bank) {
      return WgtCreateBank(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

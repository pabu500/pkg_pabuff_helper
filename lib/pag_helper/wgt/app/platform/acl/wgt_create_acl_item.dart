import 'package:buff_helper/pag_helper/def_helper/dh_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_type_selector.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../../model/mdl_pag_app_config.dart';
import 'wgt_create_permission.dart';
import 'wgt_create_policy.dart';
import 'wgt_create_resource.dart';

class WgtCreateAclItem extends StatefulWidget {
  const WgtCreateAclItem({
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
  final PagAclType? itemTypeEnum;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final Function? onCreated;

  @override
  State<WgtCreateAclItem> createState() => _CreateAclItemState();
}

class _CreateAclItemState extends State<WgtCreateAclItem> {
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
            itemKind: PagItemKind.acl,
            prefKey: 'create_acl_item_type',
            enabledItemTypeList: widget.itemTypeEnum?.value != null
                ? [widget.itemTypeEnum!.value]
                : [
                    PagAclType.resource.value,
                    PagAclType.permission.value,
                    PagAclType.policy.value,
                  ],
            onItemTypeSelected: (itemType) {
              setState(() {
                _selectedItemType = itemType;
              });
            },
          ),
          verticalSpaceSmall,
          getCreateAclForm(itemType: _selectedItemType),
          verticalSpaceMedium,
        ],
      ),
    );
  }

  Widget getCreateAclForm({required dynamic itemType}) {
    if (itemType == null) {
      return const SizedBox.shrink();
    }
    if (itemType is! PagAclType) {
      return const SizedBox.shrink();
    }
    if (itemType == PagAclType.resource) {
      return WgtCreateResource(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagAclType.permission) {
      return WgtCreatePermission(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else if (itemType == PagAclType.policy) {
      return WgtCreatePolicy(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        onCreated: widget.onCreated,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

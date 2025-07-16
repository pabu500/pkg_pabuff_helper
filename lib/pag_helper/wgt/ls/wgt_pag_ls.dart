import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter/material.dart';
import '../../model/mdl_pag_app_config.dart';
import 'wgt_ls_kind.dart';
import 'wgt_ls_item_flexi.dart';

class WgtPagLs extends StatefulWidget {
  const WgtPagLs({
    super.key,
    required this.appConfig,
    required this.pagAppContext,
    required this.itemKind,
    required this.listContextType,
    this.additionalColumnConfig,
    this.onScopeTreeUpdate,
    this.getPaneWidget,
    this.validateTreeChildren,
    this.selectedItemInfoList,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext pagAppContext;
  final PagItemKind itemKind;
  final PagListContextType listContextType;
  final List<Map<String, dynamic>>? additionalColumnConfig;
  final Function? onScopeTreeUpdate;
  final Widget Function(
          Map<String, dynamic> item, List<Map<String, dynamic>> fullList)?
      getPaneWidget;
  final Function? validateTreeChildren;
  final List<Map<String, dynamic>>? selectedItemInfoList;

  @override
  State<WgtPagLs> createState() => _WgtPagLsState();
}

class _WgtPagLsState extends State<WgtPagLs> {
  late final prefKey = widget.pagAppContext.route;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.itemKind) {
      case PagItemKind.device || PagItemKind.scope || PagItemKind.finance:
        return WgtListSearchKind(
          appConfig: widget.appConfig,
          itemKind: widget.itemKind,
          pagAppContext: widget.pagAppContext,
          prefKey: prefKey,
          selectedItemInfoList: widget.selectedItemInfoList,
          additionalColumnConfig: widget.additionalColumnConfig,
          listContextType: widget.listContextType,
          onScopeTreeUpdate: widget.onScopeTreeUpdate,
        );
      case PagItemKind.user ||
            PagItemKind.tenant ||
            PagItemKind.jobType ||
            PagItemKind.meterGroup ||
            PagItemKind.tariffPackage ||
            PagItemKind.bill ||
            PagItemKind.role:
        // || PagItemKind.finance:
        dynamic itemType;
        if (widget.itemKind == PagItemKind.bill) {
          itemType = PagItemKind.bill;
        }
        // if (widget.itemKind == PagItemKind.finance) {
        //   itemType = PagFinanceType.soa;
        // }

        if (widget.itemKind == PagItemKind.tenant) {
          itemType = PagItemKind.tenant;
        }
        return WgtListSearchItemFlexi(
          appConfig: widget.appConfig,
          pagAppContext: widget.pagAppContext,
          itemKind: widget.itemKind,
          itemType: itemType,
          listContextType: widget.listContextType,
          // use bottom sheet instead of pane mode switcher
          enablePaneModeSwitcher: false,
          prefKey: prefKey,
          additionalColumnConfig: widget.additionalColumnConfig,
          getPaneWidget: widget.getPaneWidget,
          validateTreeChildren: widget.validateTreeChildren,
        );
      default:
        return Container();
    }
  }
}

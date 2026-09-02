import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_ls_kind2.dart';
import 'package:flutter/material.dart';
import '../../../up_helper/enum/enum_acl.dart';
import '../../../xt_ui/wdgt/info/get_error_text_prompt.dart';
import '../../def_helper/def_page_route.dart';
import '../../def_helper/dh_pag_acl.dart';
import '../../model/mdl_pag_app_config.dart';
import '../../model/mdl_pag_user.dart';
import 'wgt_ls_item_flexi.dart';

class WgtPagLs extends StatefulWidget {
  const WgtPagLs({
    super.key,
    required this.appConfig,
    required this.pagAppContext,
    required this.pageRoute,
    required this.loggedInUser,
    required this.itemKind,
    required this.listContextType,
    required this.pageSection,
    this.additionalColumnConfig,
    this.onScopeTreeUpdate,
    this.getPaneWidget,
    this.validateTreeChildren,
    this.selectedItemInfoList,
    this.isSingleItemMode = false,
    this.isCompactFinder = false,
    this.hint,
    this.enabledItemTypeList = const [],
    this.initialFilterMap = const {},
    this.initialNoR,
    this.showFinder = true,
    this.loadOnInit = false,
    this.sortBy,
    this.sortOrder,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext pagAppContext;
  final PagPageRoute pageRoute;
  final String pageSection;
  final MdlPagUser? loggedInUser;
  final PagItemKind itemKind;
  final PagListContextType listContextType;
  final List<Map<String, dynamic>>? additionalColumnConfig;
  final Function? onScopeTreeUpdate;
  final Widget Function(
          Map<String, dynamic> item, List<Map<String, dynamic>> fullList)?
      getPaneWidget;
  final Function? validateTreeChildren;
  final List<Map<String, dynamic>>? selectedItemInfoList;
  final bool isSingleItemMode;
  final bool isCompactFinder;
  final String? hint;
  final List<dynamic> enabledItemTypeList;
  final Map<String, dynamic> initialFilterMap;
  final int? initialNoR;
  final bool showFinder;
  final bool loadOnInit;
  final String? sortBy;
  final String? sortOrder;

  @override
  State<WgtPagLs> createState() => _WgtPagLsState();
}

class _WgtPagLsState extends State<WgtPagLs> {
  late final prefKey = widget.pagAppContext.route;

  String _pageAclMessage = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final aclResult = await checkAcl(
        widget.appConfig,
        widget.pagAppContext,
        widget.loggedInUser!,
        widget.pageRoute,
        widget.pageSection,
        AclOperation.read,
      );
      // if (!mounted || aclResult == null) return;
      if ('error' == aclResult['result']) {
        setState(() {
          _pageAclMessage = 'Error checking Page Access';
        });
        return;
      }

      setState(() {
        _pageAclMessage = aclResult['result'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pageAclMessage != 'granted') {
      return Container(
          alignment: Alignment.topCenter,
          child:
              getErrorTextPrompt(context: context, errorText: _pageAclMessage));
    }

    switch (widget.itemKind) {
      case PagItemKind.device ||
            PagItemKind.scope ||
            PagItemKind.finance ||
            PagItemKind.tariff ||
            PagItemKind.org ||
            PagItemKind.acl:
        if (widget.listContextType == PagListContextType.paymentMatching) {
          return WgtListSearchItemFlexi(
            appConfig: widget.appConfig,
            pagAppContext: widget.pagAppContext,
            itemKind: widget.itemKind,
            itemTypeEnum: PagFinanceType.payment,
            listContextType: widget.listContextType,
            prefKey: prefKey,
            itemTypeListStr: PagFinanceType.payment.name,
            additionalColumnConfig: widget.additionalColumnConfig,
            getPaneWidget: widget.getPaneWidget,
            validateTreeChildren: widget.validateTreeChildren,
            selectedItemInfoList: widget.selectedItemInfoList,
            hint: widget.hint,
          );
        }
        return WgtListSearchKind2(
          appConfig: widget.appConfig,
          itemKind: widget.itemKind,
          pagAppContext: widget.pagAppContext,
          isCompactFinder: widget.isCompactFinder,
          prefKey: prefKey,
          selectedItemInfoList: widget.selectedItemInfoList,
          additionalColumnConfig: widget.additionalColumnConfig,
          listContextType: widget.listContextType,
          onScopeTreeUpdate: widget.onScopeTreeUpdate,
          enabledItemTypeList: widget.enabledItemTypeList,
        );
      case PagItemKind.user ||
            PagItemKind.tenant ||
            PagItemKind.jobType ||
            PagItemKind.meterGroup ||
            // PagItemKind.tariffPackage ||
            // PagItemKind.tariffPackageType ||
            PagItemKind.bill ||
            PagItemKind.role ||
            PagItemKind.resourceType:
        dynamic itemType;
        if (widget.itemKind == PagItemKind.bill) {
          itemType = PagItemKind.bill;
        }
        if (widget.itemKind == PagItemKind.role) {
          itemType = PagItemKind.role;
        }

        if (widget.itemKind == PagItemKind.tenant) {
          itemType = PagItemKind.tenant;
        }
        return WgtListSearchItemFlexi(
          appConfig: widget.appConfig,
          pagAppContext: widget.pagAppContext,
          itemKind: widget.itemKind,
          itemTypeEnum: itemType,
          isCompactFinder: widget.isCompactFinder,
          listContextType: widget.listContextType,
          // use bottom sheet instead of pane mode switcher
          enablePaneModeSwitcher: false,
          prefKey: prefKey,
          additionalColumnConfig: widget.additionalColumnConfig,
          getPaneWidget: widget.getPaneWidget,
          validateTreeChildren: widget.validateTreeChildren,
          isSingleItemMode: widget.isSingleItemMode,
          hint: widget.hint,
          initialFilterMap: widget.initialFilterMap,
          initialNoR: widget.initialNoR,
          showFinder: widget.showFinder,
          loadOnInit: widget.loadOnInit,
          sortBy: widget.sortBy,
          sortOrder: widget.sortOrder,
        );
      default:
        return Container();
    }
  }
}

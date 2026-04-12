import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/mdl_history.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_bill.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/usage/pag_usage_stat_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../pag_helper/comm/comm_batch_op.dart';
import '../../../pag_helper/model/acl/mdl_pag_svc_claim.dart';
import '../../../pag_helper/model/mdl_pag_app_config.dart';
import '../../../pag_helper/wgt/app/ems/wgt_line_item.dart';
import '../usage/usage_stat_helper.dart';
import '../../../pag_helper/wgt/app/ems/wgt_pag_group_stat_core.dart';
import '../usage/wgt_pag_meter_stat_core.dart';
import 'mdl_ems_type_usage.dart';

class WgtPagTenantCompositeUsageSummary extends StatefulWidget {
  const WgtPagTenantCompositeUsageSummary({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.isMonthly,
    required this.tenantLcs,
    required this.fromDatetime,
    required this.toDatetime,
    required this.effectiveToDatetime,
    required this.tenantName,
    required this.tenantType,
    // required this.excludeAutoUsage,
    required this.displayContextStr,
    required this.cycleStr,
    required this.billDate,
    this.itemType,
    this.isDisabled = false,
    // this.usageCalc,
    this.showFactoredUsage = true,
    // required this.usageFactor,
    // this.typeRates,
    this.renderMode = 'wgt', // wgt, pdf
    this.showRenderModeSwitch = false,
    this.tenantLabel,
    this.tenantAccountId = '',
    // for rendering, not calculation
    this.tenantSingularUsageInfoList = const [],
    this.compositeUsageCalc,
    this.strCollectionStartDateTimestamp = '',
    this.strCollectionEndDateTimestamp = '',
    this.subTenantListUsageSummary = const [],
    // this.manualUsages = const [],
    this.isBillMode = false,
    this.billInfo = const {},
    // this.meterTypeRates = const {},
    // this.gst,
    this.lineItems = const [],
    // this.billedAutoUsages = const {},
    this.usageDecimals = 3,
    this.rateDecimals = 4,
    this.costDecimals = 3,
    this.onUpdate,
    this.interestInfo = const {},
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final bool isDisabled;
  final String displayContextStr;
  // final PagEmsTypeUsageCalc? usageCalc;
  final bool showFactoredUsage;
  final dynamic itemType;
  final bool isMonthly;
  final String? tenantLcs;
  final DateTime fromDatetime;
  final DateTime toDatetime;
  final DateTime? effectiveToDatetime;
  final String tenantName;
  final String? tenantLabel;
  final String tenantAccountId;
  final String tenantType;
  final String cycleStr;
  final String billDate;
  // final bool excludeAutoUsage;
  final List<Map<String, dynamic>> tenantSingularUsageInfoList;
  final PagEmsTypeUsageCalc? compositeUsageCalc;
  final String strCollectionStartDateTimestamp;
  final String strCollectionEndDateTimestamp;
  final List<Map<String, dynamic>> subTenantListUsageSummary;
  final bool isBillMode;
  final Map<String, dynamic> billInfo;
  final List<Map<String, dynamic>> lineItems;
  final String renderMode;
  final bool showRenderModeSwitch;
  // final Map<String, dynamic> billedAutoUsages;
  final int usageDecimals;
  final int rateDecimals;
  final int costDecimals;
  // final Map<String, dynamic> usageFactor;
  // final Map<String, dynamic>? typeRates;
  final Map<String, dynamic> interestInfo;
  final Function? onUpdate;

  @override
  State<WgtPagTenantCompositeUsageSummary> createState() =>
      _WgtPagTenantCompositeUsageSummaryState();
}

class _WgtPagTenantCompositeUsageSummaryState
    extends State<WgtPagTenantCompositeUsageSummary> {
  final double statWidth = 850;
  late final String strBillingRecId;

  final List<String> _meterTypes = ['E', 'W', 'B', 'N', 'G'];

  // final Map<String, dynamic> _typeRates = {};

  final List<Map<String, dynamic>> _manualUsageList = [];
  final List<Map<String, dynamic>> _lineItemList = [];

  // late final EmsTypeUsageCalc _emsTypeUsageCalc;

  String _renderMode = 'wgt'; // wgt, pdf

  UniqueKey? _lcStatusOpsKey;

  late final _billInfo = Map<String, dynamic>.from(widget.billInfo);

  // bool _isDisabled = false;
  bool _showInterestDetail = false;

  String _line1Label = '';
  String _currentField = '';
  bool _fieldUpdated = false;
  String _errorText = '';

  Future<List<Map<String, dynamic>>> _updateProfile(String key, String value,
      {String? oldVal, String? scopeProfileIdColName}) async {
    try {
      Map<String, dynamic> opItem = {
        'id': strBillingRecId,
        key: value,
        'checked': true,
      };
      if (scopeProfileIdColName != null) {
        opItem['scope_profile_id_column_name'] = scopeProfileIdColName;
      }

      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'id': strBillingRecId,
        'item_kind': PagItemKind.bill.name,
        // 'item_type': widget.itemType is Enum
        //     ? (widget.itemType as Enum).name
        //     : widget.itemType,
        'item_id_type': ItemIdType.id.name,
        'item_id_key': 'id',
        'item_id': strBillingRecId,
        // 'key1, key2, key3, ...'
        'update_key_str': key,
        'op_name': 'multi_key_val_update',
        'op_list': [opItem],
      };

      List<Map<String, dynamic>> result = await doPagOpMultiKeyValUpdate(
        widget.appConfig,
        widget.loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser!.username,
          userId: widget.loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      return result;
    } catch (e) {
      dev.log(e.toString());

      //return a Map
      Map<String, dynamic> result = {};
      result['error'] = explainException(e, defaultMsg: 'Error updating field');

      //result is a List
      return [result];
    }
  }

  String? lineItemLabelValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Label cannot be empty';
    }
    if (value.length > 50) {
      return 'Label cannot exceed 50 characters';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _renderMode = widget.renderMode;

    strBillingRecId = widget.billInfo['billing_rec_id'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.usageCalc == null) {
    //   return getErrorTextPrompt(
    //       context: context, errorText: 'Usage calc not available');
    // }
    String lcStatus = _billInfo['lc_status'] ?? '';
    PagBillingLcStatus currentStatus = PagBillingLcStatus.byValue(lcStatus);

    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).hintColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isBillMode) getBillTitleRow(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // getUsageTitle(),
                  // getUsageTypeStat(),
                  getPagUsageTitle(
                    context,
                    widget.fromDatetime,
                    widget.toDatetime,
                    widget.effectiveToDatetime,
                    widget.isMonthly,
                    widget.tenantLabel,
                    widget.tenantName,
                    widget.tenantAccountId,
                    widget.isBillMode,
                    widget.cycleStr,
                    widget.billDate,
                    widget.billInfo['billed_due_date_timestamp'] ?? '',
                  ),
                  getPagUsageTypeTopStat(
                    costDecimals: widget.costDecimals,
                    context,
                    widget.isBillMode,
                    widget.compositeUsageCalc!.typeUsageE!.usage,
                    widget.compositeUsageCalc!.typeUsageE!.cost,
                    widget.compositeUsageCalc!.typeUsageW!.usage,
                    widget.compositeUsageCalc!.typeUsageW!.cost,
                    widget.compositeUsageCalc!.typeUsageB!.usage,
                    widget.compositeUsageCalc!.typeUsageB!.cost,
                    widget.compositeUsageCalc!.typeUsageN!.usage,
                    widget.compositeUsageCalc!.typeUsageN!.cost,
                    widget.compositeUsageCalc!.typeUsageG!.usage,
                    widget.compositeUsageCalc!.typeUsageG!.cost,
                    displayContextStr: widget.displayContextStr,
                  ),
                ],
              ),
              Divider(color: Theme.of(context).hintColor),
              // if (!widget.excludeAutoUsage)
              // ...getStat(),
              // if (widget.excludeAutoUsage) getAutoUsageExcludedInfo(context),
              getSingluarStat(),
              verticalSpaceSmall,
              // getManualUsage(),
              // verticalSpaceSmall,
              // getSubTenantUsageList(),
              // verticalSpaceSmall,
              // verticalSpaceSmall,
              // getLineItemSubjectToTax(),
              verticalSpaceSmall,
              if (widget.isBillMode)
                getPagTotal(
                  context,
                  widget.loggedInUser,
                  widget.appConfig,
                  strBillingRecId,
                  'generated',
                  widget.compositeUsageCalc!.totalUsageCost,
                  widget.compositeUsageCalc!.gst!,
                  widget.compositeUsageCalc!.subTotalCost,
                  widget.compositeUsageCalc!.gstAmount,
                  widget.compositeUsageCalc!.totalCost,
                  widget.compositeUsageCalc!.principalAmount,
                  widget.compositeUsageCalc!.cycleTotalAmount,
                  widget.compositeUsageCalc!.payableAmount,
                  widget.tenantType,
                  widget.lineItems,
                  widget.compositeUsageCalc!.miniSoaInfo,
                  widget.strCollectionStartDateTimestamp,
                  widget.strCollectionEndDateTimestamp,
                  widget.interestInfo,
                  width: statWidth,
                  showInterestDetail: _showInterestDetail,
                  onCheckInterestDetail: () {
                    setState(() {
                      _showInterestDetail = !_showInterestDetail;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getBillTitleRow() {
    if (widget.billInfo.isEmpty) {
      dev.log('Bill info is empty');
      return Container();
    }
    String billLabel = widget.billInfo['bill_label'] ?? '';
    String billLcStatusStr = widget.billInfo['lc_status'] ?? '';
    String billingRecName = widget.billInfo['billing_rec_name'] ?? '';
    PagBillingLcStatus billLcStatus =
        PagBillingLcStatus.values.byName(billLcStatusStr);

    String tenantLcsText = '';
    if (widget.tenantLcs != null) {
      if (widget.tenantLcs == 'final_bill') {
        tenantLcsText = 'FINAL BILL';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getBillLcStatusTagWidget(context, billLcStatus),
          horizontalSpaceSmall,
          Text('Invoice: ',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).hintColor.withAlpha(180),
                fontWeight: FontWeight.bold,
              )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(billLabel,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  )),
              Row(
                children: [
                  SelectableText(billingRecName),
                  SizedBox(
                      width: 40,
                      child: getCopyButton(context, billingRecName,
                          direction: 'left'))
                ],
              ),
            ],
          ),
          horizontalSpaceSmall,
          if (tenantLcsText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.brown,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                tenantLcsText,
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget getSingluarStat() {
    List<Widget> singularStatList = [];
    for (Map<String, dynamic> singularUsageInfo
        in widget.tenantSingularUsageInfoList) {
      List<Widget> typeStatList = [];
      String slotFromTimestampStr = singularUsageInfo['from_timestamp'] ?? '';
      String slotToTimestampStr = singularUsageInfo['to_timestamp'] ?? '';
      if (widget.effectiveToDatetime != null) {
        slotToTimestampStr = widget.effectiveToDatetime!
            .toIso8601String()
            .replaceAll('T', ' ')
            .replaceAll('Z', '');
      }
      String slotStr =
          '  ${slotFromTimestampStr.substring(0, 10)} - ${slotToTimestampStr.substring(0, 10)}';
      typeStatList.add(getTypeStat(singularUsageInfo, 'E'));
      typeStatList.add(getTypeStat(singularUsageInfo, 'B'));
      typeStatList.add(getTypeStat(singularUsageInfo, 'W'));
      typeStatList.add(getTypeStat(singularUsageInfo, 'N'));
      typeStatList.add(getTypeStat(singularUsageInfo, 'G'));
      singularStatList.add(Container(
        width: statWidth,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600, width: 1),
          borderRadius: BorderRadius.circular(5.0),
        ),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            verticalSpaceTiny,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(slotStr,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).hintColor))
              ],
            ),
            verticalSpaceSmall,
            ...typeStatList,
          ],
        ),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // verticalSpaceSmall,
        ...singularStatList,
      ],
    );
  }

  // List<Widget> getStat() {
  //   List<Widget> typeStat = [];
  //   typeStat.add(getTypeStat('E'));
  //   typeStat.add(getTypeStat('B'));
  //   typeStat.add(getTypeStat('W'));
  //   typeStat.add(getTypeStat('N'));
  //   typeStat.add(getTypeStat('G'));
  //   return typeStat;
  // }

  Widget getTypeStat(Map<String, dynamic> singularUsageInfo, String typeStr) {
    List<Widget> slotList = [];
    // for (Map<String, dynamic> singularUsageInfo in widget.tenantSingularUsageInfoList) {
    String slotFromTimestampStr = singularUsageInfo['from_timestamp'] ?? '';
    String slotToTimestampStr = singularUsageInfo['to_timestamp'] ?? '';
    assert(
      slotFromTimestampStr.isNotEmpty && slotToTimestampStr.isNotEmpty,
      'from_timestamp and to_timestamp cannot be empty',
    );
    // String slotStr = '  ${slotFromTimestampStr.substring(0, 10)} - ${slotToTimestampStr.substring(0, 10)}';
    String genType = singularUsageInfo['gen_type'] ?? '';
    String excludeAutoUsageStr = singularUsageInfo['exclude_auto_usage'] ?? '';

    if ('true' == excludeAutoUsageStr) {
      return getManualUsage2(singularUsageInfo, typeStr);
    } else {
      final tenantUsageSummary = singularUsageInfo['tenant_usage_summary'];

      final meterGroupUsageList =
          tenantUsageSummary['meter_group_usage_list'] ?? [];
      final typeGroupInfoList = meterGroupUsageList
          .where((element) => element['meter_type'] == typeStr)
          .toList();
      List<Widget> typeGroupList = [];
      for (var groupInfo in typeGroupInfoList) {
        String meterTypeTag = groupInfo['meter_type'] ?? '';
        MeterType? meterType = getMeterType(meterTypeTag);

        Map<String, dynamic>? meterTypeRateInfo =
            singularUsageInfo['meter_type_rate_info'];
        assert(meterTypeRateInfo != null, 'meterTypeRateInfo cannot be null');
        PagEmsTypeUsageCalc? usageCalc = singularUsageInfo['usage_calc'];
        assert(usageCalc != null, 'usageCalc cannot be null');

        typeGroupList.add(Column(
          children: [
            getGroupMeterStat(
                groupInfo, meterType, meterTypeRateInfo!, usageCalc!)
          ],
        ));
      }
      if (typeGroupList.isEmpty) {
        return Container();
      }
      slotList.add(Column(
        children: [...typeGroupList],
      ));
    }
    // }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [...slotList],
    );
  }

  Widget getGroupMeterStat(Map<String, dynamic> groupInfo, MeterType? meterType,
      Map<String, dynamic> meterTypeRateInfo, PagEmsTypeUsageCalc usageCalc) {
    String groupType = groupInfo['meter_type'] ?? '';
    MeterType? meterType = getMeterType(groupType);
    if (meterType == null) {
      return Container();
    }
    String groupName = groupInfo['meter_group_name'] ?? '';
    String groupLabel = groupInfo['meter_group_label'] ?? '';
    final meterGroupUsageSummary = groupInfo['meter_group_usage_summary'] ?? [];
    final meterUsageList = meterGroupUsageSummary['meter_usage_list'];

    List<Widget> meterList = [];
    List<Map<String, dynamic>> meterStatList = [];

    double? usageFactor = usageCalc.getTypeUsageFactor(groupType);
    for (var meterStat in meterUsageList) {
      final meterUsageSummary = meterStat['meter_usage_summary'];
      String usageStr = meterUsageSummary['usage'] ?? '';
      double? usageVal = double.tryParse(usageStr);
      if (usageVal == null) {
        dev.log('usageVal is null');
      }
      if (usageVal != null && usageFactor != null) {
        usageVal = usageVal * usageFactor;
        meterUsageSummary['usage_factored'] = usageVal;
        meterUsageSummary['factor'] = usageFactor;
      }

      meterStatList.add(meterUsageSummary);
      meterList.add(
        getMeterStat(meterUsageSummary, groupType, meterTypeRateInfo, false),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // verticalSpaceSmall,
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     InkWell(
        //         onTap: () {
        //           setState(() {
        //             groupInfo['showChart'] = !(groupInfo['showChart'] ?? false);
        //           });
        //         },
        //         child: Icon(Symbols.analytics,
        //             size: 21, color: Theme.of(context).colorScheme.primary)),
        //     horizontalSpaceTiny,
        //     Text(groupName,
        //         style: TextStyle(
        //           fontSize: 18,
        //           color: Theme.of(context).hintColor.withAlpha(180),
        //           fontWeight: FontWeight.bold,
        //         )),
        //   ],
        // ),
        // verticalSpaceTiny,
        // Text(groupLabel,
        //     style: TextStyle(
        //       fontSize: 15,
        //       color: Theme.of(context).hintColor.withAlpha(130),
        //       fontWeight: FontWeight.bold,
        //     )),
        if (groupInfo['showChart'] ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: WgtPagMeterGroupStatCore(
              loggedInUser: widget.loggedInUser,
              appConfig: widget.appConfig,
              displayContextStr: widget.displayContextStr,
              statColor: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              itemType: widget.itemType,
              meterType: meterType,
              meterIdType: ItemIdType.name,
              meterIdFieldKey: 'item_name',
              groupId: groupName,
              selectedMeterStat: meterStatList,
              isMonthly: widget.isMonthly,
              startDateTime: widget.fromDatetime,
              endDateTime: widget.toDatetime,
              decimals: 2,
            ),
          ),
        // verticalSpaceTiny,
        ...meterList
      ],
    );
  }

  Widget getMeterStat(Map<String, dynamic> meterUsage, String meterTypeTag,
      Map<String, dynamic> meterTypeRateInfo, bool calcUsageFromReadings) {
    // String meterName = meterStat['item_name'];
    String meterSn = meterUsage['meter_sn'];
    // String altName = meterStat['alt_name'];

    assert(meterTypeRateInfo[meterTypeTag] != null,
        'meterTypeRateInfo for $meterTypeTag cannot be null');
    String typeRateStr = meterTypeRateInfo[meterTypeTag]['result']['rate'];
    double? typeRate = double.tryParse(typeRateStr);

    // return Container();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: WgtPagUsageStatCore(
        loggedInUser: widget.loggedInUser,
        displayContextStr: widget.displayContextStr,
        showFactoredUsage: widget.showFactoredUsage,
        calcUsageFromReadings: calcUsageFromReadings,
        appConfig: widget.appConfig,
        isBillMode: widget.isBillMode,
        rate: typeRate,
        statColor: Theme.of(context).colorScheme.onSurface.withAlpha(210),
        showTrending: false,
        statVirticalStack: false,
        // height: 110,
        usageDecimals: widget.usageDecimals,
        rateDecimals: widget.rateDecimals,
        costDecimals: widget.costDecimals,
        meterType: getMeterType(meterTypeTag)!,
        meterId: meterSn,
        meterIdType: ItemIdType.name,
        itemType: widget.itemType,
        historyType: PagItemHistoryType.meterListUsageSummary,
        meterUsageSummary: meterUsage,
      ),
    );
  }

  Widget getManualUsage2(
      Map<String, dynamic> singularUsageInfo, String targetMeterTypeTag) {
    List<Widget> manualUsageWidgetList = [];
    PagEmsTypeUsageCalc? usageCalc = singularUsageInfo['usage_calc'];
    if (usageCalc == null) {
      return Container();
    }
    final manualUsageList = usageCalc.manualUsageList;

    Map<String, dynamic>? meterTypeRateInfo =
        singularUsageInfo['meter_type_rate_info'];

    for (var item in manualUsageList ?? []) {
      double? usageVal = item['usage'];
      String meterTypeTag = item['meter_type'] ?? '';
      if (meterTypeTag != targetMeterTypeTag) {
        continue;
      }
      assert(meterTypeRateInfo![meterTypeTag] != null,
          'meterTypeRateInfo for $meterTypeTag cannot be null');
      String typeRateStr = meterTypeRateInfo![meterTypeTag]['result']['rate'];
      double? typeRate = double.tryParse(typeRateStr);
      if (usageVal != null) {
        MeterType? meterType = getMeterType(meterTypeTag);
        if (meterType != null) {
          manualUsageWidgetList.add(
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: WgtPagUsageStatCore(
                loggedInUser: widget.loggedInUser,
                appConfig: widget.appConfig,
                displayContextStr: widget.displayContextStr,
                isBillMode: widget.isBillMode,
                rate: typeRate,
                statColor:
                    Theme.of(context).colorScheme.onSurface.withAlpha(180),
                showTrending: false,
                statVirticalStack: false,
                height: 110,
                usageDecimals: widget.usageDecimals,
                rateDecimals: widget.rateDecimals,
                costDecimals: widget.costDecimals,
                meterType: meterType,
                meterId: ' (m.)',
                meterIdType: ItemIdType.name,
                itemType: widget.itemType,
                historyType: PagItemHistoryType.meterListUsageSummary,
                isStaticUsageStat: true,
                meterUsageSummary: {'usage': usageVal},
              ),
            ),
          );
        }
      }
    }

    return SizedBox(
        width: statWidth, child: Column(children: [...manualUsageWidgetList]));
  }

  Widget getManualUsage() {
    List<Widget> manualUsageWidgetList = [];
    for (Map<String, dynamic> singularUsageInfo
        in widget.tenantSingularUsageInfoList) {
      PagEmsTypeUsageCalc? usageCalc = singularUsageInfo['usage_calc'];
      if (usageCalc == null) {
        continue;
      }
      final manualUsageList = usageCalc.manualUsageList;

      Map<String, dynamic>? meterTypeRateInfo =
          singularUsageInfo['meter_type_rate_info'];

      for (var item in manualUsageList ?? []) {
        double? usageVal = item['usage'];
        String meterTypeTag = item['meter_type'] ?? '';
        assert(meterTypeRateInfo![meterTypeTag] != null,
            'meterTypeRateInfo for $meterTypeTag cannot be null');
        String typeRateStr = meterTypeRateInfo![meterTypeTag]['result']['rate'];
        double? typeRate = double.tryParse(typeRateStr);
        if (usageVal != null) {
          MeterType? meterType = getMeterType(meterTypeTag);
          if (meterType != null) {
            manualUsageWidgetList.add(
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: WgtPagUsageStatCore(
                  loggedInUser: widget.loggedInUser,
                  appConfig: widget.appConfig,
                  displayContextStr: widget.displayContextStr,
                  isBillMode: widget.isBillMode,
                  rate: typeRate,
                  statColor:
                      Theme.of(context).colorScheme.onSurface.withAlpha(180),
                  showTrending: false,
                  statVirticalStack: false,
                  height: 110,
                  usageDecimals: widget.usageDecimals,
                  rateDecimals: widget.rateDecimals,
                  costDecimals: widget.costDecimals,
                  meterType: meterType,
                  meterId: ' (m.)',
                  meterIdType: ItemIdType.name,
                  itemType: widget.itemType,
                  historyType: PagItemHistoryType.meterListUsageSummary,
                  isStaticUsageStat: true,
                  meterUsageSummary: {'usage': usageVal},
                ),
              ),
            );
          }
        }
      }
    }
    return SizedBox(
      width: statWidth,
      child: Column(
        children: [
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.edit,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text('Manual Usage',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withAlpha(180),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...manualUsageWidgetList,
        ],
      ),
    );
  }

  Widget getLineItemSubjectToTax() {
    bool isEditableByAcl = true;

    if (widget.lineItems.isEmpty) {
      return Container();
    }
    if (widget.lineItems.first.isEmpty) {
      return Container();
    }
    List<Widget> lineItemList = [];
    for (var lineItem in widget.lineItems) {
      bool subjectToTax = lineItem['subjectToTax'] as bool;
      if (!subjectToTax) {
        continue;
      }
      String label =
          _line1Label.isEmpty ? lineItem['label'] ?? '' : _line1Label;
      String valueStr = lineItem['amount'] ?? '';
      double? valueVal = double.tryParse(valueStr) ?? 0;
      lineItemList.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            horizontalSpaceRegular,
            // SizedBox(
            //   width: 210,
            //   child: Text(
            //     label,
            //     style: TextStyle(
            //       fontSize: 15,
            //       color: Theme.of(context).hintColor.withAlpha(180),
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            // WgtViewEditField(
            //   width: 250,
            //   editable: isEditableByAcl,
            //   showCopy: false,
            //   useDatePicker: false,
            //   showLabel: true,
            //   labelWidth: 0,
            //   hintText: 'line item label',
            //   labelText: '',
            //   originalValue: label,
            //   onFocus: (hasFocus) {
            //     setState(() {
            //       _currentField = 'line_item_label_1';
            //     });
            //   },
            //   hasFocus: _currentField == 'line_item_label_1',
            //   onSetValue: (newValue) async {
            //     List<Map<String, dynamic>> result = await _updateProfile(
            //       'line_item_label_1',
            //       newValue,
            //     );
            //     Map<String, dynamic> resultMap = result[0];
            //     if (resultMap['error'] == null) {
            //       setState(() {
            //         _line1Label = newValue;

            //         _fieldUpdated = true;
            //         widget.onUpdate?.call();
            //       });
            //     } else {
            //       Map<String, dynamic> errorMap = resultMap['error'] is Map?
            //           ? resultMap['error']
            //           : {'status': resultMap['error'].toString()};
            //       String? status = errorMap['status'];
            //       dev.log('Status: $status');
            //       setState(() {
            //         _errorText = 'Error updating field';
            //       });
            //     }

            //     return resultMap;
            //   },
            //   validator: lineItemLabelValidator,
            //   textStyle: null,
            // ),
            WgtBillLineItemLabel(
              loggedInUser: widget.loggedInUser,
              appConfig: widget.appConfig,
              strBillingRecId: strBillingRecId,
              itemKeyName: 'line_item_label_1',
              lineItem: lineItem,
              width: 250,
              isEditableByAcl: false,
            ),
            horizontalSpaceSmall,
            getStatWithUnit(
              getCommaNumberStr(valueVal, decimal: 2),
              'SGD',
              statStrStyle: defStatStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.edit,
                size: 21, color: Theme.of(context).colorScheme.primary),
            horizontalSpaceTiny,
            Text(
              'Line Item',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).hintColor.withAlpha(180),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        verticalSpaceSmall,
        Container(
          width: statWidth,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          constraints: const BoxConstraints(
            maxHeight: 60,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600, width: 1),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...lineItemList,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget getSubTenantUsageList() {
  //   List<Widget> subTenantUsageList = [];
  //   for (var subTenantUsage in widget.usageCalc!.subTenantUsage) {
  //     String tenantName = subTenantUsage['tenant_name'] ?? '';
  //     String tenantLabel = subTenantUsage['tenant_label'] ?? '';
  //     List<EmsTypeUsage> typeUsageList = subTenantUsage['type_usage_list'];

  //     subTenantUsageList.add(
  //       getSubTenantUsage(
  //         tenantName,
  //         tenantLabel,
  //         typeUsageList,
  //       ),
  //     );
  //   }
  //   return Column(
  //     children: [...subTenantUsageList],
  //   );
  // }

  // widget only, no calculation
  Widget getSubTenantUsage(String tenantName, String tenantLabel,
      List<EmsTypeUsage> emsTypeUsageList) {
    Map<String, double> usage = {};
    List<Widget> typeUsageList = [];
    for (EmsTypeUsage typeUsage in emsTypeUsageList) {
      usage['usage'] = typeUsage.usage!;
      usage['usage_factored'] = typeUsage.usageFactored!;
      usage['factor'] = typeUsage.factor!;
      typeUsageList.add(
        getTypeUsageStat(context, typeUsage.typeTag!, usage,
            usageDecimals: widget.usageDecimals,
            rateDecimals: widget.rateDecimals,
            costDecimals: widget.costDecimals,
            isSubTenant: true,
            showFactoredUsage: widget.showFactoredUsage),
      );
    }

    return SizedBox(
      width: statWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.group,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text(tenantLabel,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withAlpha(180),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...typeUsageList,
        ],
      ),
    );
  }
}

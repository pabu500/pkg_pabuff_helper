import 'package:buff_helper/pag_helper/model/mdl_history.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/usage/pag_usage_stat_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../pag_helper/model/mdl_pag_app_config.dart';
import '../usage/usage_stat_helper.dart';
import '../../../pag_helper/wgt/app/ems/wgt_pag_group_stat_core.dart';
import '../usage/wgt_pag_meter_stat_core.dart';
import 'mdl_ems_type_usage.dart';

class WgtPagTenantUsageSummary extends StatefulWidget {
  const WgtPagTenantUsageSummary({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.itemType,
    required this.isMonthly,
    required this.fromDatetime,
    required this.toDatetime,
    required this.tenantName,
    required this.tenantType,
    required this.excludeAutoUsage,
    required this.displayContextStr,
    this.cycleStr = '',
    this.billDate = '',
    this.usageCalc,
    this.showFactoredUsage = true,
    // required this.usageFactor,
    this.typeRates,
    this.renderMode = 'wgt', // wgt, pdf
    this.showRenderModeSwitch = false,
    this.tenantLabel,
    this.tenantAccountId = '',
    // for rendering, not calculation
    this.tenantUsageSummary = const {},
    this.subTenantListUsageSummary = const [],
    this.manualUsages = const [],
    this.isBillMode = false,
    this.billInfo = const {},
    // this.meterTypeRates = const {},
    // this.gst,
    this.lineItems = const [],
    // this.billedAutoUsages = const {},
    this.usageDecimals = 3,
    this.rateDecimals = 4,
    this.costDecimals = 3,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String displayContextStr;
  final PagEmsTypeUsageCalc? usageCalc;
  final bool showFactoredUsage;
  final ItemType itemType;
  final bool isMonthly;
  final DateTime fromDatetime;
  final DateTime toDatetime;
  final String tenantName;
  final String? tenantLabel;
  final String tenantAccountId;
  final String tenantType;
  final String cycleStr;
  final String billDate;
  final bool excludeAutoUsage;
  final Map<String, dynamic> tenantUsageSummary;
  final List<Map<String, dynamic>> subTenantListUsageSummary;
  final bool isBillMode;
  final Map<String, dynamic> billInfo;
  // final Map<String, dynamic> meterTypeRates;
  // final double? gst;
  final List<Map<String, dynamic>> manualUsages;
  final List<Map<String, dynamic>> lineItems;
  final String renderMode;
  final bool showRenderModeSwitch;
  // final Map<String, dynamic> billedAutoUsages;
  final int usageDecimals;
  final int rateDecimals;
  final int costDecimals;
  // final Map<String, dynamic> usageFactor;
  final Map<String, dynamic>? typeRates;

  @override
  State<WgtPagTenantUsageSummary> createState() =>
      _WgtPagTenantUsageSummaryState();
}

class _WgtPagTenantUsageSummaryState extends State<WgtPagTenantUsageSummary> {
  final double statWidth = 800;

  final List<String> _meterTypes = ['E', 'W', 'B', 'N', 'G'];

  // final Map<String, dynamic> _typeRates = {};

  final List<Map<String, dynamic>> _manualUsageList = [];
  final List<Map<String, dynamic>> _lineItemList = [];

  // late final EmsTypeUsageCalc _emsTypeUsageCalc;

  String _renderMode = 'wgt'; // wgt, pdf

  @override
  void initState() {
    super.initState();
    _renderMode = widget.renderMode;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usageCalc == null) {
      return getErrorTextPrompt(
          context: context, errorText: 'Usage calc not available');
    }

    return Padding(
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // getUsageTitle(),
                  // getUsageTypeStat(),
                  if (widget.isBillMode) getBillTitleRow(),
                  getPagUsageTitle(
                    context,
                    widget.fromDatetime,
                    widget.toDatetime,
                    widget.isMonthly,
                    widget.tenantLabel,
                    widget.tenantName,
                    widget.tenantAccountId,
                    widget.cycleStr,
                    widget.billDate,
                  ),
                  getPagUsageTypeTopStat(
                    costDecimals: widget.costDecimals,
                    context,
                    widget.isBillMode,
                    widget.usageCalc!.typeUsageE!.usage,
                    widget.usageCalc!.typeUsageE!.cost,
                    widget.usageCalc!.typeUsageW!.usage,
                    widget.usageCalc!.typeUsageW!.cost,
                    widget.usageCalc!.typeUsageB!.usage,
                    widget.usageCalc!.typeUsageB!.cost,
                    widget.usageCalc!.typeUsageN!.usage,
                    widget.usageCalc!.typeUsageN!.cost,
                    widget.usageCalc!.typeUsageG!.usage,
                    widget.usageCalc!.typeUsageG!.cost,
                    displayContextStr: widget.displayContextStr,
                  ),
                ],
              ),
              Divider(color: Theme.of(context).hintColor),
              if (!widget.excludeAutoUsage) ...getStat(),
              if (widget.excludeAutoUsage) getAutoUsageExcludedInfo(context),
              verticalSpaceSmall,
              getManualUsage(),
              verticalSpaceSmall,
              getSubTenantUsageList(),
              verticalSpaceSmall,
              verticalSpaceSmall,
              getLineItem(),
              verticalSpaceSmall,
              if (widget.isBillMode)
                getTotal2(
                  context,
                  widget.usageCalc!.gst!,
                  widget.usageCalc!.subTotalCost,
                  widget.usageCalc!.gstAmount,
                  widget.usageCalc!.totalCost,
                  widget.tenantType,
                  null,
                  null,
                  {},
                  width: statWidth,
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
    String billLabel = widget.billInfo['label'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(billLabel,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).hintColor.withAlpha(180),
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  List<Widget> getStat() {
    List<Widget> typeStat = [];

    typeStat.add(getTypeStat('E'));
    typeStat.add(getTypeStat('B'));
    typeStat.add(getTypeStat('W'));
    typeStat.add(getTypeStat('N'));
    typeStat.add(getTypeStat('G'));

    return typeStat;
  }

  Widget getTypeStat(String typeStr) {
    List<Widget> typeGroups = [];
    // List<Map<String, dynamic>> typeGroupInfoList = [];
    final meterGroupUsageList =
        widget.tenantUsageSummary['meter_group_usage_list'] ?? [];
    final typeGroupInfoList = meterGroupUsageList
        .where((element) => element['meter_type'] == typeStr)
        .toList();
    for (var groupInfo in typeGroupInfoList) {
      String meterTypeTag = groupInfo['meter_type'] ?? '';
      MeterType? meterType = getMeterType(meterTypeTag);
      typeGroups.add(getGroupMeterStat(groupInfo, meterType));
    }
    return SizedBox(
      width: statWidth,
      child: Column(
        children: [...typeGroups],
      ),
    );
  }

  Widget getGroupMeterStat(
      Map<String, dynamic> groupInfo, MeterType? meterType) {
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

    // double usageFactor = getProjectMeterUsageFactor(widget.scopeProfile.selectedProjectScope, scopeProfiles, meterType);
    double? usageFactor = widget.usageCalc!.getTypeUsageFactor(groupType);
    for (var meterStat in meterUsageList) {
      final meterUsageSummary = meterStat['meter_usage_summary'];
      String usageStr = meterUsageSummary['usage'] ?? '';
      double? usageVal = double.tryParse(usageStr);
      if (usageVal == null) {
        if (kDebugMode) {
          print('usageVal is null');
        }
      }
      if (usageVal != null && usageFactor != null) {
        usageVal = usageVal * usageFactor;
        meterUsageSummary['usage_factored'] = usageVal;
        meterUsageSummary['factor'] = usageFactor;
      }

      meterStatList.add(meterUsageSummary);
      meterList.add(
        getMeterStat(meterUsageSummary, groupType, false),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        verticalSpaceSmall,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
                onTap: () {
                  setState(() {
                    groupInfo['showChart'] = !(groupInfo['showChart'] ?? false);
                  });
                },
                child: Icon(Symbols.analytics,
                    size: 21, color: Theme.of(context).colorScheme.primary)),
            horizontalSpaceTiny,
            Text(groupName,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).hintColor.withAlpha(180),
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        // verticalSpaceTiny,
        Text(groupLabel,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).hintColor.withAlpha(130),
              fontWeight: FontWeight.bold,
            )),
        if (groupInfo['showChart'] ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 10),
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
      bool calcUsageFromReadings) {
    // String meterName = meterStat['item_name'];
    String meterSn = meterUsage['meter_sn'];
    // String altName = meterStat['alt_name'];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: WgtPagUsageStatCore(
        loggedInUser: widget.loggedInUser,
        displayContextStr: widget.displayContextStr,
        showFactoredUsage: widget.showFactoredUsage,
        calcUsageFromReadings: calcUsageFromReadings,
        appConfig: widget.appConfig,
        isBillMode: widget.isBillMode,
        rate: widget.typeRates?[meterTypeTag] ?? 0,
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

  Widget getManualUsage() {
    if (widget.manualUsages.isEmpty) {
      return Container();
    }
    List<Widget> manualUsageList = [];
    for (var item in widget.manualUsages) {
      // String usageStr = item['usage'] ?? '';
      // double? usageVal = double.tryParse(usageStr);
      double? usageVal = item['usage'];
      String meterTypeTag = item['meter_type'] ?? '';
      if (usageVal != null) {
        MeterType? meterType = getMeterType(meterTypeTag);
        if (meterType != null) {
          manualUsageList.add(
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: WgtPagUsageStatCore(
                loggedInUser: widget.loggedInUser,
                appConfig: widget.appConfig,
                displayContextStr: widget.displayContextStr,
                isBillMode: widget.isBillMode,
                rate: widget.typeRates?[meterTypeTag] ?? 0,
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
          ...manualUsageList,
        ],
      ),
    );
  }

  Widget getLineItem() {
    if (widget.lineItems.isEmpty) {
      return Container();
    }
    if (widget.lineItems.first.isEmpty) {
      return Container();
    }
    List<Widget> lineItemList = [];
    for (var lineItem in widget.lineItems) {
      String label = lineItem['label'] ?? '';
      String valueStr = lineItem['amount'] ?? '';
      double? valueVal = double.tryParse(valueStr) ?? 0;
      lineItemList.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor.withAlpha(180),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            maxHeight: 55,
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

  Widget getSubTenantUsageList() {
    List<Widget> subTenantUsageList = [];
    for (var subTenantUsage in widget.usageCalc!.subTenantUsage) {
      String tenantName = subTenantUsage['tenant_name'] ?? '';
      String tenantLabel = subTenantUsage['tenant_label'] ?? '';
      List<EmsTypeUsage> typeUsageList = subTenantUsage['type_usage_list'];

      subTenantUsageList.add(
        getSubTenantUsage(
          tenantName,
          tenantLabel,
          typeUsageList,
        ),
      );
    }
    return Column(
      children: [...subTenantUsageList],
    );
  }

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

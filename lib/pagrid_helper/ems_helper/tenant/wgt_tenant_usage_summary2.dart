import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_helper/pagrid_app_config.dart';
import '../usage/usage_stat_helper.dart';
import 'mdl_ems_type_usage.dart';

class WgtTenantUsageSummary2 extends StatefulWidget {
  const WgtTenantUsageSummary2({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
    required this.itemType,
    required this.isMonthly,
    required this.fromDatetime,
    required this.toDatetime,
    required this.tenantName,
    required this.tenantType,
    required this.excludeAutoUsage,
    this.usageCalc,
    this.showFactoredUsage = true,
    // required this.usageFactor,
    this.typeRates,
    this.renderMode = 'wgt', // wgt, pdf
    this.showRenderModeSwitch = false,
    this.tenantLabel,
    this.tenantAccountId = '',
    // for rendering, not calculation
    this.tenantUsageSummary = const [],
    this.subTenantListUsageSummary = const [],
    this.manualUsages = const [],
    this.isBillMode = false,
    // this.meterTypeRates = const {},
    // this.gst,
    this.lineItems = const [],
    // this.billedAutoUsages = const {},
    this.usageDecimals = 3,
    this.rateDecimals = 4,
    this.costDecimals = 3,
  });

  final PaGridAppConfig appConfig;
  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final EmsTypeUsageCalc? usageCalc;
  final bool showFactoredUsage;
  final ItemType itemType;
  final bool isMonthly;
  final DateTime fromDatetime;
  final DateTime toDatetime;
  final String tenantName;
  final String? tenantLabel;
  final String tenantAccountId;
  final String tenantType;
  final bool excludeAutoUsage;
  final List<Map<String, dynamic>> tenantUsageSummary;
  final List<Map<String, dynamic>> subTenantListUsageSummary;
  final bool isBillMode;
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
  State<WgtTenantUsageSummary2> createState() => _WgtTenantUsageSummary2State();
}

class _WgtTenantUsageSummary2State extends State<WgtTenantUsageSummary2> {
  final double widgetWidth = 750;

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
          context: context, errorText: 'Usage data not available');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // getUsageTitle(),
                // getUsageTypeStat(),
                getUsageTitle(
                  context,
                  widget.fromDatetime,
                  widget.toDatetime,
                  widget.isMonthly,
                  widget.tenantLabel,
                  widget.tenantName,
                  widget.tenantAccountId,
                ),
                getUsageTypeStat(
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
              ),
          ],
        ),
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
    List<Map<String, dynamic>> typeGroupInfoList = [];
    typeGroupInfoList = widget.tenantUsageSummary
        .where((element) => element['meter_type'] == typeStr)
        .toList();
    for (var groupInfo in typeGroupInfoList) {
      String meterTypeTag = groupInfo['meter_type'] ?? '';
      MeterType? meterType = getMeterType(meterTypeTag);
      typeGroups.add(getGroupMeterStat(groupInfo, meterType));
    }
    return SizedBox(
      width: widgetWidth,
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
    final meterListUsageSummary =
        meterGroupUsageSummary['meter_list_usage_summary'] ?? [];

    List<Widget> meterList = [];
    List<Map<String, dynamic>> meterStatList = [];

    // double usageFactor = getProjectMeterUsageFactor(widget.scopeProfile.selectedProjectScope, scopeProfiles, meterType);
    double? usageFactor = widget.usageCalc!.getTypeUsageFactor(groupType);
    for (var meterStat in meterListUsageSummary) {
      String usageStr = meterStat['usage'] ?? '';
      double? usageVal = double.tryParse(usageStr);
      if (usageVal == null) {
        if (kDebugMode) {
          print('usageVal is null');
        }
      }
      if (usageVal != null && usageFactor != null) {
        usageVal = usageVal * usageFactor;
        meterStat['usage_factored'] = usageVal;
        meterStat['factor'] = usageFactor;
      }

      meterStatList.add(meterStat);
      meterList.add(
        getMeterStat(meterStat, groupType, false),
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
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        // verticalSpaceTiny,
        Text(groupLabel,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).hintColor.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            )),
        if (groupInfo['showChart'] ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: WgtMeterGroupStatCore(
              loggedInUser: widget.loggedInUser,
              scopeProfile: widget.scopeProfile,
              appConfig: widget.appConfig,
              statColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Widget getMeterStat(Map<String, dynamic> meterStat, String meterTypeTag,
      bool calcUsageFromReadings) {
    String meterName = meterStat['item_name'];
    String meterSn = meterStat['item_sn'];
    String altName = meterStat['alt_name'];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: WgtUsageStatCore(
        loggedInUser: widget.loggedInUser,
        scopeProfile: widget.scopeProfile,
        showFactoredUsage: widget.showFactoredUsage,
        calcUsageFromReadings: calcUsageFromReadings,
        appConfig: widget.appConfig,
        isBillMode: widget.isBillMode,
        rate: widget.typeRates?[meterTypeTag] ?? 0,
        statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        showTrending: false,
        statVirticalStack: false,
        // height: 110,
        usageDecimals: widget.usageDecimals,
        rateDecimals: widget.rateDecimals,
        costDecimals: widget.costDecimals,
        meterType: getMeterType(meterTypeTag)!,
        meterId: meterName,
        meterIdType: ItemIdType.name,
        itemType: widget.itemType,
        historyType: Evs2HistoryType.meter_list_usage_summary,
        meterStat: meterStat,
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
              child: WgtUsageStatCore(
                loggedInUser: widget.loggedInUser,
                scopeProfile: widget.scopeProfile,
                appConfig: widget.appConfig,
                isBillMode: widget.isBillMode,
                rate: widget.typeRates?[meterTypeTag] ?? 0,
                statColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                historyType: Evs2HistoryType.meter_list_usage_summary,
                isStaticUsageStat: true,
                meterStat: {'usage': usageVal},
              ),
            ),
          );
        }
      }
    }
    return SizedBox(
      width: widgetWidth,
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
                    color: Theme.of(context).hintColor.withOpacity(0.7),
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
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            horizontalSpaceSmall,
            getStatWithUnit(
              getCommaNumberStr(valueVal, decimal: 2),
              'SGD',
              statStrStyle: defStatStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                color: Theme.of(context).hintColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        verticalSpaceSmall,
        Container(
          width: widgetWidth,
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
      width: widgetWidth,
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
                    color: Theme.of(context).hintColor.withOpacity(0.7),
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

import 'package:buff_helper/pag_helper/model/mdl_history.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../usage/pag_usage_stat_helper.dart';
import '../usage/usage_stat_helper.dart';
import '../usage/wgt_pag_meter_stat_core.dart';
import 'tenant_usage_calc_released_r2.dart';

class WgtPagTenantUsageSummaryReleased extends StatefulWidget {
  const WgtPagTenantUsageSummaryReleased({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.usageCalc,
    required this.itemType,
    required this.isMonthly,
    required this.fromDatetime,
    required this.toDatetime,
    required this.tenantName,
    required this.tenantType,
    required this.excludeAutoUsage,
    required this.displayContextStr,
    this.renderMode = 'wgt', // wgt, pdf
    this.showRenderModeSwitch = false,
    this.tenantLabel,
    this.tenantAccountId = '',
    this.isBillMode = false,
    this.meterTypeRates = const {},
    this.gst,
    this.manualUsages = const {},
    this.lineItems = const [],
    this.billedAutoUsages = const {},
    this.billedSubTenantUsages = const {},
    required this.billedUsageFactor,
    this.usageDecimals = 3,
    this.rateDecimals = 4,
    this.costDecimals = 3,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> billedUsageFactor;
  final String displayContextStr;
  final EmsTypeUsageCalcReleasedR2 usageCalc;
  final ItemType itemType;
  final bool isMonthly;
  final DateTime fromDatetime;
  final DateTime toDatetime;
  final String tenantName;
  final String tenantAccountId;
  final String? tenantLabel;
  final String tenantType;
  final bool excludeAutoUsage;
  final bool isBillMode;
  final Map<String, dynamic> meterTypeRates;
  final double? gst;
  final Map<String, dynamic> manualUsages;
  final List<Map<String, dynamic>> lineItems;
  final String renderMode;
  final bool showRenderModeSwitch;
  final Map<String, dynamic> billedAutoUsages;
  final Map<String, dynamic> billedSubTenantUsages;
  final int usageDecimals;
  final int rateDecimals;
  final int costDecimals;

  @override
  State<WgtPagTenantUsageSummaryReleased> createState() =>
      _WgtPagTenantUsageSummaryReleasedState();
}

class _WgtPagTenantUsageSummaryReleasedState
    extends State<WgtPagTenantUsageSummaryReleased> {
  final List<String> usageTypeList = ['E', 'B', 'W', 'N', 'G'];

  final widgetWidth = 750.0;
  String _renderMode = 'wgt'; // wgt, pdf

  @override
  void initState() {
    super.initState();
    _renderMode = widget.renderMode;
  }

  @override
  Widget build(BuildContext context) {
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
                getPagUsageTitle(
                  context,
                  widget.fromDatetime,
                  widget.toDatetime,
                  widget.isMonthly,
                  widget.tenantLabel,
                  widget.tenantName,
                  widget.tenantAccountId,
                ),
                getPagUsageTypeTopStat(
                  costDecimals: widget.costDecimals,
                  context,
                  widget.isBillMode,
                  widget.usageCalc.typeUsageE!.usageFactored,
                  widget.usageCalc.typeUsageE!.cost,
                  widget.usageCalc.typeUsageW!.usageFactored,
                  widget.usageCalc.typeUsageW!.cost,
                  widget.usageCalc.typeUsageB!.usageFactored,
                  widget.usageCalc.typeUsageB!.cost,
                  widget.usageCalc.typeUsageN!.usageFactored,
                  widget.usageCalc.typeUsageN!.cost,
                  widget.usageCalc.typeUsageG!.usageFactored,
                  widget.usageCalc.typeUsageG!.cost,
                ),
              ],
            ),
            Divider(color: Theme.of(context).hintColor),
            widget.excludeAutoUsage
                ? getAutoUsageExcludedInfo(context)
                : getAutoUsage(),
            verticalSpaceSmall,
            getManualUsage(),
            verticalSpaceSmall,
            getSubTenantUsage(),
            verticalSpaceSmall,
            verticalSpaceSmall,
            getPagTypeUsageNet(
              context,
              widget.loggedInUser,
              widget.appConfig,
              widget.usageCalc.typeUsageE!.usageFactored,
              widget.usageCalc.typeUsageE!.rate,
              widget.usageCalc.typeUsageW!.usageFactored,
              widget.usageCalc.typeUsageW!.rate,
              widget.usageCalc.typeUsageB!.usageFactored,
              widget.usageCalc.typeUsageB!.rate,
              widget.usageCalc.typeUsageN!.usageFactored,
              widget.usageCalc.typeUsageN!.rate,
              widget.usageCalc.typeUsageG!.usageFactored,
              widget.usageCalc.typeUsageG!.rate,
              usageDecimals: widget.usageDecimals,
              rateDecimals: widget.rateDecimals,
              costDecimals: widget.costDecimals,
            ),
            verticalSpaceSmall,
            getLineItem(),
            verticalSpaceSmall,
            if (widget.isBillMode)
              getTotal2(
                context,
                widget.gst!,
                widget.usageCalc.subTotalCost,
                widget.usageCalc.gstAmount,
                widget.usageCalc.totalCost,
                widget.tenantType,
                null,
                null,
              ),
          ],
        ),
      ),
    );
  }

  Widget getAutoUsage() {
    if (widget.billedAutoUsages.isEmpty) {
      return Container();
    }
    List<Widget> autoUsageList = [];
    // for (var key in widget.billedAutoUsages.keys) {
    for (var usageTypeTag in usageTypeList) {
      double? usageVal = widget
          .billedAutoUsages['billed_auto_usage_$usageTypeTag'.toLowerCase()];
      if (usageVal == null) {
        continue;
      }
      String meterTypeTag = usageTypeTag;

      double? factor = widget
          .billedUsageFactor['billed_usage_factor_$meterTypeTag'.toLowerCase()];
      if (factor == null) {
        throw Exception('usageFactored is null');
      }
      double? usageFactored = usageVal * factor;

      Map<String, dynamic> meterStat = {
        'usage': usageVal,
        'usage_factored': usageFactored,
        'factor': factor,
      };

      MeterType? meterType = getMeterType(meterTypeTag);
      if (meterType != null) {
        autoUsageList.add(
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: WgtPagUsageStatCore(
              loggedInUser: widget.loggedInUser,
              appConfig: widget.appConfig,
              displayContextStr: widget.displayContextStr,
              isBillMode: widget.isBillMode,
              rate: widget.meterTypeRates[meterTypeTag],
              statColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              showTrending: false,
              statVirticalStack: false,
              height: 110,
              usageDecimals: widget.usageDecimals,
              rateDecimals: widget.rateDecimals,
              costDecimals: widget.costDecimals,
              meterType: meterType,
              meterId: meterTypeTag.toUpperCase(),
              meterIdType: ItemIdType.name,
              itemType: widget.itemType,
              historyType: PagItemHistoryType.meterListUsageSummary,
              isStaticUsageStat: true,
              meterUsageSummary: meterStat,
            ),
          ),
        );
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
              Icon(Symbols.auto_awesome_motion,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text('Auto Usage',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...autoUsageList,
        ],
      ),
    );
  }

  Widget getSubTenantUsage() {
    if (widget.billedSubTenantUsages.isEmpty) {
      return Container();
    }
    if (widget.billedSubTenantUsages.values
        .every((element) => element == null)) {
      return Container();
    }
    List<Widget> subTenantUsageList = [];
    for (var key in widget.billedSubTenantUsages.keys) {
      // String usageStr = widget.billedSubTenantUsages[key] ?? '';
      double? usageVal = widget.billedSubTenantUsages[key];
      if (usageVal == null) {
        continue;
      }

      String meterTypeTag = key.split('_').last;

      double? factor = widget
          .billedUsageFactor['billed_usage_factor_$meterTypeTag'.toLowerCase()];
      if (factor == null) {
        throw Exception('usageFactored is null');
      }
      double? usageFactored = usageVal * factor;

      Map<String, dynamic> meterStat = {
        'usage': usageVal,
        'usage_factored': usageFactored,
        'factor': factor,
      };

      MeterType? meterType = getMeterType(meterTypeTag);
      if (meterType != null) {
        subTenantUsageList.add(
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: WgtPagUsageStatCore(
              loggedInUser: widget.loggedInUser,
              appConfig: widget.appConfig,
              displayContextStr: widget.displayContextStr,
              isBillMode: widget.isBillMode,
              rate: widget.meterTypeRates[meterTypeTag],
              statColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              showTrending: false,
              statVirticalStack: false,
              height: 110,
              usageDecimals: widget.usageDecimals,
              rateDecimals: widget.rateDecimals,
              costDecimals: widget.costDecimals,
              meterType: meterType,
              meterId: meterTypeTag.toUpperCase(),
              meterIdType: ItemIdType.name,
              itemType: widget.itemType,
              historyType: PagItemHistoryType.meterListUsageSummary,
              isStaticUsageStat: true,
              isSubstractUsage: true,
              meterUsageSummary: meterStat, //{'usage': usageVal},
              showRate: false,
            ),
          ),
        );
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
              Icon(Symbols.group,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text('Sub Tenant Usage',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...subTenantUsageList,
        ],
      ),
    );
  }

  Widget getManualUsage() {
    if (widget.manualUsages.isEmpty) {
      return Container();
    }
    if (widget.manualUsages.values.every((element) => element == null)) {
      return Container();
    }
    List<Widget> manualUsageList = [];
    for (var key in widget.manualUsages.keys) {
      // String usageStr = widget.manualUsages[key] ?? '';
      double? usageVal = widget.manualUsages[key];
      String meterTypeTag = key.split('_').last;
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
                rate: widget.meterTypeRates[meterTypeTag],
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
                historyType: PagItemHistoryType.meterListUsageSummary,
                isStaticUsageStat: true,
                meterUsageSummary: {'usage': usageVal},
              ),
            ),
            // Text(
            //   '${meterType.name}: ${getCommaNumberStr(usageVal, decimal: 2)} ${getDeivceTypeUnit(meterType)}',
            //   style: TextStyle(
            //     fontSize: 15,
            //     color: Theme.of(context).hintColor.withOpacity(0.5),
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
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
      double? valueVal = double.tryParse(valueStr);
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
}

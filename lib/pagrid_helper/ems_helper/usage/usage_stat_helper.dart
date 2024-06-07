import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/up_helper/helper/tenant_def.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_helper/pagrid_app_config.dart';

Widget getTypeUsageStat(
    BuildContext context, String meterTypeTag, Map<String, double> usage,
    {int usageDecimals = 3,
    int rateDecimals = 4,
    int costDecimals = 2,
    bool isSubTenant = false,
    bool showFactoredUsage = true}) {
  MeterType? type = getMeterType(meterTypeTag);
  Color statColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  double usageVal = usage['usage'] as double;
  if (showFactoredUsage) {
    if (usage['factor'] != null) {
      usageVal = usageVal * usage['factor']!;
    } else {
      throw Exception('Factor is null');
    }
  }
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      // height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      // constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade600, width: 1),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Row(
                children: [
                  getDeviceTypeIcon(type, iconSize: 21, iconColor: statColor),
                  // horizontalSpaceTiny,
                  Text(
                    meterTypeTag.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      color: statColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          horizontalSpaceSmall,
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total ${getDeivceTypeUnit(type)}',
                  style: defStatStyleSmall,
                ),
                getStatWithUnit(
                  isSubTenant
                      ? '(${getCommaNumberStr(usageVal, decimal: usageDecimals)})'
                      : getCommaNumberStr(usageVal, decimal: usageDecimals),
                  getDeivceTypeUnit(type),
                  statStrStyle: defStatStyleLarge.copyWith(
                    color: statColor,
                  ),
                  unitStyle: defStatStyleSmall,
                  showUnit: false,
                ),
                if (showFactoredUsage && (usage['factor'] ?? 1) < 0.99999)
                  Text(
                    'Factor: ${(1 / (usage['factor'] ?? 1)).toStringAsFixed(5)}',
                    style: defStatStyleSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget getUsageTitle(
    BuildContext context,
    DateTime fromDatetime,
    DateTime toDatetime,
    bool isMonthly,
    String? tenantLabel,
    String tenantName,
    String? tenantAccountId) {
  String rangeStr = getTimeRangeStr(
    fromDatetime,
    toDatetime,
    targetInterval: isMonthly ? 'monthly' : 'daily',
    useMiddle: isMonthly ? true : false,
  );
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 350),
    child: Container(
      padding: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).hintColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tenantLabel ?? '',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).hintColor,
            ),
          ),
          Row(
            children: [
              Text(
                tenantName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                ),
              ),
              horizontalSpaceRegular,
              Text(
                tenantAccountId ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          verticalSpaceSmall,
          Text(
            rangeStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget getUsageTypeStat(
  BuildContext context,
  bool isBillMode,
  double? netUsageE,
  double? costE,
  double? netUsageW,
  double? costW,
  double? netUsageB,
  double? costB,
  double? netUsageN,
  double? costN,
  double? netUsageG,
  double? costG, {
  int usageDecimals = 3,
  int rateDecimals = 4,
  int costDecimals = 3,
}) {
  TextStyle valueStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 34,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    // color: Colors.grey.shade800,
  );
  return Row(
    children: [
      if (netUsageE != null)
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            children: [
              getMeterTypeWidget(MeterType.electricity1p, context),
              isBillMode
                  ? getStatWithUnit(
                      getCommaNumberStr(costE, decimal: costDecimals), 'SGD',
                      statStrStyle: valueStyle)
                  : getStatWithUnit(
                      getCommaNumberStr(netUsageE, decimal: usageDecimals),
                      getDeivceTypeUnit(MeterType.electricity1p),
                      statStrStyle: valueStyle),
            ],
          ),
        ),
      if (netUsageB != null)
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            children: [
              getMeterTypeWidget(MeterType.btu, context),
              isBillMode
                  ? getStatWithUnit(
                      getCommaNumberStr(costB, decimal: costDecimals), 'SGD',
                      statStrStyle: valueStyle)
                  : getStatWithUnit(
                      getCommaNumberStr(netUsageB, decimal: usageDecimals),
                      getDeivceTypeUnit(MeterType.btu),
                      statStrStyle: valueStyle),
            ],
          ),
        ),
      if (netUsageW != null)
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            children: [
              getMeterTypeWidget(MeterType.water, context),
              isBillMode
                  ? getStatWithUnit(
                      getCommaNumberStr(costW, decimal: costDecimals), 'SGD',
                      statStrStyle: valueStyle)
                  : getStatWithUnit(
                      getCommaNumberStr(netUsageW, decimal: usageDecimals),
                      getDeivceTypeUnit(MeterType.water),
                      statStrStyle: valueStyle),
            ],
          ),
        ),
      if (netUsageN != null)
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            children: [
              getMeterTypeWidget(MeterType.newater, context),
              isBillMode
                  ? getStatWithUnit(
                      getCommaNumberStr(costN, decimal: costDecimals), 'SGD',
                      statStrStyle: valueStyle)
                  : getStatWithUnit(
                      getCommaNumberStr(netUsageN, decimal: usageDecimals),
                      getDeivceTypeUnit(MeterType.newater),
                      statStrStyle: valueStyle),
            ],
          ),
        ),
      if (netUsageG != null)
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            children: [
              getMeterTypeWidget(MeterType.gas, context),
              isBillMode
                  ? getStatWithUnit(
                      getCommaNumberStr(costG, decimal: costDecimals), 'SGD',
                      statStrStyle: valueStyle)
                  : getStatWithUnit(
                      getCommaNumberStr(netUsageG, decimal: usageDecimals),
                      getDeivceTypeUnit(MeterType.gas),
                      statStrStyle: valueStyle),
            ],
          ),
        ),
    ],
  );
}

Widget getTypeUsageNet(
    BuildContext context,
    Evs2User loggedInUser,
    ScopeProfile scopeProfile,
    PaGridAppConfig appConfig,
    double? netUsageE,
    double? rateE,
    double? netUsageW,
    double? rateW,
    double? netUsageB,
    double? rateB,
    double? netUsageN,
    double? rateN,
    double? netUsageG,
    double? rateG,
    {int usageDecimals = 3,
    int rateDecimals = 4,
    int costDecimals = 2,
    double width = 750}) {
  if (netUsageE == null &&
      netUsageW == null &&
      netUsageB == null &&
      netUsageN == null &&
      netUsageG == null) {
    return Container();
  }
  return SizedBox(
    width: width,
    child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.functions,
              size: 21, color: Theme.of(context).colorScheme.primary),
          horizontalSpaceTiny,
          Text(
            'Net Usage',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).hintColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      if (netUsageE != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtUsageStatCore(
            loggedInUser: loggedInUser,
            scopeProfile: scopeProfile,
            appConfig: appConfig,
            isBillMode: true,
            rate: rateE,
            statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            showTrending: false,
            statVirticalStack: false,
            height: 110,
            usageDecimals: usageDecimals,
            rateDecimals: rateDecimals,
            costDecimals: costDecimals,
            meterType: MeterType.electricity1p,
            meterId: 'E',
            meterIdType: ItemIdType.name,
            itemType: ItemType.meter_iwow,
            historyType: Evs2HistoryType.meter_list_usage_summary,
            isStaticUsageStat: true,
            meterStat: {'usage': netUsageE},
          ),
        ),
      if (netUsageB != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtUsageStatCore(
            loggedInUser: loggedInUser,
            scopeProfile: scopeProfile,
            appConfig: appConfig,
            isBillMode: true,
            rate: rateB,
            statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            showTrending: false,
            statVirticalStack: false,
            height: 110,
            usageDecimals: usageDecimals,
            rateDecimals: rateDecimals,
            costDecimals: costDecimals,
            meterType: MeterType.btu,
            meterId: 'B',
            meterIdType: ItemIdType.name,
            itemType: ItemType.meter_iwow,
            historyType: Evs2HistoryType.meter_list_usage_summary,
            isStaticUsageStat: true,
            meterStat: {'usage': netUsageB},
          ),
        ),
      if (netUsageW != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtUsageStatCore(
            loggedInUser: loggedInUser,
            scopeProfile: scopeProfile,
            appConfig: appConfig,
            isBillMode: true,
            rate: rateW,
            statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            showTrending: false,
            statVirticalStack: false,
            height: 110,
            usageDecimals: usageDecimals,
            rateDecimals: rateDecimals,
            costDecimals: costDecimals,
            meterType: MeterType.water,
            meterId: 'W',
            meterIdType: ItemIdType.name,
            itemType: ItemType.meter_iwow,
            historyType: Evs2HistoryType.meter_list_usage_summary,
            isStaticUsageStat: true,
            meterStat: {'usage': netUsageW},
          ),
        ),
      if (netUsageN != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtUsageStatCore(
            loggedInUser: loggedInUser,
            scopeProfile: scopeProfile,
            appConfig: appConfig,
            isBillMode: true,
            rate: rateN,
            statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            showTrending: false,
            statVirticalStack: false,
            height: 110,
            usageDecimals: usageDecimals,
            rateDecimals: rateDecimals,
            costDecimals: costDecimals,
            meterType: MeterType.newater,
            meterId: 'N',
            meterIdType: ItemIdType.name,
            itemType: ItemType.meter_iwow,
            historyType: Evs2HistoryType.meter_list_usage_summary,
            isStaticUsageStat: true,
            meterStat: {'usage': netUsageN},
          ),
        ),
      if (netUsageG != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtUsageStatCore(
            loggedInUser: loggedInUser,
            scopeProfile: scopeProfile,
            appConfig: appConfig,
            isBillMode: true,
            rate: rateG,
            statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            showTrending: false,
            statVirticalStack: false,
            height: 110,
            usageDecimals: usageDecimals,
            rateDecimals: rateDecimals,
            costDecimals: costDecimals,
            meterType: MeterType.gas,
            meterId: 'G',
            meterIdType: ItemIdType.name,
            itemType: ItemType.meter_iwow,
            historyType: Evs2HistoryType.meter_list_usage_summary,
            isStaticUsageStat: true,
            meterStat: {'usage': netUsageG},
          ),
        ),
    ]),
  );
}

Widget getTotal(
    BuildContext context,
    double? costE,
    double? costW,
    double? costB,
    double? costN,
    double? costG,
    double? costLineItems,
    double gst,
    String tenantType,
    {double width = 750.0}) {
  double? totalCost;
  if (costE != null) {
    totalCost = (totalCost ?? 0) + costE;
  }
  if (costW != null) {
    totalCost = (totalCost ?? 0) + costW;
  }
  if (costB != null) {
    totalCost = (totalCost ?? 0) + costB;
  }
  if (costN != null) {
    totalCost = (totalCost ?? 0) + costN;
  }
  if (costG != null) {
    totalCost = (totalCost ?? 0) + costG;
  }
  if (costLineItems != null) {
    totalCost = (totalCost ?? 0) + costLineItems;
  }
  double? subTotalAmt = totalCost;
  if (subTotalAmt != null) {
    // subTotalAmt = getRoundUp(subTotalAmt, 2);
    // subTotalAmt = getRound(subTotalAmt, 2);
  }
  double? totalAmt = subTotalAmt;
  bool applyGst = false;
  double? gstAmt;
  if (TenantType.cw_nus_internal != getTenantType(tenantType)) {
    applyGst = true;
    if (subTotalAmt != null && gst != null) {
      subTotalAmt = getRound(subTotalAmt, 2);
      gstAmt = subTotalAmt * gst / 100;
      gstAmt = getRoundUp(gstAmt, 2);
      // total = subTotal + subTotal * (gst / 100);
      totalAmt = subTotalAmt + gstAmt;
    }
  } else {
    applyGst = false;
    if (subTotalAmt != null) {
      totalAmt = getRoundUp(subTotalAmt, 2);
    }
  }
  return Container(
    width: width,
    // height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 21),
    // constraints: const BoxConstraints(maxHeight: 130),
    decoration: BoxDecoration(
      border:
          Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
      borderRadius: BorderRadius.circular(5.0),
    ),
    child: Column(
      children: [
        if (applyGst)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'Sub Total',
                    style: defStatStyle,
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  getCommaNumberStr(subTotalAmt, decimal: 2),
                  'SGD',
                  statStrStyle: defStatStyle.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        if (applyGst)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'GST ($gst%)',
                    style: defStatStyle,
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  // getCommaNumberStr(subTotal * (gst / 100), decimal: 2),
                  getCommaNumberStr(gstAmt, decimal: 2),
                  'SGD',
                  statStrStyle: defStatStyle.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: Text(
                  'Total',
                  style: defStatStyleLarge.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ),
              horizontalSpaceSmall,
              getStatWithUnit(
                // getCommaNumberStr(total, decimal: 2),
                getCommaNumberStr(totalAmt, decimal: 2, isRoundUp: false),
                'SGD',
                statStrStyle: defStatStyleLarge.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget getTotal2(BuildContext context, double gst, double? subTotalAmt,
    double? gstAmt, double? totalAmt, String tenantType,
    {double width = 750.0}) {
  bool applyGst = tenantType != 'cw_nus_internal';

  return Container(
    width: width,
    // height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 21),
    // constraints: const BoxConstraints(maxHeight: 130),
    decoration: BoxDecoration(
      border:
          Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
      borderRadius: BorderRadius.circular(5.0),
    ),
    child: Column(
      children: [
        if (applyGst)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'Sub Total',
                    style: defStatStyle,
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  getCommaNumberStr(subTotalAmt, decimal: 2),
                  'SGD',
                  statStrStyle: defStatStyle.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        if (applyGst)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'GST ($gst%)',
                    style: defStatStyle,
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  // getCommaNumberStr(subTotal * (gst / 100), decimal: 2),
                  getCommaNumberStr(gstAmt, decimal: 2),
                  'SGD',
                  statStrStyle: defStatStyle.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: Text(
                  'Total',
                  style: defStatStyleLarge.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ),
              horizontalSpaceSmall,
              getStatWithUnit(
                applyGst
                    ? getCommaNumberStr(totalAmt, decimal: 2, isRoundUp: false)
                    : getCommaNumberStr(subTotalAmt,
                        decimal: 2, isRoundUp: false),
                'SGD',
                statStrStyle: defStatStyleLarge.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget getAutoUsageExcludedInfo(BuildContext context, {double width = 750}) {
  return Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 3),
    constraints: const BoxConstraints(
      maxHeight: 55,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade600, width: 1),
      borderRadius: BorderRadius.circular(5.0),
    ),
    child: Center(
      child: Text(
        'Auto Usage Excluded',
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).hintColor.withOpacity(0.5),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

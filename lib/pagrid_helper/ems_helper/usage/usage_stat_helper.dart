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
  Color statColor = Theme.of(context).colorScheme.onSurface.withAlpha(210);
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
                  color: Theme.of(context).hintColor.withAlpha(210),
                ),
              ),
              horizontalSpaceRegular,
              Text(
                tenantAccountId ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor.withAlpha(210),
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
    double? costG,
    {int usageDecimals = 3,
    int rateDecimals = 4,
    int costDecimals = 3,
    String? displayContextStr}) {
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
              getMeterTypeWidget(MeterType.btu, context,
                  displayContextStr: displayContextStr),
              isBillMode
                  ? getStatWithUnit(
                      getCommaNumberStr(costB, decimal: costDecimals), 'SGD',
                      statStrStyle: valueStyle)
                  : getStatWithUnit(
                      getCommaNumberStr(netUsageB, decimal: usageDecimals),
                      getDeivceTypeUnit(MeterType.btu,
                          displayContextStr: displayContextStr),
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
  double? rateG, {
  int usageDecimals = 3,
  int rateDecimals = 4,
  int costDecimals = 2,
  double width = 750,
  String displayContontextStr = '',
}) {
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
              color: Theme.of(context).hintColor.withAlpha(210),
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
            displayContextStr: displayContontextStr,
            isBillMode: true,
            rate: rateE,
            statColor: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
            displayContextStr: displayContontextStr,
            isBillMode: true,
            rate: rateB,
            statColor: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
            displayContextStr: displayContontextStr,
            isBillMode: true,
            rate: rateW,
            statColor: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
            displayContextStr: displayContontextStr,
            isBillMode: true,
            rate: rateN,
            statColor: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
            displayContextStr: displayContontextStr,
            isBillMode: true,
            rate: rateG,
            statColor: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget getTotal2(
    BuildContext context,
    double gst,
    double? subTotalAmt,
    double? gstAmt,
    double? totalAmt,
    String tenantType,
    double? balBfUsage,
    double? balBfInterest,
    Map<String, dynamic> interestInfo,
    {Function? onCheckInterestDetail,
    bool showInterestDetail = false,
    double width = 750.0}) {
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
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
        // bal b/f
        if (balBfUsage != null && balBfUsage.abs() > -0.00001)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'Bal. B/F (Usage)',
                    style: defStatStyle,
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  getCommaNumberStr(balBfUsage, decimal: 2),
                  'SGD',
                  statStrStyle: defStatStyle.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
        if (balBfInterest != null && balBfInterest.abs() > -0.00001)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'Bal. B/F (Interest)',
                    style: defStatStyle,
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  getCommaNumberStr(balBfInterest, decimal: 2),
                  'SGD',
                  statStrStyle: defStatStyle.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              getInterestInfo(
                interestInfo,
                context,
                showInterestDetail,
                onCheckInterestDetail,
              )
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
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
          color: Theme.of(context).hintColor.withAlpha(130),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget getInterestInfo(
  Map<String, dynamic> interestInfo,
  BuildContext context,
  bool showInterestDetail,
  Function? onCheckDetail,
) {
  final totalInterestAmount = interestInfo['total_interest_amount'];
  double totalInterestAmountDouble = 0.0;
  if (totalInterestAmount is String) {
    totalInterestAmountDouble = double.tryParse(totalInterestAmount) ?? 0.0;
  } else if (totalInterestAmount is double) {
    totalInterestAmountDouble = totalInterestAmount;
  }
  final precedingBillInfo =
      interestInfo['preceding_bill_info'] as Map<String, dynamic>?;
  List<Widget> billWidgets = [];
  Map<String, dynamic> bill = {};
  bill.addAll(precedingBillInfo ?? {});
  if (bill.isNotEmpty) {
    // final billId = bill['bill_id'];
    final billLabel = bill['label'];
    final billDate = bill['bill_date_timestamp'];
    final billedTotalAmount = bill['billed_total_amount'];
    final tti = bill['tti'];
    final ttiDays = bill['tti_days'];
    final tai = bill['tai'];
    final paymentTermDays = bill['payment_term_days'];
    final interestRate = bill['interest_rate'];
    final dueDate = bill['due_date_timestamp'];
    final totalOverdueDays = bill['total_overdue_days'];
    final paymentApplyList = bill['payment_apply_list'];

    final cycleStartDateTimestamp = bill['cycle_start_date_timestamp'];
    final cycleEndDateTimestamp = bill['cycle_end_date_timestamp'];
    final daysInCycle = bill['days_in_cycle'];

    List<Map<String, dynamic>> paymentApplyListCasted = [];
    if (paymentApplyList != null) {
      for (var payment in paymentApplyList) {
        if (payment is Map<String, dynamic>) {
          paymentApplyListCasted.add(payment);
        }
      }
    }

    double billedTotalAmountDouble = 0.0;
    if (billedTotalAmount is String) {
      billedTotalAmountDouble = double.tryParse(billedTotalAmount) ?? 0.0;
    } else if (billedTotalAmount is double) {
      billedTotalAmountDouble = billedTotalAmount;
    }
    double totalTheoreticalInterestToDateDouble = 0.0;
    if (tti is String) {
      totalTheoreticalInterestToDateDouble = double.tryParse(tti) ?? 0.0;
    } else if (tti is double) {
      totalTheoreticalInterestToDateDouble = tti;
    }
    int? ttiDaysInt;
    if (ttiDays is String) {
      ttiDaysInt = int.tryParse(ttiDays) ?? 0;
    } else if (ttiDays is int) {
      ttiDaysInt = ttiDays;
    }
    double totalActualInterestToDateDouble = 0.0;
    if (tai is String) {
      totalActualInterestToDateDouble = double.tryParse(tai) ?? 0.0;
    } else if (tai is double) {
      totalActualInterestToDateDouble = tai;
    }
    int totalOverdueDaysInt = 0;
    if (totalOverdueDays is String) {
      totalOverdueDaysInt = int.tryParse(totalOverdueDays) ?? 0;
    } else if (totalOverdueDays is int) {
      totalOverdueDaysInt = totalOverdueDays;
    }

    int paymentTermDaysInt = 0;
    if (paymentTermDays is String) {
      paymentTermDaysInt = int.tryParse(paymentTermDays) ?? 0;
    } else if (paymentTermDays is int) {
      paymentTermDaysInt = paymentTermDays;
    }
    double interestRateDouble = 0.0;
    if (interestRate is String) {
      interestRateDouble = double.tryParse(interestRate) ?? 0.0;
    } else if (interestRate is double) {
      interestRateDouble = interestRate;
    }

    int? daysInCycleInt;
    if (daysInCycle is String) {
      daysInCycleInt = int.tryParse(daysInCycle) ?? 0;
    } else if (daysInCycle is int) {
      daysInCycleInt = daysInCycle;
    }
    assert(daysInCycleInt != null && daysInCycleInt > 0,
        'Days in cycle should be greater than 0 for bill $billLabel');

    Widget outstandingBillWidget = Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor, width: 1),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('Bill ID: $billId'),
          Row(
            children: [
              Icon(Symbols.request_quote,
                  size: 16, color: Theme.of(context).colorScheme.error),
              horizontalSpaceTiny,
              Text(
                billLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text('Bill Date: ${billDate.substring(0, 10)}'),
          Text('Payment Term: $paymentTermDaysInt days'),
          Text('Due Date: ${dueDate.substring(0, 10)}'),
          Text('Total Overdue Days: $totalOverdueDaysInt'),
          Text('Interest Rate: ${interestRateDouble.toStringAsFixed(3)}%'),
          Text(
              'Cycle Start Date: ${cycleStartDateTimestamp.toString().substring(0, 10)}'),
          Text(
              'Cycle End Date: ${cycleEndDateTimestamp.toString().substring(0, 10)}'),
          Text('Days in Cycle: $daysInCycleInt days'),

          Text(
              'Billed Total Amount: SGD${getCommaNumberStr(billedTotalAmountDouble, decimal: 2)}'),
          Text('TTI Days of This Cycle: ${ttiDaysInt ?? '-'} days'),
          Text(
              'TTI of This Cycle: SGD${getCommaNumberStr(totalTheoreticalInterestToDateDouble, decimal: 2)}'),
          verticalSpaceTiny,
          getPaymentApplyList(paymentApplyListCasted, context),
          Text(
              'TAI of This Cycle: SGD${getCommaNumberStr(totalActualInterestToDateDouble, decimal: 2)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
    billWidgets.add(outstandingBillWidget);
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (totalInterestAmount != null)
      Row(
        children: [
          SizedBox(
            width: 210,
            child: Text(
              'Interest',
              style: defStatStyle,
            ),
          ),
          horizontalSpaceSmall,
          getStatWithUnit(
            getCommaNumberStr(totalInterestAmountDouble, decimal: 2),
            'SGD',
            statStrStyle: defStatStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
            ),
          ),
          IconButton(
              onPressed: () {
                onCheckDetail?.call();
              },
              icon: const Icon(Symbols.info))
        ],
      ),
    // verticalSpaceSmall,
    if (showInterestDetail) ...billWidgets,
  ]);
}

Widget getPaymentApplyList(
    List<Map<String, dynamic>> paymentApplyList, BuildContext context) {
  List<Widget> paymentWidgets = [];
  for (var payment in paymentApplyList) {
    // final paymentId = payment['payment_id'];
    final appliedUsageAmountFromBal = payment['usage_amount_from_bal'];
    final appliedInterestAmountFromBal = payment['interest_amount_from_bal'];
    final appliedUsageAmountFromPayment = payment['usage_amount_from_payment'];
    final appliedInterestAmountFromPayment =
        payment['interest_amount_from_payment'];
    final valueTimestamp = payment['value_timestamp'];
    final reducedBilledUsageFromThisApply =
        payment['reduced_billed_usage_from_this_apply'];
    // final overdueDays = payment['overdue_days'];
    final paymentTillCycleEndDays = payment['payment_till_cycle_end_days'];
    final rieFromThisApply = payment['rie_from_this_apply'];

    double appliedUsageAmountFromBalDouble = 0.0;
    if (appliedUsageAmountFromBal is String) {
      appliedUsageAmountFromBalDouble =
          double.tryParse(appliedUsageAmountFromBal) ?? 0.0;
    } else if (appliedUsageAmountFromBal is double) {
      appliedUsageAmountFromBalDouble = appliedUsageAmountFromBal;
    }
    double appliedInterestAmountFromBalDouble = 0.0;
    if (appliedInterestAmountFromBal is String) {
      appliedInterestAmountFromBalDouble =
          double.tryParse(appliedInterestAmountFromBal) ?? 0.0;
    } else if (appliedInterestAmountFromBal is double) {
      appliedInterestAmountFromBalDouble = appliedInterestAmountFromBal;
    }
    double appliedUsageAmountFromPaymentDouble = 0.0;
    if (appliedUsageAmountFromPayment is String) {
      appliedUsageAmountFromPaymentDouble =
          double.tryParse(appliedUsageAmountFromPayment) ?? 0.0;
    } else if (appliedUsageAmountFromPayment is double) {
      appliedUsageAmountFromPaymentDouble = appliedUsageAmountFromPayment;
    }
    double appliedInterestAmountFromPaymentDouble = 0.0;
    if (appliedInterestAmountFromPayment is String) {
      appliedInterestAmountFromPaymentDouble =
          double.tryParse(appliedInterestAmountFromPayment) ?? 0.0;
    } else if (appliedInterestAmountFromPayment is double) {
      appliedInterestAmountFromPaymentDouble = appliedInterestAmountFromPayment;
    }
    double reducedBilledUsageFromThisApplyDouble = 0.0;
    if (reducedBilledUsageFromThisApply is String) {
      reducedBilledUsageFromThisApplyDouble =
          double.tryParse(reducedBilledUsageFromThisApply) ?? 0.0;
    } else if (reducedBilledUsageFromThisApply is double) {
      reducedBilledUsageFromThisApplyDouble = reducedBilledUsageFromThisApply;
    }
    // int overdueDaysInt = 0;
    // if (overdueDays is String) {
    //   overdueDaysInt = int.tryParse(overdueDays) ?? 0;
    // } else if (overdueDays is int) {
    //   overdueDaysInt = overdueDays;
    // }
    int paymentTillCycleEndDaysInt = 0;
    if (paymentTillCycleEndDays is String) {
      paymentTillCycleEndDaysInt = int.tryParse(paymentTillCycleEndDays) ?? 0;
    } else if (paymentTillCycleEndDays is int) {
      paymentTillCycleEndDaysInt = paymentTillCycleEndDays;
    }
    double rieFromThisApplyDouble = 0.0;
    if (rieFromThisApply is String) {
      rieFromThisApplyDouble = double.tryParse(rieFromThisApply) ?? 0.0;
    } else if (rieFromThisApply is double) {
      rieFromThisApplyDouble = rieFromThisApply;
    }

    Widget paymentWidget = Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor, width: 1),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Date: ${valueTimestamp.substring(0, 10)}'),
          Row(
            children: [
              Icon(Symbols.attach_money,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              const Text(
                'Payment Apply:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (appliedUsageAmountFromBalDouble.abs() > 0.00001)
            Text(
                ' - SGD${getCommaNumberStr(appliedUsageAmountFromBalDouble, decimal: 2)} applied to Usage from Balance B/F'),
          if (appliedInterestAmountFromBalDouble.abs() > 0.00001)
            Text(
                ' - SGD${getCommaNumberStr(appliedInterestAmountFromBalDouble, decimal: 2)} applied to Interest from Balance B/F'),
          if (appliedUsageAmountFromPaymentDouble.abs() > 0.00001)
            Text(
                ' - SGD${getCommaNumberStr(appliedUsageAmountFromPaymentDouble, decimal: 2)} applied to Usage from Payment'),
          if (appliedInterestAmountFromPaymentDouble.abs() > 0.00001)
            Text(
                ' - SGD${getCommaNumberStr(appliedInterestAmountFromPaymentDouble, decimal: 2)} applied to Interest from Payment'),
          if (reducedBilledUsageFromThisApplyDouble.abs() > 0.00001)
            Text(
                ' - SGD${getCommaNumberStr(reducedBilledUsageFromThisApplyDouble, decimal: 2)} reduced Billed Usage from this Apply'),
          // Text(' - Overdue Days at Payment: $overdueDaysInt days'),
          Text(
              ' - Payment Till Cycle End Days: $paymentTillCycleEndDaysInt days'),
          if (rieFromThisApplyDouble.abs() > 0.00001)
            Text(
                ' - SGD${getCommaNumberStr(rieFromThisApplyDouble, decimal: 2)} RIE from this Apply',
                style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
    paymentWidgets.add(paymentWidget);
  }
  return Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: paymentWidgets);
}

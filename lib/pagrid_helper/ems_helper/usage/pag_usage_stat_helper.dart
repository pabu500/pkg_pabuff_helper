import 'package:buff_helper/pagrid_helper/ems_helper/usage/usage_stat_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/up_helper/helper/tenant_def.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../pag_helper/def_helper/dh_pag_finance.dart';
import '../../../pag_helper/model/mdl_history.dart';
import '../../../pag_helper/model/mdl_pag_app_config.dart';
import '../../../up_helper/helper/pag_meter_type_helper.dart';
import 'wgt_pag_meter_stat_core.dart';

Widget getPagTypeUsageStat(
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

Widget getPagUsageTitle(
  BuildContext context,
  DateTime fromDatetime,
  DateTime toDatetime,
  bool isMonthly,
  String? tenantLabel,
  String tenantName,
  String? tenantAccountId,
  bool isBillMode,
  String cycleStr,
  String billDate,
) {
  // String rangeStr = getTimeRangeStr(
  //   fromDatetime,
  //   toDatetime,
  //   targetInterval: isMonthly ? 'monthly' : 'daily',
  //   useMiddle: isMonthly ? true : false,
  // );
  if (isBillMode) {
    assert(cycleStr.isNotEmpty, 'CycleStr is empty');
    assert(billDate.isNotEmpty, 'BillDate is empty');
  }

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
          if (isBillMode)
            Row(
              children: [
                Text(
                  cycleStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                horizontalSpaceRegular,
                Text(
                  'Bill Date: ${billDate.substring(0, 10)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Widget getPagUsageTypeTopStat(
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
    color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
  );
  return Row(
    children: [
      if (netUsageE != null)
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            children: [
              getPagMeterTypeWidget(MeterType.electricity1p, context),
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
              getPagMeterTypeWidget(MeterType.btu, context,
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
              getPagMeterTypeWidget(MeterType.water, context),
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
              getPagMeterTypeWidget(MeterType.newater, context),
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
              getPagMeterTypeWidget(MeterType.gas, context),
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

Widget getPagTypeUsageNet(
  BuildContext context,
  MdlPagUser loggedInUser,
  MdlPagAppConfig appConfig,
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
          child: WgtPagUsageStatCore(
            loggedInUser: loggedInUser,
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
            historyType: PagItemHistoryType.meterListUsageSummary,
            isStaticUsageStat: true,
            meterUsageSummary: {'usage': netUsageE},
          ),
        ),
      if (netUsageB != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtPagUsageStatCore(
            loggedInUser: loggedInUser,
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
            historyType: PagItemHistoryType.meterListUsageSummary,
            isStaticUsageStat: true,
            meterUsageSummary: {'usage': netUsageB},
          ),
        ),
      if (netUsageW != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtPagUsageStatCore(
            loggedInUser: loggedInUser,
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
            historyType: PagItemHistoryType.meterListUsageSummary,
            isStaticUsageStat: true,
            meterUsageSummary: {'usage': netUsageW},
          ),
        ),
      if (netUsageN != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtPagUsageStatCore(
            loggedInUser: loggedInUser,
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
            historyType: PagItemHistoryType.meterListUsageSummary,
            isStaticUsageStat: true,
            meterUsageSummary: {'usage': netUsageN},
          ),
        ),
      if (netUsageG != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: WgtPagUsageStatCore(
            loggedInUser: loggedInUser,
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
            historyType: PagItemHistoryType.meterListUsageSummary,
            isStaticUsageStat: true,
            meterUsageSummary: {'usage': netUsageG},
          ),
        ),
    ]),
  );
}

// Widget getPagTotal(
//     BuildContext context,
//     double? costE,
//     double? costW,
//     double? costB,
//     double? costN,
//     double? costG,
//     double? costLineItems,
//     double gst,
//     String tenantType,
//     {double width = 750.0}) {
//   double? totalCost;
//   if (costE != null) {
//     totalCost = (totalCost ?? 0) + costE;
//   }
//   if (costW != null) {
//     totalCost = (totalCost ?? 0) + costW;
//   }
//   if (costB != null) {
//     totalCost = (totalCost ?? 0) + costB;
//   }
//   if (costN != null) {
//     totalCost = (totalCost ?? 0) + costN;
//   }
//   if (costG != null) {
//     totalCost = (totalCost ?? 0) + costG;
//   }
//   if (costLineItems != null) {
//     totalCost = (totalCost ?? 0) + costLineItems;
//   }
//   double? subTotalAmt = totalCost;
//   if (subTotalAmt != null) {
//     // subTotalAmt = getRoundUp(subTotalAmt, 2);
//     // subTotalAmt = getRound(subTotalAmt, 2);
//   }
//   double? totalAmt = subTotalAmt;
//   bool applyGst = false;
//   double? gstAmt;
//   if (TenantType.cw_nus_internal != getTenantType(tenantType)) {
//     applyGst = true;
//     if (subTotalAmt != null && gst != null) {
//       subTotalAmt = getRound(subTotalAmt, 2);
//       gstAmt = subTotalAmt * gst / 100;
//       gstAmt = getRoundUp(gstAmt, 2);
//       // total = subTotal + subTotal * (gst / 100);
//       totalAmt = subTotalAmt + gstAmt;
//     }
//   } else {
//     applyGst = false;
//     if (subTotalAmt != null) {
//       totalAmt = getRoundUp(subTotalAmt, 2);
//     }
//   }
//   return Container(
//     width: width,
//     // height: 80,
//     padding: const EdgeInsets.symmetric(horizontal: 21),
//     // constraints: const BoxConstraints(maxHeight: 130),
//     decoration: BoxDecoration(
//       border:
//           Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
//       borderRadius: BorderRadius.circular(5.0),
//     ),
//     child: Column(
//       children: [
//         if (applyGst)
//           Padding(
//             padding: const EdgeInsets.only(top: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: 210,
//                   child: Text(
//                     'Sub Total',
//                     style: defStatStyle,
//                   ),
//                 ),
//                 horizontalSpaceSmall,
//                 getStatWithUnit(
//                   getCommaNumberStr(subTotalAmt, decimal: 2),
//                   'SGD',
//                   statStrStyle: defStatStyle.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withOpacity(0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         if (applyGst)
//           Padding(
//             padding: const EdgeInsets.only(top: 5),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: 210,
//                   child: Text(
//                     'GST ($gst%)',
//                     style: defStatStyle,
//                   ),
//                 ),
//                 horizontalSpaceSmall,
//                 getStatWithUnit(
//                   // getCommaNumberStr(subTotal * (gst / 100), decimal: 2),
//                   getCommaNumberStr(gstAmt, decimal: 2),
//                   'SGD',
//                   statStrStyle: defStatStyle.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withOpacity(0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.only(top: 5),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               SizedBox(
//                 width: 210,
//                 child: Text(
//                   'Total',
//                   style: defStatStyleLarge.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withOpacity(0.7),
//                   ),
//                 ),
//               ),
//               horizontalSpaceSmall,
//               getStatWithUnit(
//                 // getCommaNumberStr(total, decimal: 2),
//                 getCommaNumberStr(totalAmt, decimal: 2, isRoundUp: false),
//                 'SGD',
//                 statStrStyle: defStatStyleLarge.copyWith(
//                   color:
//                       Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget getPagTotal2(BuildContext context, double gst, double? subTotalAmt,
//     double? gstAmt, double? totalAmt, String tenantType,
//     {double width = 750.0}) {
//   bool applyGst = tenantType != 'cw_nus_internal';

//   return Container(
//     width: width,
//     // height: 80,
//     padding: const EdgeInsets.symmetric(horizontal: 21),
//     // constraints: const BoxConstraints(maxHeight: 130),
//     decoration: BoxDecoration(
//       border:
//           Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
//       borderRadius: BorderRadius.circular(5.0),
//     ),
//     child: Column(
//       children: [
//         if (applyGst)
//           Padding(
//             padding: const EdgeInsets.only(top: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: 210,
//                   child: Text(
//                     'Sub Total',
//                     style: defStatStyle,
//                   ),
//                 ),
//                 horizontalSpaceSmall,
//                 getStatWithUnit(
//                   getCommaNumberStr(subTotalAmt, decimal: 2),
//                   'SGD',
//                   statStrStyle: defStatStyle.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withOpacity(0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         if (applyGst)
//           Padding(
//             padding: const EdgeInsets.only(top: 5),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: 210,
//                   child: Text(
//                     'GST ($gst%)',
//                     style: defStatStyle,
//                   ),
//                 ),
//                 horizontalSpaceSmall,
//                 getStatWithUnit(
//                   // getCommaNumberStr(subTotal * (gst / 100), decimal: 2),
//                   getCommaNumberStr(gstAmt, decimal: 2),
//                   'SGD',
//                   statStrStyle: defStatStyle.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withOpacity(0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.only(top: 5),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               SizedBox(
//                 width: 210,
//                 child: Text(
//                   'Total',
//                   style: defStatStyleLarge.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withOpacity(0.7),
//                   ),
//                 ),
//               ),
//               horizontalSpaceSmall,
//               getStatWithUnit(
//                 applyGst
//                     ? getCommaNumberStr(totalAmt, decimal: 2, isRoundUp: false)
//                     : getCommaNumberStr(subTotalAmt,
//                         decimal: 2, isRoundUp: false),
//                 'SGD',
//                 statStrStyle: defStatStyleLarge.copyWith(
//                   color:
//                       Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

Widget getPagTotal(
    BuildContext context,
    double gst,
    double? subTotalAmt,
    double? gstAmt,
    double? totalAmt,
    double? payableAmt,
    String tenantType,
    // List<Map<String, dynamic>>? miniSoa,
    Map<String, dynamic>? miniSoaInfo,
    String strCollectionStartDateTimestamp,
    String strCollectionEndDateTimestamp,
    Map<String, dynamic> interestInfo,
    {Function? onCheckInterestDetail,
    bool showInterestDetail = false,
    double width = 750.0}) {
  bool applyGst = tenantType != 'cw_nus_internal';

  double contentWidth = 235;

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
        getMiniSoA(
          miniSoaInfo ?? {},
          strCollectionStartDateTimestamp,
          strCollectionEndDateTimestamp,
          context,
          contentWidth,
        ),
        const Divider(height: 21),
        if (applyGst)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: contentWidth,
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
                  width: contentWidth,
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
                width: contentWidth,
                child: Text(
                  'Current Total',
                  style: defStatStyle.copyWith(
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
                statStrStyle: defStatStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 21),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              getInterestInfo(
                interestInfo,
                context,
                showInterestDetail,
                contentWidth,
                onCheckInterestDetail,
              )
            ],
          ),
        ),
        const Divider(height: 21),
        if (payableAmt != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: contentWidth,
                  child: Text(
                    'Total Payable',
                    style: defStatStyleLarge.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(210),
                    ),
                  ),
                ),
                horizontalSpaceSmall,
                getStatWithUnit(
                  getCommaNumberStr(payableAmt, decimal: 2, isRoundUp: false),
                  'SGD',
                  statStrStyle: defStatStyleLarge.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget getMiniSoA(
    Map<String, dynamic> miniSoaInfo,
    String strCollectionStartDateTimestamp,
    String strCollectionEndDateTimestamp,
    BuildContext context,
    double contentWidth) {
  if (miniSoaInfo.isEmpty) {
    return Container();
  }
  // get last item to get the balance brought forward
  dynamic balBf = miniSoaInfo['opening_balance'];
  if (balBf is String) {
    balBf = double.tryParse(balBf) ?? 0.0;
  } else if (balBf is double) {
    balBf = balBf;
  } else {
    balBf = 0.0;
  }
  if (balBf.abs() < 0.00001) {
  } else {
    balBf = -1 * balBf;
  }

  List<Map<String, dynamic>> paymentList = [];
  for (var paymentInfo in miniSoaInfo['payment_list'] ?? []) {
    // String? creditRemark = item['credit_remark'];
    // if ('initial_balance' == (creditRemark ?? '').toString().toLowerCase()) {
    //   continue;
    // }
    String? itemType = paymentInfo['entry_type'];

    // do not include initial balance payment (CPE-66)
    String? paymentType = paymentInfo['payment_type'] ?? 'normal';
    if ('initial_balance' == paymentType) {
      continue;
    }
    if (itemType != null && itemType == 'payment') {
      dynamic creditAmount = paymentInfo['credit_amount'];
      if (creditAmount is String) {
        creditAmount = double.tryParse(creditAmount) ?? 0.0;
      } else if (creditAmount is double) {
        creditAmount = creditAmount;
      } else {
        creditAmount = 0.0;
      }
      String dateStr = paymentInfo['entry_timestamp'];
      if (dateStr.isNotEmpty) {
        //get date only
        dateStr = dateStr.substring(0, 10);
      }
      paymentList.add({
        ...paymentInfo,
        'amount': creditAmount,
        'payment_date': dateStr,
        'payment_type': paymentType,
      });
    }
  }

  dynamic balCf = miniSoaInfo['closing_balance'];
  if (balCf is String) {
    balCf = double.tryParse(balCf) ?? 0.0;
  } else if (balCf is double) {
    balCf = balCf;
  } else {
    balCf = 0.0;
  }
  if (balCf.abs() < 0.00001) {
  } else {
    balCf = -1 * balCf;
  }

  assert(strCollectionStartDateTimestamp.isNotEmpty);
  assert(strCollectionEndDateTimestamp.isNotEmpty);

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: contentWidth,
              child: Text(
                'Bal. B/F',
                style: defStatStyle,
              ),
            ),
            horizontalSpaceSmall,
            getStatWithUnit(
              getCommaNumberStr(balBf, decimal: 2),
              'SGD',
              statStrStyle: defStatStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
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
              width: contentWidth,
              child: Text(
                'Collection Date Start:',
                style: defStatStyle,
              ),
            ),
            horizontalSpaceSmall,
            Text(
              strCollectionStartDateTimestamp.substring(0, 10),
              style: defStatStyle,
            ),
          ],
        ),
      ),
      for (var pay in paymentList)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: contentWidth,
                child: Text(
                  'Payment (${pay['payment_date'] ?? ''})',
                  style: defStatStyle,
                ),
              ),
              horizontalSpaceSmall,
              getStatWithUnit(
                getCommaNumberStr(-(pay['amount'] ?? 0.0), decimal: 2),
                'SGD',
                statStrStyle: defStatStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
                ),
              ),
              if (pay['payment_type'] == 'initial_balance')
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: getPaymentSoaTypeTagWidget(
                    context,
                    PaymentSoaType.initialBalance,
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
              width: contentWidth,
              child: Text('Collection Date To:', style: defStatStyle),
            ),
            horizontalSpaceSmall,
            Text(
              strCollectionEndDateTimestamp.substring(0, 10),
              style: defStatStyle,
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
              width: contentWidth,
              child: Text(
                'Bal. C/F',
                style: defStatStyle,
              ),
            ),
            horizontalSpaceSmall,
            getStatWithUnit(
              getCommaNumberStr(balCf, decimal: 2),
              'SGD',
              statStrStyle: defStatStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget getPagAutoUsageExcludedInfo(BuildContext context, {double width = 750}) {
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

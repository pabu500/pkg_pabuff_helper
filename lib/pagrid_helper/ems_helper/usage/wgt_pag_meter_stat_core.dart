import 'package:buff_helper/up_helper/up_helper.dart';
import 'package:buff_helper/util/string_util.dart';
import 'package:buff_helper/xt_ui/xt_ui.dart';
import 'package:flutter/material.dart';

import '../../../pag_helper/def_helper/pag_item_helper.dart';
import '../../../pag_helper/model/mdl_history.dart';
import '../../../pag_helper/model/mdl_pag_app_config.dart';
import '../../../pag_helper/model/mdl_pag_user.dart';
import '../../../pag_helper/wgt/history_presentor/wgt_pag_item_history_presenter.dart';

class WgtPagUsageStatCore extends StatefulWidget {
  const WgtPagUsageStatCore({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.displayContextStr,
    this.noData = false,
    required this.meterType,
    required this.meterId,
    required this.meterIdType,
    required this.itemType,
    required this.historyType,
    required this.meterUsageSummary,
    this.statColor,
    this.isMonthly = true,
    this.showTrending = true,
    this.statVirticalStack = true,
    this.height,
    this.isBillMode = false,
    this.rate,
    this.isStaticUsageStat = false,
    this.isSubstractUsage = false,
    this.showRate = true,
    this.calcUsageFromReadings = true,
    this.usageDecimals = 3,
    this.rateDecimals = 5,
    this.costDecimals = 3,
    this.showFactoredUsage = true,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final String displayContextStr;
  final bool noData;
  final MeterType meterType;
  final String meterId;
  final ItemIdType meterIdType;
  final ItemType itemType;
  final PagItemHistoryType historyType;
  final Map<String, dynamic> meterUsageSummary;
  final bool isMonthly;
  final Color? statColor;
  final bool showTrending;
  final int usageDecimals;
  final int rateDecimals;
  final int costDecimals;
  final bool statVirticalStack;
  final double? height;
  final bool isBillMode;
  final double? rate;
  final bool isStaticUsageStat;
  final bool isSubstractUsage;
  final bool showRate;
  final bool calcUsageFromReadings;
  final bool showFactoredUsage;

  @override
  State<WgtPagUsageStatCore> createState() => _WgtPagUsageStatCoreState();
}

class _WgtPagUsageStatCoreState extends State<WgtPagUsageStatCore> {
  final totalWidth = 185.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      // if put constraints here, the height will grow to the max height
      // constraints: BoxConstraints(
      //   maxHeight: widget.height ?? 220,
      // ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade600, width: 1),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: widget.noData
            ? Center(
                child: Text(
                  'No Data',
                  style: TextStyle(
                    fontSize: 21,
                    color: Theme.of(context).hintColor.withAlpha(80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : widget.statVirticalStack
                ? Column(
                    children: [
                      Row(
                        children: [
                          getDeviceTypeIcon(widget.meterType,
                              iconSize: 21,
                              iconColor:
                                  widget.statColor ?? Colors.grey.shade800),
                          // horizontalSpaceTiny,
                          Text(
                            widget.meterId,
                            style: TextStyle(
                              fontSize: 18,
                              color: widget.statColor ?? Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      verticalSpaceTiny,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getStat(),
                          if (widget.showTrending)
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: getTrending(),
                            ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: Row(
                            children: [
                              getDeviceTypeIcon(widget.meterType,
                                  iconSize: 21,
                                  iconColor:
                                      widget.statColor ?? Colors.grey.shade800),
                              // horizontalSpaceTiny,
                              Text(
                                widget.meterId,
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      widget.statColor ?? Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      horizontalSpaceSmall,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.isStaticUsageStat
                              ? getStatStatic()
                              : getStat(),
                          if (widget.showTrending)
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: getTrending(),
                            ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget getStatStatic() {
    var usageFactoredObj = widget.meterUsageSummary['usage_factored'];
    var usageObj = widget.meterUsageSummary['usage'];
    if (usageFactoredObj is String) {
      usageFactoredObj = double.tryParse(usageFactoredObj);
    }
    if (usageObj is String) {
      usageObj = double.tryParse(usageObj);
    }
    double? usage = usageFactoredObj ?? usageObj;
    if (usage == null) {
      return getErrorTextPrompt(context: context, errorText: 'No usage data');
    }

    //factor is applied outside of this widget
    // double usageFactor = 1;
    // // getProjectMeterUsageFactor(_scopeProfile.selectedProjectScope, scopeProfiles, widget.meterType);
    // usage = usage * usageFactor;

    bool showRate = widget.isBillMode && widget.rate != null && widget.showRate;
    bool showCost = widget.isBillMode && widget.rate != null && widget.showRate;
    return widget.statVirticalStack
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: widget.statColor != null
                    ? defStatStyleSmall.copyWith(color: widget.statColor)
                    : defStatStyleSmall,
              ),
              getStatWithUnit(
                  getCommaNumberStr(usage, decimal: widget.usageDecimals),
                  getDeivceTypeUnit(widget.meterType,
                      displayContextStr: widget.displayContextStr),
                  statStrStyle: widget.statColor == null
                      ? defStatStyleLarge
                      : defStatStyleLarge.copyWith(color: widget.statColor),
                  unitStyle: defStatStyleSmall.copyWith(
                    color: widget.statColor ?? Colors.grey.shade800,
                  )),
              if (widget.showFactoredUsage &&
                  (widget.meterUsageSummary['factor'] ?? 1) < 0.999999)
                Text(
                  'Factor: ${(1 / widget.meterUsageSummary['factor']).toStringAsFixed(5)}',
                  style: defStatStyleSmall,
                ),
            ],
          )
        : Row(
            children: [
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${getDeivceTypeUnit(widget.meterType, displayContextStr: widget.displayContextStr)}',
                      style: defStatStyleSmall,
                    ),
                    getStatWithUnit(
                      widget.isSubstractUsage
                          ? '(${getCommaNumberStr(usage, decimal: widget.usageDecimals)})'
                          : getCommaNumberStr(usage,
                              decimal: widget.usageDecimals),
                      getDeivceTypeUnit(widget.meterType,
                          displayContextStr: widget.displayContextStr),
                      statStrStyle: widget.statColor == null
                          ? defStatStyleLarge
                          : defStatStyleLarge.copyWith(color: widget.statColor),
                      unitStyle: defStatStyleSmall.copyWith(
                        color: widget.statColor ?? Colors.grey.shade800,
                      ),
                      showUnit: false,
                    ),
                    if (widget.showFactoredUsage &&
                        (widget.meterUsageSummary['factor'] ?? 1) < 0.999999)
                      Text(
                        'Factor: ${(1 / widget.meterUsageSummary['factor']).toStringAsFixed(5)}',
                        style: defStatStyleSmall,
                      ),
                  ],
                ),
              ),
              if (showRate)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        getCommaNumberStr(widget.rate!,
                            decimal: widget.rateDecimals),
                        'SGD',
                        statStrStyle: widget.statColor == null
                            ? defStatStyle
                            : defStatStyle.copyWith(color: widget.statColor),
                        unitStyle: defStatStyleSmall.copyWith(
                          color: widget.statColor ?? Colors.grey.shade800,
                        ),
                        showUnit: true,
                      ),
                    ],
                  ),
                ),
              if (showCost)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        getCommaNumberStr(usage * widget.rate!,
                            decimal: widget.costDecimals),
                        'SGD',
                        statStrStyle: widget.statColor == null
                            ? defStatStyle
                            : defStatStyle.copyWith(color: widget.statColor),
                        unitStyle: defStatStyleSmall.copyWith(
                          color: widget.statColor ?? Colors.grey.shade800,
                        ),
                        showUnit: true,
                      ),
                    ],
                  ),
                ),
            ],
          );
  }

  Widget getStat() {
    var percentageObj = widget.meterUsageSummary['percentage'];
    double? percentage;
    if (percentageObj is String) {
      percentage = double.tryParse(percentageObj);
    } else {
      percentage = percentageObj;
    }
    bool showReading = percentage == null || percentage == 100.0;
    bool showPercentage =
        !widget.isBillMode && percentage != null && percentage != 100.0;
    bool showRate = widget.isBillMode && widget.rate != null;
    bool showCost = widget.isBillMode && widget.rate != null;

    double? firstReadingValue =
        double.tryParse(widget.meterUsageSummary['first_reading_value']);
    double? lastReadingValue =
        double.tryParse(widget.meterUsageSummary['last_reading_value']);

    double? usage;

    if (widget.calcUsageFromReadings) {
      usage = firstReadingValue == null || lastReadingValue == null
          ? null
          : lastReadingValue - firstReadingValue;
      if (percentage != null && usage != null) {
        usage = usage * (percentage / 100);
      }
    } else {
      var usageObj = widget.meterUsageSummary['usage'];
      if (usageObj is String) {
        usage = double.tryParse(usageObj);
      } else {
        usage = usageObj;
      }

      if (percentage != null && usage != null) {
        usage = usage * (percentage / 100);
      }
    }
    if (usage != null) {
      var usageFactorObj = widget.meterUsageSummary['factor'];
      double? usageFactor;
      if (usageFactorObj is String) {
        usageFactor = double.tryParse(usageFactorObj);
      } else {
        usageFactor = usageFactorObj;
      }

      if (widget.showFactoredUsage) {
        if (usageFactor == null) {
          throw Exception('usageFactor is null');
        }
      } else {
        usageFactor = 1;
      }
      usage = usage * usageFactor;
    }

    //only to minutes substring(0, 16)
    String firstReadingTime =
        widget.meterUsageSummary['first_reading_timestamp'] == null ||
                widget.meterUsageSummary['first_reading_timestamp'].length < 16
            ? '-'
            : (widget.meterUsageSummary['first_reading_timestamp'] as String)
                .substring(0, 16);
    String lastReadingTime =
        widget.meterUsageSummary['last_reading_timestamp'] == null ||
                widget.meterUsageSummary['last_reading_timestamp'].length < 16
            ? '-'
            : (widget.meterUsageSummary['last_reading_timestamp'] as String)
                .substring(0, 16);
    return widget.statVirticalStack
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: widget.statColor != null
                    ? defStatStyleSmall.copyWith(color: widget.statColor)
                    : defStatStyleSmall,
              ),
              getStatWithUnit(
                  getCommaNumberStr(usage, decimal: widget.usageDecimals),
                  getDeivceTypeUnit(widget.meterType,
                      displayContextStr: widget.displayContextStr),
                  statStrStyle: widget.statColor == null
                      ? defStatStyleLarge
                      : defStatStyleLarge.copyWith(color: widget.statColor),
                  unitStyle: defStatStyleSmall.copyWith(
                    color: widget.statColor ?? Colors.grey.shade800,
                  )),
              if (showReading)
                Text(
                  'last reading: $lastReadingTime',
                  style: defStatStyleSmall,
                ),
              if (showReading)
                //text with 'kwh' as supertext
                getStatWithUnit(
                  getCommaNumberStr(lastReadingValue,
                      decimal: widget.usageDecimals),
                  getDeivceTypeUnit(widget.meterType,
                      displayContextStr: widget.displayContextStr),
                ),
              if (showReading)
                Text(
                  'first reading: $firstReadingTime',
                  style: defStatStyleSmall,
                ),
              if (showReading)
                getStatWithUnit(
                  getCommaNumberStr(firstReadingValue,
                      decimal: widget.usageDecimals),
                  getDeivceTypeUnit(widget.meterType,
                      displayContextStr: widget.displayContextStr),
                ),
            ],
          )
        : Row(
            children: [
              SizedBox(
                width: totalWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${getDeivceTypeUnit(widget.meterType, displayContextStr: widget.displayContextStr)}',
                      style: defStatStyleSmall,
                    ),
                    getStatWithUnit(
                      getCommaNumberStr(usage, decimal: widget.usageDecimals),
                      getDeivceTypeUnit(widget.meterType,
                          displayContextStr: widget.displayContextStr),
                      statStrStyle: widget.statColor == null
                          ? defStatStyleLarge
                          : defStatStyleLarge.copyWith(color: widget.statColor),
                      unitStyle: defStatStyleSmall.copyWith(
                        color: widget.statColor ?? Colors.grey.shade800,
                      ),
                      showUnit: false,
                    ),
                    if (widget.showFactoredUsage &&
                        (widget.meterUsageSummary['factor'] ?? 1) < 0.999999)
                      Text(
                        'Factor: ${(1 / widget.meterUsageSummary['factor']).toStringAsFixed(5)}',
                        style: defStatStyleSmall,
                      ),
                  ],
                ),
              ),
              if (showReading)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'last reading: $lastReadingTime',
                        style: defStatStyleSmall,
                      ),
                      //text with 'kwh' as supertext
                      getStatWithUnit(
                        getCommaNumberStr(lastReadingValue,
                            decimal: widget.usageDecimals),
                        getDeivceTypeUnit(widget.meterType,
                            displayContextStr: widget.displayContextStr),
                      ),
                      Text(
                        'first reading: $firstReadingTime',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        getCommaNumberStr(firstReadingValue,
                            decimal: widget.usageDecimals),
                        getDeivceTypeUnit(widget.meterType,
                            displayContextStr: widget.displayContextStr),
                      ),
                    ],
                  ),
                ),
              if (showRate)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        getCommaNumberStr(widget.rate!,
                            decimal: widget.rateDecimals),
                        'SGD',
                        statStrStyle: widget.statColor == null
                            ? defStatStyle
                            : defStatStyle.copyWith(color: widget.statColor),
                        unitStyle: defStatStyleSmall.copyWith(
                          color: widget.statColor ?? Colors.grey.shade800,
                        ),
                        showUnit: true,
                      ),
                    ],
                  ),
                ),
              if (showPercentage)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Percentage',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        percentage.toStringAsFixed(3),
                        '%',
                        statStrStyle: widget.statColor == null
                            ? defStatStyle
                            : defStatStyle.copyWith(color: widget.statColor),
                        unitStyle: defStatStyleSmall.copyWith(
                          color: widget.statColor ?? Colors.grey.shade800,
                        ),
                        showUnit: true,
                      ),
                    ],
                  ),
                ),
              if (showCost)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        getCommaNumberStr(
                            usage == null ? null : usage * widget.rate!,
                            decimal: widget.costDecimals),
                        'SGD',
                        statStrStyle: widget.statColor == null
                            ? defStatStyle
                            : defStatStyle.copyWith(color: widget.statColor),
                        unitStyle: defStatStyleSmall.copyWith(
                          color: widget.statColor ?? Colors.grey.shade800,
                        ),
                        showUnit: true,
                      ),
                    ],
                  ),
                ),
            ],
          );
  }

  Widget getTrending() {
    DateTime firstReadingDate =
        DateTime.parse(widget.meterUsageSummary['first_reading_time']);
    DateTime lastReadingDate =
        DateTime.parse(widget.meterUsageSummary['last_reading_time']);
    double height = 170;
    double width = 460;
    double chartRatio = 1.3 * width / height;
    return WgtPagItemHistoryPresenter(
      loggedInUser: widget.loggedInUser,
      appConfig: widget.appConfig,
      itemKind: PagItemKind.device,
      itemSubType: widget.meterType,
      height: height,
      width: width,
      bgColor: Colors.transparent,
      borderColor: Colors.grey.shade500, // Colors.transparent,
      chartRatio: chartRatio,
      itemType: widget.itemType,
      itemId: widget.meterId,
      itemIdType: widget.meterIdType,
      historyType: widget.historyType,
      config: const ['chart_core'],
      useWidgetStartEndDate: true,
      startDate: firstReadingDate,
      endDate: lastReadingDate,
      showXTitles: false,
      showYTitles: false,
      reserveTooltipSpace: false,
      barColor: Colors.grey.shade700,
      chartBorder: Border.all(color: Colors.transparent),
    );
  }
}

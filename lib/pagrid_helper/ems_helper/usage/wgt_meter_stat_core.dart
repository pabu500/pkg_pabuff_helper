import 'package:buff_helper/up_helper/up_helper.dart';
import 'package:buff_helper/util/string_util.dart';
import 'package:buff_helper/xt_ui/xt_ui.dart';
import 'package:flutter/material.dart';

import '../../app_helper/pagrid_app_config.dart';
import '../../chart_helper/history_presentor/wgt_item_history_presenter.dart';

class WgtUsageStatCore extends StatefulWidget {
  const WgtUsageStatCore({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
    this.noData = false,
    required this.meterType,
    required this.meterId,
    required this.meterIdType,
    required this.itemType,
    required this.historyType,
    required this.meterStat,
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

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final PaGridAppConfig appConfig;
  final bool noData;
  final MeterType meterType;
  final String meterId;
  final ItemIdType meterIdType;
  final ItemType itemType;
  final Evs2HistoryType historyType;
  final Map<String, dynamic> meterStat;
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
  State<WgtUsageStatCore> createState() => _WgtUsageStatCoreState();
}

class _WgtUsageStatCoreState extends State<WgtUsageStatCore> {
  final totalWidth = 170.0;

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
                    color: Theme.of(context).hintColor.withOpacity(0.3),
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
                        width: 70,
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
    double usage = double.parse(
        widget.meterStat['usage_factored'] ?? widget.meterStat['usage']);

    //factor is applied outside of this widget
    double usageFactor = 1;
    // getProjectMeterUsageFactor(_scopeProfile.selectedProjectScope, scopeProfiles, widget.meterType);
    usage = usage * usageFactor;

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
                  getDeivceTypeUnit(widget.meterType),
                  statStrStyle: widget.statColor == null
                      ? defStatStyleLarge
                      : defStatStyleLarge.copyWith(color: widget.statColor),
                  unitStyle: defStatStyleSmall.copyWith(
                    color: widget.statColor ?? Colors.grey.shade800,
                  )),
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
                      'Total ${getDeivceTypeUnit(widget.meterType)}',
                      style: defStatStyleSmall,
                    ),
                    getStatWithUnit(
                      widget.isSubstractUsage
                          ? '(${getCommaNumberStr(usage, decimal: widget.usageDecimals)})'
                          : getCommaNumberStr(usage,
                              decimal: widget.usageDecimals),
                      getDeivceTypeUnit(widget.meterType),
                      statStrStyle: widget.statColor == null
                          ? defStatStyleLarge
                          : defStatStyleLarge.copyWith(color: widget.statColor),
                      unitStyle: defStatStyleSmall.copyWith(
                        color: widget.statColor ?? Colors.grey.shade800,
                      ),
                      showUnit: false,
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
    double? percentage = widget.meterStat['percentage'];
    bool showReading = percentage == null || percentage == 100.0;
    bool showPercentage =
        !widget.isBillMode && percentage != null && percentage != 100.0;
    bool showRate = widget.isBillMode && widget.rate != null;
    bool showCost = widget.isBillMode && widget.rate != null;

    double? firstReadingValue =
        double.tryParse(widget.meterStat['first_reading_val']);
    double? lastReadingValue =
        double.tryParse(widget.meterStat['last_reading_val']);

    double? usage;

    if (widget.calcUsageFromReadings) {
      usage = firstReadingValue == null || lastReadingValue == null
          ? null
          : lastReadingValue - firstReadingValue;
      if (percentage != null && usage != null) {
        usage = usage * (percentage / 100);
      }
    } else {
      usage = double.tryParse(widget.meterStat['usage']);
      if (percentage != null && usage != null) {
        usage = usage * (percentage / 100);
      }
    }
    if (usage != null) {
      double? usageFactor = widget.meterStat['factor'];

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
    String firstReadingTime = widget.meterStat['first_reading_time'] == null ||
            widget.meterStat['first_reading_time'].length < 16
        ? '-'
        : (widget.meterStat['first_reading_time'] as String).substring(0, 16);
    String lastReadingTime = widget.meterStat['last_reading_time'] == null ||
            widget.meterStat['last_reading_time'].length < 16
        ? '-'
        : (widget.meterStat['last_reading_time'] as String).substring(0, 16);
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
                  getDeivceTypeUnit(widget.meterType),
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
                  getDeivceTypeUnit(widget.meterType),
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
                  getDeivceTypeUnit(widget.meterType),
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
                      'Total ${getDeivceTypeUnit(widget.meterType)}',
                      style: defStatStyleSmall,
                    ),
                    getStatWithUnit(
                      getCommaNumberStr(usage, decimal: widget.usageDecimals),
                      getDeivceTypeUnit(widget.meterType),
                      statStrStyle: widget.statColor == null
                          ? defStatStyleLarge
                          : defStatStyleLarge.copyWith(color: widget.statColor),
                      unitStyle: defStatStyleSmall.copyWith(
                        color: widget.statColor ?? Colors.grey.shade800,
                      ),
                      showUnit: false,
                    ),
                    if (widget.showFactoredUsage &&
                        (widget.meterStat['factor'] ?? 1) < 0.999999)
                      Text(
                        'Factor: ${(1 / widget.meterStat['factor']).toStringAsFixed(5)}',
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
                        getDeivceTypeUnit(widget.meterType),
                      ),
                      Text(
                        'first reading: $firstReadingTime',
                        style: defStatStyleSmall,
                      ),
                      getStatWithUnit(
                        getCommaNumberStr(firstReadingValue,
                            decimal: widget.usageDecimals),
                        getDeivceTypeUnit(widget.meterType),
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
        DateTime.parse(widget.meterStat['first_reading_time']);
    DateTime lastReadingDate =
        DateTime.parse(widget.meterStat['last_reading_time']);
    double height = 170;
    double width = 460;
    double chartRatio = 1.3 * width / height;
    return WgtItemHistoryPresenter(
      loggedInUser: widget.loggedInUser,
      scopeProfile: widget.scopeProfile,
      appConfig: widget.appConfig,
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

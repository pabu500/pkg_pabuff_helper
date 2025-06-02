import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import '../../../pag_helper/model/acl/mdl_pag_svc_claim.dart';
import '../../../pag_helper/model/mdl_pag_app_config.dart';
import 'comm_pag_meter_usage.dart';

class WgtPagMeterGroupStatCore extends StatefulWidget {
  const WgtPagMeterGroupStatCore({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.displayContextStr,
    this.noData = false,
    this.chartKey,
    required this.itemType,
    required this.meterIdFieldKey,
    required this.meterIdType,
    required this.meterType,
    required this.groupId,
    // required this.groupStat,
    required this.selectedMeterStat,
    this.isMonthly = true,
    this.startDateTime,
    this.endDateTime,
    this.decimals = 0,
    this.statColor,
    this.isBillMode = false,
    this.rate,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final String displayContextStr;
  final bool noData;
  final UniqueKey? chartKey;
  final ItemType itemType;
  final String meterIdFieldKey;
  final String groupId;
  // final Map<String, dynamic> groupStat;
  final ItemIdType meterIdType;
  final MeterType meterType;
  final List<Map<String, dynamic>> selectedMeterStat;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isMonthly;
  final int decimals;
  final Color? statColor;
  final bool isBillMode;
  final double? rate;

  @override
  State<WgtPagMeterGroupStatCore> createState() =>
      _WgtPagMeterGroupStatCoreState();
}

class _WgtPagMeterGroupStatCoreState extends State<WgtPagMeterGroupStatCore> {
  late DateTime _lastLoadingTime;
  DateTime? _lastRequestTime;

  // final ScreenshotController _screenshotController = ScreenshotController();

  bool _isItemListLoading = false;
  String _emptyResultText = '';
  double _groupTotalUsage = 0;

  final List<Map<String, dynamic>> _pieStat = [];

  final List<Map<String, dynamic>> _monthlyConsumption = [];
  final List<FlSpot> _chartData = [];
  UniqueKey _chartKey = UniqueKey();

  Future<void> _getMeterUsageSummary() async {
    // await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _isItemListLoading = true;
    });
    _lastRequestTime = DateTime.now();

    List<String> itemIds = [];
    for (var meterStat in widget.selectedMeterStat) {
      itemIds.add(meterStat[widget.meterIdFieldKey]);
    }
    try {
      Map<String, dynamic> result = {};
      List<Map<String, dynamic>> usageHistory = [];
      _emptyResultText = '';

      Duration duration = const Duration(days: 150);
      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'end_datetime': widget.endDateTime == null
            ? getLocalDatetimeNowStr(
                widget.loggedInUser.selectedScope.getProjectTimezone())
            : widget.endDateTime.toString(),
        'target_interval': 'month',
        'num_of_intervals': '6',
        'item_id_type': widget.meterIdType.name,
        'item_id_list': itemIds.join(','),
        'item_type': widget.itemType.name,
        'group_name': widget.groupId,
      };
      if (kDebugMode) {
        print('_getMeterConsumptionSummary pulling data');
      }
      result = await queryPagMeterConsolidatedUsageHistory(
        widget.appConfig,
        queryMap,
        duration,
        MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: AclScope.global.name,
          target: getAclTargetStr(AclTarget.meter_p_consumption),
          operation: AclOperation.read.name,
        ),
      );
      usageHistory =
          result[Evs2HistoryType.meter_list_consolidated_usage_history.name]
              as List<Map<String, dynamic>>;

      List<Map<String, dynamic>> conlidatedHistoryList = [];
      for (var meterHistory in usageHistory) {
        String meterId = meterHistory['meter_id'];
        String meterIdType = meterHistory['meter_id_type'];
        String interval = meterHistory['interval'];

        if (meterHistory['history'].isEmpty) {
          _emptyResultText =
              'Empty result for $meterId for the $duration period';
          if (kDebugMode) {
            print(_emptyResultText);
          }
          continue;
        }

        for (var history in meterHistory['history']) {
          String consolidatedTimeLabel = history['consolidated_time_label'];
          double? usage = double.tryParse(history['usage']);

          //check if the time label is already in the list
          bool isExist = false;
          for (var item in conlidatedHistoryList) {
            if (item['time'] == consolidatedTimeLabel) {
              isExist = true;
              break;
            }
          }
          if (!isExist) {
            conlidatedHistoryList.add({
              'time': consolidatedTimeLabel,
              'label': consolidatedTimeLabel,
              'value': usage,
            });
          } else {
            //add the consumption to the existing time label
            for (var item in conlidatedHistoryList) {
              if (item['time'] == consolidatedTimeLabel) {
                item['value'] += usage ?? 0;
                break;
              }
            }
          }
        }
      }

      _chartData.clear();
      for (var item in conlidatedHistoryList) {
        _chartData.add(
          FlSpot(
            conlidatedHistoryList.indexOf(item).toDouble(),
            item['value'] as double,
          ),
        );
      }

      // setState(() {
      _monthlyConsumption.clear();
      _monthlyConsumption.addAll(conlidatedHistoryList);
      // });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains('No transaction')) {
        _emptyResultText = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      setState(() {
        _isItemListLoading = false;
      });
    }
  }

  void _genSeletedMeterStat() {
    if (widget.noData) {
      return;
    }
    _groupTotalUsage = 0;
    _pieStat.clear();
    for (var meterStat in widget.selectedMeterStat) {
      double usage = 0;
      if (meterStat['percentage'] != null && meterStat['usage'] != null) {
        usage =
            meterStat['percentage'] * double.parse(meterStat['usage']) / 100;
      } else {
        double firstReading = double.parse(meterStat['first_reading_val']);
        double lastReading = double.parse(meterStat['last_reading_val']);
        usage = lastReading - firstReading;
      }
      _groupTotalUsage += usage;
      _pieStat.add({
        'label': meterStat[widget.meterIdFieldKey],
        'value': usage,
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _lastLoadingTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    _genSeletedMeterStat();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      constraints: const BoxConstraints(
        maxHeight: 250,
      ),
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
                    color: Theme.of(context).hintColor.withAlpha(80),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Text(
                        widget.groupId,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.statColor ?? Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      getStat(),
                      horizontalSpaceSmall,
                      // Screenshot(controller: _screenshotController, child: getPie()),
                      getPie(),
                      horizontalSpaceSmall,
                      getTrending(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget getStat() {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              getDeviceTypeIcon(widget.meterType,
                  iconSize: 15, iconColor: Colors.grey.shade600),
              Text(
                'Group Total',
                style: defStatStyleSmall,
              ),
            ],
          ),
          getStatWithUnit(
            getCommaNumberStr(_groupTotalUsage, decimal: widget.decimals),
            statStrStyle: widget.statColor == null
                ? defStatStyleLarge
                : defStatStyleLarge.copyWith(color: widget.statColor),
            unitStyle: defStatStyleSmall.copyWith(
                color: widget.statColor ?? Colors.grey.shade800),
            getDeivceTypeUnit(widget.meterType,
                displayContextStr: widget.displayContextStr),
          ),
          Expanded(
            child: Container(),
          )
        ],
      ),
    );
  }

  Widget getTrending() {
    bool pullData = canPullData2(_monthlyConsumption.isNotEmpty,
        _lastRequestTime, 500, _lastLoadingTime, 2000);
    bool extKeyUpdated = false;
    if (widget.chartKey != null) {
      if (widget.chartKey != _chartKey) {
        pullData = true;
        _chartKey = widget.chartKey!;
        _emptyResultText = '';
        extKeyUpdated = true;
      }
    }
    //has the same data, no need to pull data
    if (_monthlyConsumption.isNotEmpty && !extKeyUpdated) {
      pullData = false;
    }
    double height = 210;
    double width = 270;
    return SizedBox(
      height: height,
      width: width,
      child: _emptyResultText.isNotEmpty &&
              !_isItemListLoading &&
              !extKeyUpdated
          ? Container()
          : pullData
              ? FutureBuilder<void>(
                  future: _getMeterUsageSummary(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                          height: height,
                          width: width,
                          child: Center(
                            child: xtWait(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ));
                    } else if (snapshot.hasError) {
                      if (kDebugMode) {
                        print(snapshot.error);
                      }
                      return const Text('Eorr getting data');
                    } else {
                      return getCompletedChart(height, width);
                    }
                  },
                )
              : getCompletedChart(height, width),
    );
  }

  Widget getCompletedChart(double height, double width) {
    return _isItemListLoading
        ? Center(
            child: xtWait(
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : WgtHistoryBarChart(
            historyData: _monthlyConsumption,
            chartData: _chartData,
            getXText: (value) {
              int index = value.toInt();
              if (index < 0 || index >= _chartData.length) {
                return '';
              }
              return _monthlyConsumption[index]['time'];
            },
            getTooltipXText: (value) {
              int index = value.toInt();
              if (index < 0 || index >= _chartData.length) {
                return '';
              }
              return _monthlyConsumption[index]['label'];
            },
            ratio: 1.7,
            timeKey: 'time',
            valKey: 'value',
            showXTitle: true,
            showYTitle: false,
            rereservedSizeBottom: 21,
            timestampOnSecondLine: true,
            barColor: Colors.grey.shade600,
            border: Border.all(color: Colors.grey.shade600, width: 1),
            tooltipTextColor: widget.statColor ?? Colors.grey.shade800,
            bottomTextColor: widget.statColor ?? Colors.grey.shade800,
            bottomTextAngle: 0,
          );
  }

  Widget getPie() {
    return WgtPieChart(
      centerSize: 55,
      sectionRadius: 34,
      chartData: _pieStat,
      showIndicator: false,
      valueUnit: getDeivceTypeUnit(widget.meterType,
          displayContextStr: widget.displayContextStr),
      getColorList: AppColors.getColorListGreys,
      minLabelSize: 13,
      maxLabelSize: 15,
      startDegreeOffset: _pieStat.length > 1 ? 30 : -30,
      labelBaseColor: widget.statColor ?? Colors.grey.shade800,
      centerInfo: SizedBox(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text(
            //   getLookbackTypeLabel(_selectedLookbackType),
            //   style: TextStyle(
            //     color: Theme.of(context).hintColor,
            //     fontSize: 13,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // verticalSpaceTiny,
            Text(
              '${getCommaNumberStr(_groupTotalUsage)}${getDeivceTypeUnit(widget.meterType, displayContextStr: widget.displayContextStr)}',
              style: TextStyle(
                color: statColorDark,
                // widget.centerTopicColor ??Theme.of(context).colorScheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ), //widget.centerTopic,
    );
  }
}

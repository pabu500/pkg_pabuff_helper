import 'dart:async';

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_popup_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app_helper/pagrid_app_config.dart';

class WgtItemHistoryGetter extends StatefulWidget {
  const WgtItemHistoryGetter({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
    this.genMeta = true,
    // this.externalKeyReshfreshed = false,
    this.getterParentLoaded = false,
    this.externalKeyReshfrehKey,
    required this.dataType,
    // required this.chartType,
    required this.itemType,
    required this.itemId,
    required this.itemIdType,
    required this.historyType,
    // required this.chartLabel,
    required this.dataFields,
    this.meterType,
    this.showNormalization = true,
    this.allowNormalize = true,
    this.allowConsolidation = true,
    this.resetRange,
    this.width = 550,
    this.factor = 1,
    this.startDate,
    this.endDate,
    this.forceAlignTimeRange = false,
    this.lookBackMinutes = const [],
    required this.onTimeRangeChanged,
    required this.onResult,
    this.onPullingData,
    this.onToggleNormalization,
    this.maxDuration = const Duration(days: 7),
    this.isInvisible = false,
    this.useWidgetStartEndDate = false,
    this.clearRepeatedReadingsOnly = false,
    this.rawDataCheck = false,
    this.getByJob = false,
  });

  // final bool externalKeyReshfreshed;
  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final PaGridAppConfig appConfig;
  final bool genMeta;
  final bool getterParentLoaded;
  final UniqueKey? externalKeyReshfrehKey;
  final double width;
  final DataType dataType;
  // final ChartType chartType;
  final ItemType itemType;
  final String itemId;
  final ItemIdType itemIdType;
  final MeterType? meterType;
  final Evs2HistoryType historyType;
  final bool allowConsolidation;
  final bool showNormalization;
  final bool allowNormalize;
  // final String chartLabel;
  final List<Map<String, dynamic>> dataFields;
  final bool? resetRange;
  final double factor;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool forceAlignTimeRange;
  final Function onTimeRangeChanged;
  final Function onResult;
  final Function? onPullingData;
  final List<int> lookBackMinutes;
  final Duration maxDuration;
  final Function? onToggleNormalization;
  final bool isInvisible;
  final bool useWidgetStartEndDate;
  final bool clearRepeatedReadingsOnly;
  final bool rawDataCheck;
  final bool getByJob;

  @override
  State<WgtItemHistoryGetter> createState() => _WgtItemHistoryGetterState();
}

class _WgtItemHistoryGetterState extends State<WgtItemHistoryGetter> {
  //loading
  late DateTime _lastLoadingTime;
  DateTime? _lastRequestTime;
  bool _isPullingData = false;
  String _emptyResultText = '';
  String _tooManyRecordsText = '';

  //time
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _earliestDate;
  late int _selectedTimeRangeMinutes;
  bool _isCustomRange = false;
  late bool _normalization;

  late int _maxNumberOfRecords;

  //data
  final List<Map<String, List<Map<String, dynamic>>>> _selectedHistoryDataSets =
      [];
  final List<Map<String, dynamic>> _historyData = [];
  final Map<String, MeterHistoryMeta> _historyMeta = {};
  List<String> _allDataKeys = [];
  List<String> _readingTotalKeys = [];
  List<Map<String, dynamic>> _legend = [];

  //stat
  int _dominantIntervalMinutes = 1;
  double _maxY = 0;
  double _minY = double.infinity;
  double _total = 0;
  double _avgY = 0;
  double _medianY = 0;

  UniqueKey? _externalRefreshKey;

  Future<String> _getHistorys() async {
    if (widget.dataFields.isEmpty) {
      if (kDebugMode) {
        print('no data fields');
      }
      return 'no data fields';
    }
    setState(() {
      _isPullingData = true;
    });
    // if (widget.onPullingData != null) {
    //   widget.onPullingData!();
    // }
    // if (!widget.allowNormalize) {
    //   _normalization = false;
    // }
    if (widget.useWidgetStartEndDate) {
      _startDate = widget.startDate;
      _endDate = widget.endDate;
    }

    if (widget.resetRange ?? false) {
      _isCustomRange = false;
      _selectedTimeRangeMinutes = widget.lookBackMinutes[0];
    }

    if (!_isCustomRange) {
      DateTime endDate = _endDate ??
          widget.endDate ??
          getTargetLocalDatetimeNow(widget.scopeProfile.timezone);
      DateTime startDate = widget.startDate ??
          endDate.subtract(Duration(minutes: _selectedTimeRangeMinutes + 1));

      _startDate = startDate;
      _endDate = endDate;
    }

    _minY = double.infinity;
    _selectedHistoryDataSets.clear();
    _historyData.clear();
    _historyMeta.clear();
    _allDataKeys = [];
    _readingTotalKeys = [];
    _legend = [];
    _emptyResultText = '';
    _tooManyRecordsText = '';

    Map<String, dynamic> historyResult = {};
    List<String> fields =
        widget.dataFields.map((e) => e['field'] as String).toList();

    _lastRequestTime = DateTime.now();

    String meterTypeTag =
        widget.meterType == null ? '' : getMeterTypeTag(widget.meterType!);

    try {
      //delay
      // await Future.delayed(const Duration(milliseconds: 1000));

      Duration duration = _endDate!.difference(_startDate!);
      Map<String, String> queryMap = {};

      // get count first if duration is more than 7 days
      if (duration > const Duration(days: 7) || widget.getByJob) {
        Map<String, String> queryMap = {
          'item_type': widget.itemType.name,
          'item_id': widget.itemId,
          'item_id_type': widget.itemIdType.name,
          'meter_type_tag': meterTypeTag,
          'history_type': widget.historyType.name,
          'start_datetime': _startDate.toString(),
          'end_datetime': _endDate.toString(),
          'get_earliest_date': _earliestDate == null ? 'true' : 'false',
          'get_count_only': 'true',
        };
        if (kDebugMode) {
          print('pull history $_startDate - $_endDate');
        }
        historyResult = await pullItemHistory(
          widget.appConfig,
          queryMap,
          SvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: AclScope.global.name,
            target: widget.historyType.name,
            operation: AclOperation.list.name,
          ),
        );

        int totalCount = historyResult['total_count'];

        if (totalCount > _maxNumberOfRecords || widget.getByJob) {
          _tooManyRecordsText =
              'Too many records to display. Please select a smaller time range.';
          widget.onResult({
            'too_many_records': totalCount,
            'too_many_records_text':
                'Too many records to display. Please select a smaller time range.',
            'job_request': {
              'item_type': widget.itemType.name,
              'item_id': widget.itemId,
              'item_id_type': widget.itemIdType.name,
              'meter_type_tag': meterTypeTag,
              'data_fields': fields.join(','),
              'from_datetime': _startDate.toString(),
              'to_datetime': _endDate.toString(),
              'target': widget.historyType.name,
              'operation': AclOperation.list.name,
              'site_tag': widget.scopeProfile.selectedSiteScope == null
                  ? ''
                  : widget.scopeProfile.selectedSiteScope!.name,
              'project_scope': widget.appConfig.activePortalProjectScope.name,
            },
          });
          return 'too many records';
        }
      }

      queryMap = {
        'item_type': widget.itemType.name,
        'item_id': widget.itemId,
        'item_id_type': widget.itemIdType.name,
        'history_type': widget.historyType.name,
        'meter_type_tag': meterTypeTag,
        'data_fields': fields.join(','),
        'normalization':
            _normalization && widget.allowNormalize ? 'v2' : 'v2_none',
        'start_datetime': _startDate.toString(),
        'end_datetime': _endDate.toString(),
        'max_number_of_records': _maxNumberOfRecords.toString(),
        'get_earliest_date': _earliestDate == null ? 'true' : 'false',
        'allow_consolidation': widget.allowConsolidation ? 'true' : 'false',
        'clear_repeated_readings_only':
            widget.clearRepeatedReadingsOnly ? 'true' : 'false',
        'raw_data_check': widget.rawDataCheck ? 'true' : 'false',
        'detect_restart_event': widget.appConfig.activePortalProjectScope ==
                    ProjectScope.EMS_SMRT &&
                widget.itemType == ItemType.meter_3p
            ? 'true'
            : 'false',
        // 'get_count_only': 'false',
        'force_align_time_range': widget.forceAlignTimeRange ? 'true' : 'false',
        'gen_meta': widget.genMeta ? 'true' : 'false',
      };
      if (kDebugMode) {
        print('pull history $_startDate - $_endDate');
      }
      historyResult = await pullItemHistory(
        widget.appConfig,
        queryMap,
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: AclScope.global.name,
          target: widget.historyType.name,
          operation: AclOperation.list.name,
        ),
      );

      if (historyResult['time_range'] != null) {
        Map<String, dynamic> timeRange = historyResult['time_range'];
        String? earliestDateStr = timeRange['min_time'];
        if (earliestDateStr != null) {
          _earliestDate = DateTime.parse(earliestDateStr);
        } else {
          _earliestDate = null;
          _emptyResultText = 'No history data for this period';
          // throw Exception('empty');
          widget.onResult({
            'emptyResultText': _emptyResultText,
          });
        }
      }

      List<Map<String, dynamic>> history = [];
      for (var element in historyResult['history'] as List<dynamic>) {
        history.add(element as Map<String, dynamic>);
      }
      if (history.isEmpty) {
        // throw Exception('empty');
        _emptyResultText = 'No history data for this period';
        widget.onResult({
          'emptyResultText': _emptyResultText,
        });
      }

      if (kDebugMode) {
        print('history length: ${history.length}');
      }

      if (widget.rawDataCheck) {
      } else {
        Map<String, MeterHistoryMeta> historyMeta = {};
        if (historyResult['metas'].isNotEmpty) {
          for (var element
              in (historyResult['metas'] as Map<String, dynamic>).entries) {
            if (element.value != null) {
              historyMeta[element.key] =
                  MeterHistoryMeta.fromJson(element.value);

              _allDataKeys.add(element.key);
              if (!element.key.contains('_diff')) {
                _readingTotalKeys.add(element.key);
              }
            }
          }
        }
        if (_readingTotalKeys.isEmpty) {
          _readingTotalKeys = history.first['readings'].keys.toList();
        }

        _historyMeta.clear();
        _historyMeta.addAll(historyMeta);

        if (_historyMeta.isNotEmpty) {
          _dominantIntervalMinutes =
              _historyMeta[_historyMeta.keys.first]!.dominantInterval ~/
                  1000 ~/
                  60;
          if (kDebugMode) {
            print('dominantIntervalMinutes: $_dominantIntervalMinutes');
          }
        }
      }

      if (widget.forceAlignTimeRange) {
        history = _alignTimeRange(history, _startDate!, _endDate!);
      }

      _historyData.addAll(history);

      _genChartData();

      _genChartInfo();

      // int skipInterval = _getSkipInteral(10);
      // if (kDebugMode) {
      //   print('return result');
      // }

      MeterHistoryMeta? rawDataCheckMeta;
      if (widget.rawDataCheck) {
        rawDataCheckMeta = MeterHistoryMeta.fromJson(
          (historyResult['metas'] as Map<String, dynamic>).entries.first.value,
        );
      }

      widget.onResult({
        'rawDataCheckMeta': rawDataCheckMeta,
        'historyData': _historyData,
        'dataSet': _selectedHistoryDataSets,
        'legend': _legend,
        // 'skipInterval': skipInterval,
        'selectedTimeRangeMinutes': _selectedTimeRangeMinutes,
        'historyMeta': {
          'minY': _minY,
          'maxY': _maxY,
          'total': _total,
          'avgY': _avgY,
          'medianY': _medianY,
          'dominantIntervalMinutes': _dominantIntervalMinutes,
        }
      });

      return 'done';
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (e.toString().contains('null')) {
        _emptyResultText = 'error retrieving data';
        throw Exception('null');
      }
      if (e.toString().contains('empty')) {
        _emptyResultText = 'No history data';
        throw Exception('empty');
      }
    } finally {
      setState(() {
        _isPullingData = false;
      });

      widget.onResult({
        'emptyResultText': _emptyResultText,
      });
    }

    return 'error';
  }

  List<Map<String, dynamic>> _alignTimeRange(List<Map<String, dynamic>> history,
      DateTime targetStartDate, DateTime targetEndDate) {
    List<Map<String, dynamic>> alignedHistory = [];
    DateTime alignedStartDate = targetStartDate;
    DateTime alignedEndDate = targetEndDate;
    if (history.isNotEmpty) {
      String firstTimestamp = history.last['dt'];
      String lastTimestamp = history.first['dt'];
      DateTime dataFirstDate = DateTime.parse(firstTimestamp);
      DateTime dataLastDate = DateTime.parse(lastTimestamp);

      // insert zero if data starts after target start date or ends before target end date
      if (targetEndDate.isAfter(
          dataLastDate.add(Duration(minutes: _dominantIntervalMinutes)))) {
        DateTime insertDate =
            dataLastDate.add(Duration(minutes: _dominantIntervalMinutes));
        while (insertDate.isBefore(targetEndDate)) {
          alignedHistory.add({
            'dt': insertDate.toString(),
            'readings': {},
            'is_empty': 1,
          });
          insertDate =
              insertDate.add(Duration(minutes: _dominantIntervalMinutes));
        }
      }
      //reverse the alignedHistory
      alignedHistory = alignedHistory.reversed.toList();

      alignedHistory.addAll(history);
      if (targetStartDate.isBefore(dataFirstDate
          .subtract(Duration(minutes: _dominantIntervalMinutes)))) {
        DateTime insertDate =
            dataFirstDate.subtract(Duration(minutes: _dominantIntervalMinutes));
        while (insertDate.isAfter(targetStartDate)) {
          alignedHistory.add({
            'dt': insertDate.toString(),
            'readings': {},
            'is_empty': 1,
          });
          insertDate =
              insertDate.subtract(Duration(minutes: _dominantIntervalMinutes));
        }
      }
    }
    return alignedHistory;
  }

  void _genChartData() {
    List<Map<String, List<Map<String, dynamic>>>> chartData;
    // for (String fieldKeys in _allDataKeys) {
    for (String fieldKeys in _readingTotalKeys) {
      Map<String, List<Map<String, dynamic>>> readingDataSet = {
        fieldKeys: [],
      };

      _selectedHistoryDataSets.add(readingDataSet);
    }
    _selectedHistoryDataSets
        .sort((a, b) => a.keys.first.compareTo(b.keys.first));
    for (var readingRow in _historyData) {
      String readingTimestamp = readingRow['dt'];
      int isEstimated = readingRow['is_est'] ?? 0;
      int dtRepeated = readingRow['dt_repeated'] ?? 0;
      int dtMissing = readingRow['dt_missing'] ?? 0;
      // String isEmpty = readingRow['is_empty'];
      Map<String, dynamic> readingParts =
          readingRow['readings'].isEmpty ? {} : readingRow['readings'];
      for (String key in _readingTotalKeys) {
        if (readingParts.isEmpty) {
          _selectedHistoryDataSets
              .firstWhere((element) => element.containsKey(key))[key]!
              .add({
            'time': readingTimestamp,
            'value': 0.0,
            'is_estimated': 'false',
            'is_ot': 'false',
            'is_neg': 'false',
            'dt_repeated': 0,
            'dt_missing': 0,
            'is_restart': 'false',
            'is_empty': readingRow['is_empty'] == 1 ? 'true' : 'false',
          });
        } else {
          Map<String, dynamic> readingPair = readingParts[key] ?? {};
          double readingTotal = readingPair['rt'];
          int isReadingTotalEstimated = readingPair['rt_is_est'] ?? 0;
          double readingDiff = readingPair['rd'];
          int isReadingDiffEstimated = readingPair['rd_is_est'] ?? 0;
          int isReadingDiffOt = readingPair['rd_ot'] ?? 0;
          int isReadingDiffNeg = readingPair['rd_neg'] ?? 0;
          int isRestart = readingPair['rd_is_restart'] ?? 0;

          double displayValue = widget.dataType == DataType.total
              ? widget.factor * readingTotal
              : widget.factor * readingDiff;
          if (widget.dataType == DataType.diff && isReadingDiffOt == 1) {
            displayValue = 0;
          }
          isEstimated = widget.dataType == DataType.total
              ? isReadingTotalEstimated
              : isReadingDiffEstimated;

          _selectedHistoryDataSets
              .firstWhere((element) => element.containsKey(key))[key]!
              .add({
            'time': readingTimestamp,
            'value': displayValue,
            'is_estimated': isEstimated == 1 ? 'true' : 'false',
            'is_ot': isReadingDiffOt == 1 ? 'true' : 'false',
            'is_neg': isReadingDiffNeg == 1 ? 'true' : 'false',
            'dt_repeated': dtRepeated,
            'dt_missing': dtMissing,
            'is_restart': isRestart == 1 ? 'true' : 'false',
            'is_empty': readingRow['is_empty'] == 1 ? 'true' : 'false',
          });
        }
      }
    }
  }

  void _genChartInfo() {
    _legend = [];
    int i = 0;
    List<String> selectedKeys = [];
    for (var element in _selectedHistoryDataSets) {
      selectedKeys.add(
          '${element.keys.first}${widget.dataType == DataType.total ? '' : '_diff'}');
    }
    for (var keyName in selectedKeys) {
      _legend.add({
        'name': keyName,
        'color': AppColors
            .tier1colorsGreenBlue[i++ % AppColors.tier1colorsAlt.length],
      });
      if (_historyMeta[keyName] != null) {
        if (_historyMeta[keyName]!.minValNonZero < _minY) {
          _minY = widget.factor * _historyMeta[keyName]!.minValNonZero;
        }
        if (_historyMeta[keyName]!.maxVal > _maxY) {
          _maxY = widget.factor * _historyMeta[keyName]!.maxVal;
        }
      }
    }
    if (_historyMeta.isNotEmpty) {
      _dominantIntervalMinutes =
          _historyMeta[selectedKeys[0]]!.dominantInterval / 1000 ~/ 60;
      _total = _getMetaTotal();
      _avgY = _getMetaAverage();
      _medianY = _getMetaMedian();
    }
  }

  double _getMetaTotal() {
    if (widget.dataType == DataType.total) {
      return widget.factor *
          _historyMeta[_selectedHistoryDataSets.first.keys.first]!.total;
    } else {
      return widget.factor *
          _historyMeta['${_selectedHistoryDataSets.first.keys.first}_diff']!
              .total;
    }
  }

  double _getMetaAverage() {
    if (widget.dataType == DataType.total) {
      return widget.factor *
          _historyMeta[_selectedHistoryDataSets.first.keys.first]!.avgVal;
    } else {
      return widget.factor *
          _historyMeta['${_selectedHistoryDataSets.first.keys.first}_diff']!
              .avgVal;
    }
  }

  double _getMetaMedian() {
    if (widget.dataType == DataType.total) {
      return widget.factor *
          _historyMeta[_selectedHistoryDataSets.first.keys.first]!.medianVal;
    } else {
      return widget.factor *
          _historyMeta['${_selectedHistoryDataSets.first.keys.first}_diff']!
              .medianVal;
    }
  }

  @override
  void initState() {
    super.initState();

    _normalization =
        widget.appConfig.activePortalProjectScope == ProjectScope.EMS_CW_NUS
            ? false
            : true;

    _selectedTimeRangeMinutes = widget.lookBackMinutes[0];

    _maxNumberOfRecords = (widget.itemType == ItemType.meter ||
            widget.itemType == ItemType.meter_iwow)
        ? 3000
        : widget.itemType == ItemType.meter_3p
            ? 2500
            : 1500 /* 30min interval, 30 days */;

    _lastLoadingTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // if (kDebugMode) {
    //   print('WgtItemHistoryGetter build. externalKeyReshfreshed: ${widget.externalKeyReshfreshed}');
    // }
    String result = '';
    bool hasData =
        _historyData.isNotEmpty && _selectedHistoryDataSets.isNotEmpty;
    bool pullData = false;
    // if (widget.externalKeyReshfreshed) {
    if (widget.getterParentLoaded) {
      pullData = false;
    } else if (widget.externalKeyReshfrehKey != null &&
        widget.externalKeyReshfrehKey != _externalRefreshKey) {
      _externalRefreshKey = widget.externalKeyReshfrehKey;
      // _emptyResultText = '';
      // _tooManyRecordsText = '';
      pullData = true;
    } else {
      pullData =
          canPullData2(hasData, _lastRequestTime, 500, _lastLoadingTime, 1000);
    }

    // pullData = pullData && _emptyResultText.isEmpty && _tooManyRecordsText.isEmpty;

    return pullData
        ? FutureBuilder<String>(
            future: _getHistorys().then((value) => result = value),
            builder: (context, AsyncSnapshot<String> snapshot) {
              switch (snapshot.connectionState) {
                // case ConnectionState.waiting:
                //   return SizedBox(
                //     width: widget.width,
                //     child: Align(
                //       alignment: Alignment.center,
                //       child: xtWait(
                //         color: Theme.of(context).colorScheme.primary,
                //       ),
                //     ),
                //   );
                // case ConnectionState.done:
                //   return getChart();
                default:
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      print(snapshot.error.toString());
                    }
                    return SizedBox(
                      width: widget.width,
                      child: const Align(
                        alignment: Alignment.center,
                        child:
                            //  _emptyResultText.isNotEmpty
                            //     ? EmptyResult(message: _emptyResultText)
                            //     :
                            Text('error loading data'),
                      ),
                    );
                  } else {
                    return completedWidget();
                  }
              }
            },
          )
        : completedWidget();
  }

  Widget completedWidget() {
    if (widget.isInvisible) return Container();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 45,
              decoration: BoxDecoration(
                border: _isCustomRange
                    ? Border.all(
                        color: Theme.of(context).hintColor.withOpacity(0.2),
                        width: 1,
                      )
                    : Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                      height: 35,
                      child: IconButton(
                        tooltip:
                            'previous ${getReadableDuration(Duration(minutes: _selectedTimeRangeMinutes))}',
                        onPressed: _isPullingData ||
                                _isCustomRange ||
                                _startDate == null ||
                                _earliestDate == null ||
                                _startDate!.isBefore(_earliestDate!)
                            ? null
                            : () async {
                                _endDate = _endDate!.subtract(Duration(
                                    minutes: _selectedTimeRangeMinutes));
                                _startDate = _startDate!.subtract(Duration(
                                    minutes: _selectedTimeRangeMinutes));
                                _isCustomRange = false;

                                widget.onTimeRangeChanged(
                                    _startDate!, _endDate!, _isCustomRange);
                                await _getHistorys();
                              },
                        icon: const Icon(Icons.arrow_left),
                      )),
                  for (var item in widget.lookBackMinutes)
                    InkWell(
                      onTap: _isPullingData
                          ? null
                          : () async {
                              if (item != _selectedTimeRangeMinutes) {
                                setState(() {
                                  _selectedTimeRangeMinutes = item;
                                });
                                _endDate = getTargetLocalDatetimeNow(
                                    widget.scopeProfile.timezone);
                                _startDate = _endDate!.subtract(Duration(
                                    minutes: _selectedTimeRangeMinutes));
                                _isCustomRange = false;
                                widget.onTimeRangeChanged(
                                  _startDate!,
                                  _endDate!,
                                  _isCustomRange,
                                );

                                await _getHistorys();
                              }
                            },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        color: _selectedTimeRangeMinutes == item
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5)
                            : Theme.of(context).hintColor.withOpacity(0.1),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(5.0, 6.0, 5.0, 5.0),
                          child: Text(
                              getReadableDuration(Duration(minutes: item)),
                              // '${item ~/ 60} hours',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip:
                        'next ${getReadableDuration(Duration(minutes: _selectedTimeRangeMinutes))}',
                    onPressed: _isPullingData ||
                            _isCustomRange ||
                            _endDate == null ||
                            _endDate!.isAfter(getTargetLocalDatetimeNow(
                                    widget.scopeProfile.timezone)
                                .subtract(const Duration(hours: 1)))
                        ? null
                        : () async {
                            _endDate = _endDate!.add(
                                Duration(minutes: _selectedTimeRangeMinutes));
                            _startDate = _startDate!.add(
                                Duration(minutes: _selectedTimeRangeMinutes));
                            widget.onTimeRangeChanged(
                                _startDate!, _endDate!, _isCustomRange);

                            await _getHistorys();
                          },
                    icon: const Icon(Icons.arrow_right),
                  )
                ],
              ),
            ),
            horizontalSpaceTiny,
            Container(
              height: 45,
              decoration: BoxDecoration(
                border: _isCustomRange
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : Border.all(
                        color: Theme.of(context).hintColor.withOpacity(0.2),
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: WgtDateRangePicker2(
                scopeProfile: widget.scopeProfile,
                timezone: widget.scopeProfile.timezone,
                populateDefaultRange: false,
                width: 290,
                updateRangeByParent: true,
                startDateTime: _startDate,
                endDateTime: _endDate,
                onSet: (startDate, endDate) async {
                  if (startDate == null || endDate == null) return;
                  setState(() {
                    _startDate = startDate;
                    _endDate = endDate;
                    _isCustomRange = true;
                    _selectedTimeRangeMinutes =
                        endDate.difference(startDate).inMinutes;
                  });

                  widget.onTimeRangeChanged(
                      _startDate!, _endDate!, _isCustomRange);

                  await _getHistorys();
                },
                maxDuration: widget.maxDuration, // const Duration(days: 7),
                onMaxDurationExceeded: () {
                  // Timer(const Duration(milliseconds: 500), () {
                  //   showSnackBar(
                  //     context,
                  //     'Maximum duration is ${getReadableDuration(const Duration(days: 3))}',
                  //   );
                  // });
                },
              ),
            ),
          ],
        ),
        verticalSpaceTiny,
        widget.showNormalization &&
                widget.loggedInUser.hasPermmision2(
                    widget.scopeProfile.getEffectiveScope(),
                    AclTarget.meter_p_trending_est_option,
                    AclOperation.read)
            ? false //activePortalProjectScope == ProjectScope.EMS_CW_NUS
                ? WgtPopupButton(
                    direction: 'right',
                    // buttonKey: buttonKey,
                    width: 200,
                    height: 21,
                    popupWidth: 89,
                    popupHeight: 50,
                    popupChild: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withOpacity(0.2),
                        border: Border.all(
                          width: 1,
                          color: Theme.of(context).hintColor,
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(2, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Contact Us',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                    ),
                    // disabled: disabled,
                    child: getNormalization(disabled: true),
                    onHover: (val) {},
                  )
                : getNormalization()
            : Container(),
        // getNormalization(),
      ],
    );
  }

  Widget getNormalization({bool disabled = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _normalization,
          onChanged: _isPullingData || disabled
              ? null
              : (value) async {
                  if (value != null) {
                    if (value == _normalization) {
                      return;
                    }
                  }
                  setState(() {
                    _normalization = !_normalization;
                    if (widget.onToggleNormalization != null) {
                      widget.onToggleNormalization!(_normalization);
                    }
                  });
                  await _getHistorys();
                },
        ),
        Text('apply Trending Discovery',
            style: disabled
                ? TextStyle(color: Theme.of(context).hintColor)
                : null),
      ],
    );
  }
}

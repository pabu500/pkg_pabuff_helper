import 'dart:async';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_operation.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_target.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/up_helper/enum/enum_item.dart';
import 'package:buff_helper/up_helper/helper/device_def.dart';
import 'package:buff_helper/up_helper/model/mdl_meter_kwh_history.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:buff_helper/xt_ui/style/app_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/chart/chart_def.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../comm/comm_pag_item.dart';
import '../../model/mdl_history.dart';
import '../../model/mdl_pag_app_config.dart';
import '../datetime/wgt_pag_date_range_picker.dart';

enum NormalisationType {
  NONE,
  DEVICE_READING,
  DEVICE_READING_INSERT_ZERO,
}

class WgtPagItemHistoryGetter extends StatefulWidget {
  const WgtPagItemHistoryGetter({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    this.genMeta = true,
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

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final bool genMeta;
  final bool getterParentLoaded;
  final UniqueKey? externalKeyReshfrehKey;
  final double width;
  final DataType dataType;
  final dynamic itemType;
  final String itemId;
  final ItemIdType itemIdType;
  final MeterType? meterType;
  final PagItemHistoryType historyType;
  final bool allowConsolidation;
  final bool showNormalization;
  final bool allowNormalize;
  final List<Map<String, dynamic>> dataFields;
  final bool? resetRange;
  final double factor;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool forceAlignTimeRange;
  final Function onTimeRangeChanged;
  final Function(Map<String, dynamic>) onResult;
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
  State<WgtPagItemHistoryGetter> createState() =>
      _WgtPagItemHistoryGetterState();
}

class _WgtPagItemHistoryGetterState extends State<WgtPagItemHistoryGetter> {
  //loading
  int _pullFailCount = 0;
  late DateTime _lastLoadingTime;
  DateTime? _lastRequestTime;
  bool _isFetchingData = false;
  bool _isFetched = false;
  String _emptyResultText = '';
  String _errorText = '';
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

  Future<dynamic> _getHistory() async {
    if (_isFetchingData) {
      return;
    }
    if (widget.dataFields.isEmpty) {
      if (kDebugMode) {
        print('no data fields');
      }
      return 'no data fields';
    }

    _isFetchingData = true;
    _isFetched = false;
    _errorText = '';
    _emptyResultText = '';
    _tooManyRecordsText = '';

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
          getTargetLocalDatetimeNow(
              widget.loggedInUser.selectedScope.getProjectTimezone());
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

    // Map<String, dynamic> historyResult = {};
    List<String> fields =
        widget.dataFields.map((e) => e['field'] as String).toList();

    _lastRequestTime = DateTime.now();

    String meterTypeTag =
        widget.meterType == null ? '' : getMeterTypeTag(widget.meterType!);

    String itemTypeStr = "";
    if (widget.itemType is DeviceCat) {
      itemTypeStr = (widget.itemType as DeviceCat).name;
    }

    try {
      Duration duration = _endDate!.difference(_startDate!);
      Map<String, dynamic> queryMap = {};

      // MdlPagScope pagScope = widget.loggedInUser.selectedScope.getSelectedPagScope();

      // get count first if duration is more than 7 days
      if (duration > const Duration(days: 7) || widget.getByJob) {
        Map<String, dynamic> queryMap = {
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'item_type': itemTypeStr,
          'item_id_value': widget.itemId,
          'item_id_type': widget.itemIdType.name,
          'meter_type_tag': meterTypeTag,
          'history_type': widget.historyType.name,
          'from_timestamp': _startDate.toString(),
          'to_timestamp': _endDate.toString(),
          'get_earliest_date': _earliestDate == null ? 'true' : 'false',
          'get_count_only': 'true',
        };
        if (kDebugMode) {
          print('pull history $_startDate - $_endDate');
        }
        var data = await pullPagItemHistory(
          widget.loggedInUser,
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: widget.historyType.name,
            operation: '',
          ),
        );

        var itemHistoryInfo = data['item_history'];

        if (queryMap['get_count_only'] == 'true') {
          if (data['total_count'] == null) {
            throw Exception('Failed to get total count');
          }
          itemHistoryInfo = {
            'total_count': data['total_count'],
          };
        }

        if (itemHistoryInfo == null) {
          throw Exception('error getting history data');
        }

        // var itemHistoryInfo = data['item_history'];

        int totalCount = itemHistoryInfo['total_count'];

        if (totalCount > _maxNumberOfRecords || widget.getByJob) {
          _tooManyRecordsText =
              'Too many records to display. Please select a smaller time range.';
          widget.onResult({
            'too_many_records': totalCount,
            'too_many_records_text':
                'Too many records to display. Please select a smaller time range.',
            'job_request': {
              'item_type': itemTypeStr,
              'item_id': widget.itemId,
              'item_id_type': widget.itemIdType.name,
              'meter_type_tag': meterTypeTag,
              'data_fields': fields.join(','),
              'from_datetime': _startDate.toString(),
              'to_datetime': _endDate.toString(),
              'target': widget.historyType.name,
              'operation': '',
            },
          });
          return 'too many records';
        }
      }

      queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'item_type': itemTypeStr,
        'item_id_type': widget.itemIdType.name,
        'item_id_value': widget.itemId,
        'history_type': widget.historyType.name,
        'meter_type_tag': meterTypeTag,
        'normalization_field_str': fields.join(','),
        'normalization_type': _normalization && widget.allowNormalize
            ? NormalisationType.DEVICE_READING.name
            : NormalisationType.NONE.name,
        'from_timestamp': _startDate.toString(),
        'to_timestamp': _endDate.toString(),
        'max_number_of_records': _maxNumberOfRecords.toString(),
        'get_earliest_date': _earliestDate == null ? 'true' : 'false',
        'allow_consolidation': widget.allowConsolidation ? 'true' : 'false',
        'clear_repeated_readings_only':
            widget.clearRepeatedReadingsOnly ? 'true' : 'false',
        'raw_data_check': widget.rawDataCheck ? 'true' : 'false',
        'detect_restart_event':
            false //widget.appConfig.activePortalProjectScope == ProjectScope.EMS_SMRT && widget.itemType == ItemType.meter_3p
                ? 'true'
                : 'false',
        'force_align_time_range': widget.forceAlignTimeRange ? 'true' : 'false',
        'gen_meta': widget.genMeta ? 'true' : 'false',
      };
      if (kDebugMode) {
        print('pull history $_startDate - $_endDate');
      }
      var data = await pullPagItemHistory(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: '',
          target: widget.historyType.name,
          operation: '',
        ),
      );

      var itemHistoryInfo = data['item_history'];

      String? info = data['info'];
      if (info != null) {
        if (info.contains("Empty") || info.contains("found")) {
          itemHistoryInfo = {
            'history_list': [],
            'meta_info': {},
            'time_range': data['time_range'],
          };
        }
      }

      if (itemHistoryInfo == null) {
        throw Exception('error getting history data');
      }

      // final meterReadingHistoryJson = itemHistoryInfo[queryMap['history_type']];
      final timeRange = itemHistoryInfo['time_range'];
      final meterReadingHistoryMeta = itemHistoryInfo['meta'];
      final multiMetaInfo = itemHistoryInfo['multi_meta_info'];
      final meterInfo = multiMetaInfo ?? {'total': meterReadingHistoryMeta};

      if (timeRange != null) {
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
          return;
        }
      }

      List<Map<String, dynamic>> historyList = [];
      for (var element in itemHistoryInfo['history_list'] as List<dynamic>) {
        historyList.add(element as Map<String, dynamic>);
      }
      if (historyList.isEmpty) {
        // throw Exception('empty');
        _emptyResultText = 'No history data for this period';
        widget.onResult({
          'emptyResultText': _emptyResultText,
        });
        return;
      }

      if (kDebugMode) {
        print('history length: ${historyList.length}');
      }

      if (widget.rawDataCheck) {
      } else {
        Map<String, MeterHistoryMeta> historyMeta = {};
        if (meterInfo.isNotEmpty) {
          for (var element in (meterInfo as Map<String, dynamic>).entries) {
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
          _readingTotalKeys = historyList.first['readings'].keys.toList();
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
        historyList = _alignTimeRange(historyList, _startDate!, _endDate!);
      }

      _historyData.addAll(historyList);

      _genChartData();

      _genChartInfo();

      MeterHistoryMeta? rawDataCheckMeta;
      if (widget.rawDataCheck) {
        if (itemHistoryInfo['multi_meta_info'] == null) {
          throw Exception('multi_meta_info is null');
        }

        rawDataCheckMeta = MeterHistoryMeta.fromJson(
          (itemHistoryInfo['multi_meta_info'] as Map<String, dynamic>)
              .entries
              .first
              .value,
        );
      }

      widget.onResult({
        'rawDataCheckMeta': rawDataCheckMeta,
        'historyData': _historyData,
        'dataSet': _selectedHistoryDataSets,
        'legend': _legend,
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
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }

      _pullFailCount++;

      _errorText = 'Failed to fetch data';

      throw Exception(_emptyResultText);
    } finally {
      _isFetchingData = false;
      _isFetched = true;

      Timer(const Duration(microseconds: 100), () {
        if (mounted) {
          widget.onResult.call({
            'tooManyRecordsText': _tooManyRecordsText,
            'emptyResultText': _emptyResultText,
            'errorText': _errorText,
          });
        }
      });
    }
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
    // List<Map<String, List<Map<String, dynamic>>>> chartData;
    // for (String fieldKeys in _allDataKeys) {
    _selectedHistoryDataSets.clear();
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

    _normalization = false
        // widget.appConfig.activePortalProjectScope == ProjectScope.EMS_CW_NUS
        ? false
        : true;

    _selectedTimeRangeMinutes = widget.lookBackMinutes[0];

    _maxNumberOfRecords = 3000;

    _lastLoadingTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('WgtPagItemHistoryGetter build');
    }

    // if (_pullFailCount > 0) {
    //   return getErrorTextPrompt(
    //       context: context, errorText: 'Failed to fetch data');
    // }

    bool pullData = false;
    if (widget.getterParentLoaded) {
      pullData = false;
    } else if (widget.externalKeyReshfrehKey != null &&
        widget.externalKeyReshfrehKey != _externalRefreshKey) {
      _externalRefreshKey = widget.externalKeyReshfrehKey;
      pullData = true;
    } else if (_isFetched && _errorText.isNotEmpty) {
      pullData = false;
    } else {
      pullData = true;
    }

    return pullData
        ? FutureBuilder<dynamic>(
            future: _getHistory(),
            builder: (context, AsyncSnapshot<dynamic> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return SizedBox(
                    width: widget.width,
                    child: const Center(child: WgtPagWait()),
                  );
                case ConnectionState.done:
                  if (kDebugMode) {
                    print('done');
                  }

                  //reach here if the future throws an error
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      print(snapshot.error.toString());
                    }
                  }
                  return completedWidget();
                default:
                  return completedWidget();
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
                        color: Theme.of(context).hintColor.withAlpha(50),
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
                        onPressed: _isFetchingData ||
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
                                await _getHistory();
                              },
                        icon: const Icon(Icons.arrow_left),
                      )),
                  for (var item in widget.lookBackMinutes)
                    InkWell(
                      onTap: _isFetchingData
                          ? null
                          : () async {
                              if (item != _selectedTimeRangeMinutes) {
                                setState(() {
                                  _selectedTimeRangeMinutes = item;
                                });
                                _endDate = getTargetLocalDatetimeNow(widget
                                    .loggedInUser.selectedScope
                                    .getProjectTimezone());
                                _startDate = _endDate!.subtract(Duration(
                                    minutes: _selectedTimeRangeMinutes));
                                _isCustomRange = false;
                                widget.onTimeRangeChanged(
                                  _startDate!,
                                  _endDate!,
                                  _isCustomRange,
                                );

                                await _getHistory();
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
                                .withAlpha(130)
                            : Theme.of(context).hintColor.withAlpha(30),
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
                    onPressed: _isFetchingData ||
                            _isCustomRange ||
                            _endDate == null ||
                            _endDate!.isAfter(getTargetLocalDatetimeNow(widget
                                    .loggedInUser.selectedScope
                                    .getProjectTimezone())
                                .subtract(const Duration(hours: 1)))
                        ? null
                        : () async {
                            _endDate = _endDate!.add(
                                Duration(minutes: _selectedTimeRangeMinutes));
                            _startDate = _startDate!.add(
                                Duration(minutes: _selectedTimeRangeMinutes));
                            widget.onTimeRangeChanged(
                                _startDate!, _endDate!, _isCustomRange);

                            await _getHistory();
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
                        color: Theme.of(context).hintColor.withAlpha(55),
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: WgtPagDateRangePicker(
                timezone:
                    widget.loggedInUser.selectedScope.getProjectTimezone(),
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

                  await _getHistory();
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
                widget.loggedInUser.hasPermission(
                  MdlPagScope(
                    projectId: widget
                        .loggedInUser.selectedScope.projectProfile!.id
                        .toString(),
                    projectName:
                        widget.loggedInUser.selectedScope.projectProfile!.name,
                  ),
                  MdlPagTarget(),
                  MdlPagOperation(operation: PagOperationType.READ),
                )
            ? getNormalization()
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
          onChanged: _isFetchingData || disabled
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
                  await _getHistory();
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

import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/file/wgt_save_table.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import '../../def_helper/dh_device.dart';
import '../../model/mdl_history.dart';
import '../../model/mdl_pag_app_config.dart';
import 'wgt_pag_history_rep_chart.dart';
import 'wgt_pag_history_rep_list.dart';
import 'wgt_pag_item_history_getter.dart';

class WgtPagItemHistoryPresenter extends StatefulWidget {
  const WgtPagItemHistoryPresenter({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.itemKind,
    required this.itemType,
    required this.itemSubType,
    required this.itemId,
    required this.itemIdType,
    required this.historyType,
    this.showTitle = true,
    this.displayId,
    this.borderColor,
    this.barColor,
    this.width = 720,
    this.height = 560,
    this.bgColor,
    this.chartKey,
    this.startDate,
    this.endDate,
    this.useWidgetStartEndDate = false,
    this.chartTitle = '',
    this.chartTitleWidget,
    this.chartBorder,
    this.chartRatio = 1.8,
    this.refreshInterval = 30000,
    this.lookBackMinutes = const [24 * 60, 3 * 24 * 60, 7 * 24 * 60],
    this.canCollapse = true,
    this.showNormalization,
    this.displayType,
    this.config = const [],
    this.showXTitles = true,
    this.showYTitles = true,
    this.reserveTooltipSpace = true,
    this.dataFields,
    this.genMeta = true,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final PagItemKind itemKind; //e.g. DEVICE, LOCATION
  final dynamic itemType; //e.g. METER, SENSOR
  final dynamic itemSubType; //e.g. E, W, G, N
  final String itemId;
  final ItemIdType itemIdType;
  final PagItemHistoryType historyType;
  final HistroyDisplayType? displayType;
  final String? displayId;
  final bool showTitle;
  final double width;
  final double height;
  final Color? borderColor;
  final Color? bgColor;
  final int? refreshInterval;
  final UniqueKey? chartKey;
  final double chartRatio;
  final Border? chartBorder;
  final List<int> lookBackMinutes;
  final String chartTitle;
  final Widget? chartTitleWidget;
  final Color? barColor;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool useWidgetStartEndDate;
  final bool canCollapse;
  final bool? showNormalization;
  final List<String> config;
  final bool showXTitles;
  final bool showYTitles;
  final bool reserveTooltipSpace;
  final List<Map<String, dynamic>>? dataFields;
  final bool genMeta;

  @override
  State<WgtPagItemHistoryPresenter> createState() =>
      _WgtPagItemHistoryPresenterState();
}

class _WgtPagItemHistoryPresenterState
    extends State<WgtPagItemHistoryPresenter> {
  late bool _showTitle = widget.showTitle;
  late bool _showDivider;
  late bool _showHistoryGetter;
  late bool _showMeta;

  bool _isHistoryLoading = false;
  bool _isHistoryLoaded = false;

  int _dominantIntervalMinutes = 1;
  UniqueKey? _intRefreshKey;
  UniqueKey? _chartKeyExt;
  UniqueKey _optionChangeRefreshKey = UniqueKey();

  //for history getter
  late HistroyDisplayType _displayType;
  late int _selectedTimeRangeMinutes;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _resetRange;
  bool _inNormalizeMode = false;

  // for meta
  final Map<String, dynamic> _historyMeta = {};
  // final Map<String, dynamic> _rawDataCheckMeta = {};
  double _maxY = 0;
  double _minY = double.infinity;
  double _total = 0;
  double _avgY = 0;
  double _medianY = 0;

  //for raw data check
  Duration? _actualDuration;
  int? _expectedCount;
  // int? _actualCount;
  int? _missingCount;
  int? _negTotalCount;
  int? _negDiffCount;
  int? _overThresholdCount;

  bool _fullCols = false;

  // for history data
  List<Map<String, dynamic>> _legendChart = [];
  // List<Map<String, dynamic>> _legendList = [];
  final List<Map<String, dynamic>> _historyDataForList = [];
  final List<ValueItem<String>> _selectedMultiFields = [];
  // final List<Map<String, dynamic>> _selectedDataFieldsChart = [];
  final List<Map<String, dynamic>> _selectedDataFieldsForList = [];
  bool _selectedFieldsChanged = false;
  final List<Map<String, List<Map<String, dynamic>>>>
      _selectedHistoryDataSetsForChart = [];
  final List<Map<String, List<Map<String, dynamic>>>>
      _selectedHistoryDataSetsForList = [];

  String _tooManyRecordsText = '';
  String _emptyResultText = '';
  String _errorText = '';
  String _intervalStr = '';

  final String _reportPrefix = 'history';

  late String _selectedChartReadingTypeKey;
  late final String _defaultChartReadingTypeKey;

  final MultiSelectController<String> _controller = MultiSelectController();

  late final Map<String, dynamic> _readingTypeConfig;

  bool _getByJob = false;
  final Map<String, String> _jobRequest = {};

  // bool _forceAlignTimeRange = false;

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];

    List<Map<String, List<Map<String, dynamic>>>> selectedHistoryDataSets = [];
    if (_displayType == HistroyDisplayType.chart) {
      selectedHistoryDataSets.addAll(_selectedHistoryDataSetsForChart);
    } else {
      selectedHistoryDataSets.addAll(_selectedHistoryDataSetsForList);
    }
    List<String> header = ['time'];
    for (var element in selectedHistoryDataSets) {
      header.add(element.keys.first);
      if (_fullCols) {
        //is estimated
        header.add('${element.keys.first}_is_est');
      }
    }
    table.add(header);

    for (var i = 0;
        i < selectedHistoryDataSets.first.values.first.length;
        i++) {
      List<dynamic> row = [];
      row.add(selectedHistoryDataSets.first.values.first[i]['time']);
      for (var element in selectedHistoryDataSets) {
        row.add(element.values.first[i]['value']);
        if (_fullCols) {
          row.add(element.values.first[i]['is_estimated']);
        }
      }
      table.add(row);
    }

    return table;
  }

  void _iniHistorySetting() {
    if (widget.itemKind == PagItemKind.device) {
      assert(widget.itemType is PagDeviceCat);
      assert(
          widget.itemSubType is MeterType || widget.itemSubType is SensorType);

      switch (widget.itemSubType) {
        case MeterType.electricity1p ||
              MeterType.water ||
              MeterType.gas ||
              MeterType.newater:
          _selectedChartReadingTypeKey = 'val_meter';

          _readingTypeConfig.clear();
          _readingTypeConfig.addAll({
            'val_meter': {
              'title': 'kWh',
              'dataFields': [
                {
                  'field': 'val',
                }
              ],
              'timeKey': 'time',
              'decimals': 3,
              'unit': getDeivceTypeUnit(widget.itemSubType),
              'chartType': ChartType.bar,
              'dataType': DataType.diff,
              'color': Colors.blue.withAlpha(210),
              'width': 150,
            }
          });
          break;
        case MeterType.electricity3p:
        case MeterType.water:
        case MeterType.gas:
        case MeterType.newater:
        case MeterType.btu:
          _selectedChartReadingTypeKey = 'val_meter';

          _readingTypeConfig.clear();
          _readingTypeConfig.addAll({
            'val_meter': {
              'title': 'kWh',
              'dataFields': [
                {
                  'field': 'val',
                }
              ],
              'unit': 'kWh',
              'decimals': 3,
              'chartType': ChartType.bar,
              'dataType': DataType.diff,
              'color': Colors.blue.withAlpha(210),
            },
            'flow': {
              'title': 'Flow (m3/h)',
              'dataFields': [
                {
                  'field': 'flow',
                }
              ],
              'unit': '',
              // 'decimals': 1,
              'chartType': ChartType.line,
              'dataType': DataType.total,
              'color': Colors.blueGrey.withAlpha(210),
            },
            'power': {
              'title': 'Power (kW)',
              'dataFields': [
                {
                  'field': 'power',
                }
              ],
              'unit': 'kW',
              'chartType': ChartType.line,
              'dataType': DataType.total,
              'color': Colors.green.withAlpha(210),
            },
            'volume': {
              'title': 'Volume (m3)',
              'dataFields': [
                {
                  'field': 'volume',
                },
              ],
              'unit': 'm3',
              'chartType': ChartType.bar,
              'dataType': DataType.diff,
              'color': Colors.green.withAlpha(210),
            },
            'forward_temp': {
              'title': 'Forward Temp (°C)',
              'dataFields': [
                {
                  'field': 'forward_temp',
                },
              ],
              'unit': '°C',
              'chartType': ChartType.line,
              'dataType': DataType.total,
              'color': Colors.green,
            },
            'return_temp': {
              'title': 'Return Temp (°C)',
              'dataFields': [
                {
                  'field': 'return_temp',
                }
              ],
              'unit': '°C',
              'chartType': ChartType.line,
              'dataType': DataType.total,
              'color': Colors.blueGrey.withAlpha(210),
            },
          });
          break;
        case MeterType.bidirection:
          _selectedChartReadingTypeKey = 'delivered_total';

          _readingTypeConfig.clear();
          _readingTypeConfig.addAll({
            'delivered_total': {
              'title': 'Delivered Energy (kWh)',
              'dataFields': [
                {
                  'field': 'delivered_total',
                }
              ],
              'unit': 'kWh',
              'chartType': ChartType.bar,
              'dataType': DataType.diff,
              'color': Colors.orange.withAlpha(210),
            },
            'received_total': {
              'title': 'Received Energy (kWh)',
              'dataFields': [
                {
                  'field': 'received_total',
                }
              ],
              'unit': 'kWh',
              'chartType': ChartType.bar,
              'dataType': DataType.diff,
              'color': Colors.blue.withAlpha(210),
            },
          });

          break;
        case SensorType.temperature ||
              SensorType.humidity ||
              SensorType.ir ||
              SensorType.light ||
              SensorType.co2 ||
              SensorType.fan ||
              SensorType.temperature_humidity ||
              SensorType.switchSensor:
          _selectedChartReadingTypeKey = 'val_sensor';
           String valColName = "val";
              switch(widget.itemSubType) {
                  case SensorType.temperature || SensorType.temperature_humidity:
                    valColName = "temperature_val";
                    break;
                  case SensorType.humidity:
                    valColName = "humidity_val";
                    break;
                  case SensorType.ir:
                    valColName = "ir_val";
                    break;
                  case SensorType.co2:
                    valColName = "co2_val";
                    break;
                case SensorType.fan:
                    valColName = "fan_val";
                    break;
              default: 
                    break;
              }
          _readingTypeConfig.clear();
          _readingTypeConfig.addAll({
            'val_sensor': {
              'title': '',
              'dataFields': [
                {
                  'field': valColName,
                }
              ],
              'timeKey': 'time',
              'decimals': 1,
              'unit': getDeivceTypeUnit(widget.itemSubType),
              'chartType': ChartType.line,
              'dataType': DataType.total,
              'color': Colors.blue.withAlpha(210),
              'width': 150,
            }
          });
          break;
        default:
          throw Exception('Unsupported itemSubType: ${widget.itemSubType}');
      }
    }

    assert(_readingTypeConfig.isNotEmpty);

    _displayType = widget.displayType ?? HistroyDisplayType.chart;
    if (!widget.config.contains('chart_core') &&
        widget.config.contains('table_core')) {
      _displayType = HistroyDisplayType.table;
    }
    _showTitle = widget.config.isEmpty || widget.config.contains('title');
    _showDivider = widget.config.isEmpty || widget.config.contains('divider');
    _showHistoryGetter =
        widget.config.isEmpty || widget.config.contains('history_getter');
    _showMeta = !_isHistoryLoading &&
        (widget.config.isEmpty || widget.config.contains('meta'));

    _chartKeyExt = widget.chartKey /* ?? UniqueKey()*/;
    _isHistoryLoading = true;

    _selectedTimeRangeMinutes = widget.lookBackMinutes[0];

    if (widget.itemType == ItemType.meter_3p) {
      _selectedChartReadingTypeKey = 'a_imp';
    }
    if (widget.itemType == PagDeviceCat.sensor) {
      _selectedChartReadingTypeKey = 'val_sensor';
    }
    if (widget.itemType == ItemType.fleet_health) {
      _selectedChartReadingTypeKey = 'score1';
    }
    _defaultChartReadingTypeKey = _selectedChartReadingTypeKey;

    _selectedMultiFields.clear();
    _selectedMultiFields.add(ValueItem(
        label: _readingTypeConfig[_selectedChartReadingTypeKey]['title'],
        value: _selectedChartReadingTypeKey));
    _selectedDataFieldsForList.clear();
    _selectedDataFieldsForList.addAll(
        _readingTypeConfig[_selectedChartReadingTypeKey]['dataFields']
            as List<Map<String, dynamic>>);
  }

  void _updateSelectedDataFieldsList() {
    _selectedDataFieldsForList.clear();
    for (var item in _selectedMultiFields) {
      _selectedDataFieldsForList.addAll(_readingTypeConfig[item.value!]
          ['dataFields'] as List<Map<String, dynamic>>);
    }

    _selectedChartReadingTypeKey =
        _selectedMultiFields.first.value ?? _defaultChartReadingTypeKey;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  dynamic _getReadingTypeConfig(String chartRedingTypeKey, String key) {
    return _readingTypeConfig[chartRedingTypeKey][key];
  }

  @override
  void initState() {
    super.initState();
    _readingTypeConfig = {};

    _iniHistorySetting();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('WgtPagItemHistoryPresenter build');
    }
    if (_chartKeyExt != widget.chartKey) {
      if (widget.chartKey != null) {
        _chartKeyExt = widget.chartKey!;
        _selectedHistoryDataSetsForChart.clear();
        _selectedHistoryDataSetsForList.clear();
        _emptyResultText = '';
        _errorText = '';
        _isHistoryLoading = true;
        _isHistoryLoaded = false;
      }
    }
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.bgColor ??
            (Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).cardColor
                : null),
        border: Border.all(
          color:
              widget.borderColor ?? Theme.of(context).hintColor.withAlpha(210),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        children: [
          if (_showTitle) getTitleRow(),
          if (_showDivider)
            Divider(
              indent: 8,
              endIndent: 8,
              color: Theme.of(context).hintColor.withAlpha(210),
              thickness: 0.5,
            ),
          if (_showHistoryGetter) verticalSpaceSmall,
          _errorText.isNotEmpty
              ? Expanded(
                  child: Center(
                      child: getErrorTextPrompt(
                          context: context, errorText: _errorText)),
                )
              : WgtPagItemHistoryGetter(
                  loggedInUser: widget.loggedInUser,
                  appConfig: widget.appConfig,
                  genMeta: widget.genMeta,
                  forceAlignTimeRange: _getReadingTypeConfig(
                          _selectedChartReadingTypeKey, 'chartType') ==
                      ChartType.bar,
                  getterParentLoaded: _isHistoryLoaded,
                  getByJob: _getByJob,
                  isInvisible: !_showHistoryGetter,
                  useWidgetStartEndDate: widget.useWidgetStartEndDate,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  externalKeyReshfrehKey: _optionChangeRefreshKey,
                  itemType: widget.itemType,
                  itemId: widget.itemId,
                  itemIdType: widget.itemIdType,
                  historyType: widget.historyType,
                  lookBackMinutes: widget.lookBackMinutes,
                  dataFields: _displayType == HistroyDisplayType.chart
                      ? _getReadingTypeConfig(
                              _selectedChartReadingTypeKey, 'dataFields')
                          as List<Map<String, dynamic>>
                      : _selectedDataFieldsForList,
                  dataType: _getReadingTypeConfig(
                      _selectedChartReadingTypeKey, 'dataType') as DataType,
                  factor: _getReadingTypeConfig(
                          _selectedChartReadingTypeKey, 'factor') as double? ??
                      1,
                  clearRepeatedReadingsOnly:
                      _displayType == HistroyDisplayType.chart ? false : true,
                  rawDataCheck:
                      _displayType == HistroyDisplayType.chart ? false : true,
                  resetRange: _resetRange,
                  showNormalization: widget.showNormalization ??
                          _displayType == HistroyDisplayType.chart
                      ? true
                      : false,
                  allowNormalize:
                      _displayType == HistroyDisplayType.chart ? true : false,
                  allowConsolidation:
                      _displayType == HistroyDisplayType.chart ? true : false,
                  maxDuration: _displayType == HistroyDisplayType.chart
                      ? const Duration(days: 7)
                      : const Duration(days: 180),
                  onTimeRangeChanged: (startDate, endDate, customRange) {
                    _startDate = startDate;
                    _endDate = endDate;

                    _resetRange = null;

                    setState(() {
                      _isHistoryLoading = true;
                      _isHistoryLoaded = false;
                    });
                  },
                  onPullingData: () {
                    if (kDebugMode) {
                      print('*** pulling data');
                    }
                    setState(() {
                      _isHistoryLoading = true;
                      _isHistoryLoaded = false;
                    });
                  },
                  onToggleNormalization: (value) {
                    _inNormalizeMode = value;
                    // setState(() {
                    //   _isHistoryLoading = true;
                    // });
                  },
                  onResult: (resultMap) {
                    if (kDebugMode) {
                      print('onResult');
                    }

                    if (resultMap['too_many_records'] != null) {
                      setState(() {
                        _isHistoryLoading = false;
                        _isHistoryLoaded = true;
                        _tooManyRecordsText =
                            resultMap['too_many_records_text'];
                        int totalCount = resultMap['too_many_records'] as int;
                        if (_emptyResultText.isNotEmpty) {
                          _historyDataForList.clear();
                          _selectedHistoryDataSetsForList.clear();
                        }

                        _jobRequest.clear();
                        _jobRequest.addAll(resultMap['job_request']);

                        _intRefreshKey = UniqueKey();
                        // _isHistoryLoaded = false;
                      });
                      return;
                    }

                    if (resultMap['errorText'] != null) {
                      if (kDebugMode) {
                        print('errorText: ${resultMap['errorText']}');
                      }
                      setState(() {
                        _isHistoryLoading = false;
                        _isHistoryLoaded = true;
                        _errorText = resultMap['errorText'];
                        if (_emptyResultText.isNotEmpty) {
                          _selectedHistoryDataSetsForChart.clear();
                          _selectedHistoryDataSetsForList.clear();
                        }
                      });
                      return;
                    } else if (resultMap['emptyResultText'] != null) {
                      if (kDebugMode) {
                        print(
                            'emptyResultText: ${resultMap['emptyResultText']}');
                      }
                      setState(() {
                        _isHistoryLoading = false;
                        _isHistoryLoaded = true;
                        _emptyResultText = resultMap['emptyResultText'];
                        if (_emptyResultText.isNotEmpty) {
                          _selectedHistoryDataSetsForChart.clear();
                          _selectedHistoryDataSetsForList.clear();
                        }
                      });
                      return;
                    }

                    if (kDebugMode) {
                      print('onResult2');
                    }
                    _jobRequest.clear();
                    _tooManyRecordsText = '';
                    _emptyResultText = '';
                    _errorText = '';

                    _selectedTimeRangeMinutes =
                        resultMap['selectedTimeRangeMinutes'];

                    _historyMeta.clear();
                    _historyMeta.addAll(resultMap['historyMeta']);
                    if (resultMap['rawDataCheckMeta'] != null) {
                      MeterHistoryMeta rawDataCheckMeta =
                          resultMap['rawDataCheckMeta'] as MeterHistoryMeta;
                      int duraitonMills = rawDataCheckMeta.duration;
                      _actualDuration = Duration(milliseconds: duraitonMills);
                      _expectedCount = rawDataCheckMeta.expectedReadingCount;
                      // _actualCount = rawDataCheckMeta.actualReadingCount;
                      _missingCount = rawDataCheckMeta.missingReadingCount;
                      _negTotalCount = rawDataCheckMeta.negativeTotalCount;
                      _negDiffCount = rawDataCheckMeta.negativeDiffCount;
                      _overThresholdCount = rawDataCheckMeta.overThresholdCount;
                    }
                    _minY = _historyMeta['minY'];
                    _maxY = _historyMeta['maxY'];
                    _dominantIntervalMinutes =
                        _historyMeta['dominantIntervalMinutes'];
                    _total = _historyMeta['total'];
                    _avgY = _historyMeta['avgY'];
                    _medianY = _historyMeta['medianY'];

                    _historyDataForList.clear();
                    _historyDataForList.addAll(resultMap['historyData']);

                    var dataSet = resultMap['dataSet'];
                    var legend = resultMap['legend'];
                    if (_displayType == HistroyDisplayType.chart) {
                      //get subset from dataSet with key = _selectedChartReadingTypeKey
                      List<Map<String, dynamic>> seletedDataFileds =
                          _getReadingTypeConfig(
                                  _selectedChartReadingTypeKey, 'dataFields')
                              as List<Map<String, dynamic>>;
                      List<Map<String, List<Map<String, dynamic>>>>
                          seletedDataSetForChart = [];
                      List<Map<String, dynamic>> selectedLegendForChart = [];
                      for (Map<String, List<Map<String, dynamic>>> dataSetItem
                          in dataSet) {
                        String key = dataSetItem.keys.first;
                        if (seletedDataFileds
                            .any((element) => element['field'] == key)) {
                          seletedDataSetForChart.add(dataSetItem);
                        }
                        if (legend.any((element) => element['name'] == key)) {
                          selectedLegendForChart.add(legend
                              .firstWhere((element) => element['name'] == key));
                        }
                      }
                      _selectedHistoryDataSetsForChart.clear();
                      _selectedHistoryDataSetsForChart
                          .addAll(seletedDataSetForChart);
                      _legendChart.clear();
                      _legendChart.addAll(selectedLegendForChart);
                    } else {
                      _selectedHistoryDataSetsForList.clear();
                      _selectedHistoryDataSetsForList.addAll(dataSet);
                    }

                    _intervalStr = _dominantIntervalMinutes >= 60
                        ? '${_dominantIntervalMinutes ~/ 60}h'
                        : '${_dominantIntervalMinutes}m';
                    if (kDebugMode) {
                      print('onResult3');
                    }
                    setState(() {
                      _isHistoryLoading = false;
                      _isHistoryLoaded = true;
                      _intRefreshKey = UniqueKey();
                    });

                    // _externalKeyReshfreshed = false;
                    // _dataFieldPull = false;
                    // _normalizedChartToRawListPull = false;
                    // _rawListToNormalizedChartPull = false;
                    // _downloadModeChangePull = false;

                    if (kDebugMode) {
                      print('onResult4');
                    }
                  },
                ),
          if (_errorText.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: getHistoryPresentor(),
              ),
            ),
        ],
      ),
    );
  }

  Widget getTitleRow() {
    bool useMultiFields = _readingTypeConfig.length > 1;

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          horizontalSpaceSmall,
          widget.displayType == null
              ? Row(
                  children: [
                    Tooltip(
                      message: 'Chart View',
                      waitDuration: const Duration(milliseconds: 500),
                      child: InkWell(
                        child: Icon(
                          // CupertinoIcons.chart_bar_square,
                          Symbols.insert_chart,
                          size: 34,
                          color: _displayType == HistroyDisplayType.chart
                              ? Theme.of(context).highlightColor.withAlpha(210)
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(210),
                        ),
                        onTap: () {
                          // if _endDate is more than 7 days from startDate, reset endDate to 7 days from startDate
                          if (_selectedTimeRangeMinutes >
                              const Duration(days: 7).inMinutes) {
                            // _endDate = _startDate!.add(const Duration(days: 7));
                            _selectedTimeRangeMinutes =
                                widget.lookBackMinutes[0];
                            _resetRange = true;
                          }

                          setState(() {
                            _displayType = HistroyDisplayType.chart;

                            // _currentMainChartReading = _selectedDataFieldsList.first['field'] as String;
                            if (_selectedMultiFields.isNotEmpty) {
                              _selectedChartReadingTypeKey =
                                  _selectedMultiFields.first.value!;
                            }

                            _selectedDataFieldsForList.clear();
                            _selectedDataFieldsForList.addAll(
                                _getReadingTypeConfig(
                                        _selectedChartReadingTypeKey,
                                        'dataFields')
                                    as List<Map<String, dynamic>>);

                            if (_inNormalizeMode) {
                              // _rawListToNormalizedChartPull = true;
                              _optionChangeRefreshKey = UniqueKey();
                              _isHistoryLoading = true;
                              _isHistoryLoaded = false;
                            }
                          });
                        },
                      ),
                    ),
                    horizontalSpaceTiny,
                    Tooltip(
                      message: 'List View',
                      waitDuration: const Duration(milliseconds: 500),
                      child: InkWell(
                        child: Icon(
                          // CupertinoIcons.square_list,
                          Symbols.list_alt,
                          size: 34,
                          color: _displayType == HistroyDisplayType.table
                              ? Theme.of(context).highlightColor.withAlpha(210)
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(210),
                        ),
                        onTap: () {
                          setState(() {
                            _displayType = HistroyDisplayType.table;

                            //always pull
                            // if (_inNormalizeMode) {
                            // _normalizedChartToRawListPull = true;
                            _optionChangeRefreshKey = UniqueKey();
                            _isHistoryLoading = true;
                            _isHistoryLoaded = false;
                            // }

                            _selectedDataFieldsForList.clear();
                            _selectedDataFieldsForList.addAll(
                                _getReadingTypeConfig(
                                        _selectedChartReadingTypeKey,
                                        'dataFields')
                                    as List<Map<String, dynamic>>);
                            _selectedMultiFields.clear();
                            _selectedMultiFields.add(ValueItem(
                                label: _readingTypeConfig[
                                    _selectedChartReadingTypeKey]['title'],
                                value: _selectedChartReadingTypeKey));
                            _controller.selectedOptions.clear();
                            _controller.selectedOptions
                                .addAll(_selectedMultiFields);
                            _selectedFieldsChanged = false;
                            _intRefreshKey = UniqueKey();
                            _isHistoryLoaded = false;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : Container(),
          Expanded(child: Container()),
          // (widget.itemType == ItemType.meter_3p || widget.itemType == ItemType.fleet_health)
          useMultiFields
              ? Row(
                  children: [
                    Text(
                      widget.displayId ?? widget.itemId,
                      style: TextStyle(
                          // fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).hintColor),
                    ),
                    horizontalSpaceSmall,
                    // (widget.itemType == ItemType.meter_3p ||widget.itemType == ItemType.fleet_health)
                    useMultiFields && _displayType == HistroyDisplayType.table
                        ? getFieldSelector()
                        : getChartReadingTypeSelector(),
                  ],
                )
              : Text(
                  widget.displayId ?? widget.itemId,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
          Expanded(child: Container()),
          if (_displayType == HistroyDisplayType.table)
            Tooltip(
              message: 'Get list by task email',
              waitDuration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _getByJob,
                      onChanged: (value) {
                        setState(() {
                          _getByJob = value!;
                          // _downloadModeChangePull = true;
                          _optionChangeRefreshKey = UniqueKey();
                          _isHistoryLoading = true;
                          _isHistoryLoaded = false;
                        });
                      },
                    ),
                    Text(
                      'Task',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ),
          Tooltip(
            message: 'CSV to include troubleshoot columns',
            waitDuration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _fullCols,
                    onChanged: (value) {
                      setState(() {
                        _fullCols = value!;
                      });
                    },
                  ),
                  Text(
                    'T/C',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ),
          if (_displayType == HistroyDisplayType.chart)
            WgtSaveTable(
              enabled: _selectedHistoryDataSetsForChart.isNotEmpty,
              getList: _getCsvList,
              fileName: makeReportName(
                _reportPrefix,
                widget.itemId,
                _startDate ?? DateTime.now(),
                _endDate ?? DateTime.now(),
              ),
            ),
          horizontalSpaceSmall,
        ],
      ),
    );
  }

  Widget getChartReadingTypeSelector() {
    //remove 'val' from _readingTypeConfig
    Map<String, dynamic> items = {};
    items.addAll(_readingTypeConfig);
    items.remove('val');

    return DropdownButton(
      value: _selectedChartReadingTypeKey,
      onChanged: (String? newValue) {
        setState(() {
          _selectedChartReadingTypeKey = newValue!;
          // _iniHistorySetting();

          _selectedMultiFields.clear();
          _selectedMultiFields.add(ValueItem(
              label: _readingTypeConfig[_selectedChartReadingTypeKey]['title'],
              value: _selectedChartReadingTypeKey));

          // _chartKeyExt = UniqueKey();
          // _intRefreshKey = UniqueKey();
          // _optionChangeRefreshKey = UniqueKey();
          _isHistoryLoaded = false;
        });
      },
      items: items.keys.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(_readingTypeConfig[value]['title'],
              style: TextStyle(
                color: value == _selectedChartReadingTypeKey
                    ? Theme.of(context).colorScheme.primary
                    : null,
              )),
        );
      }).toList(),
    );
  }

  Widget getFieldSelector() {
    //remove 'val' from _readingTypeConfig
    Map<String, dynamic> items = {};
    items.addAll(_readingTypeConfig);
    items.remove('val');

    List<ValueItem<String>> options = [];
    for (var item in items.keys) {
      options.add(ValueItem(
        label: _readingTypeConfig[item]['title'],
        value: item,
      ));
    }

    return Row(
      children: [
        SizedBox(
          width: 360,
          height: 60,
          child: MultiSelectDropDown<String>(
            options: <ValueItem<String>>[
              ...options,
            ],
            selectedOptions: _selectedMultiFields,
            // showClearIcon: true,
            controller: _controller,
            onOptionSelected: (options) {
              // debugPrint(options.toString());
              // // at least one option must be selected
              // if (_selectedFields.length == 1 && options.isEmpty) {
              //   _controller.addSelectedOption(_selectedFields.first);
              //   return;
              // }
              _selectedMultiFields.clear();
              _selectedMultiFields.addAll(options);
              setState(() {
                _selectedFieldsChanged = true;
              });
            },
            borderRadius: 5,
            hintColor: Theme.of(context).hintColor,
            // backgroundColor: Theme.of(context).cardColor, //Colors.blue,
            fieldBackgroundColor: Theme.of(context).cardColor,
            optionsBackgroundColor:
                Theme.of(context).cardColor, //Colors.yellow,
            focusedBorderColor: Colors.transparent,
            selectedOptionBackgroundColor:
                Theme.of(context).cardColor, //Colors.purple,
            maxItems: 8,
            selectionType: SelectionType.multi,
            chipConfig: ChipConfig(
                deleteIcon: _selectedMultiFields.length == 1
                    ? Icon(Icons.minimize,
                        size: 0, color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.cancel),
                radius: 5,
                backgroundColor: Theme.of(context).colorScheme.primary),

            dropdownHeight: items.length * 40.0 + 10,
            optionTextStyle:
                TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
            selectedOptionIcon: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            // borderWidth: 2,
            selectedOptionTextColor: Colors.white,
            // searchEnabled: true,
            dropdownMargin: 2,
            optionSeparator: SizedBox(
              height: 1,
              child: Divider(
                indent: 5,
                endIndent: 5,
                color: Theme.of(context).hintColor.withAlpha(130),
              ),
            ),
          ),
        ),
        horizontalSpaceTiny,
        if (_selectedFieldsChanged && _selectedMultiFields.isNotEmpty)
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              setState(() {
                _updateSelectedDataFieldsList();
                // _intRefreshKey = UniqueKey();
                // _externalKeyReshfreshed = true;

                // _dataFieldPull = true;
                _optionChangeRefreshKey = UniqueKey();
                _selectedFieldsChanged = false;
                _isHistoryLoading = true;
                _isHistoryLoaded = false;
              });
            },
          ),
      ],
    );
  }

  double _getOverheadHeight() {
    double height = 0;
    if (widget.config.isEmpty) {}
    if (_showTitle) {
      height += 34;
    }
    if (_showDivider) {
      height += 16;
    }
    if (_showHistoryGetter) {
      height += 50;
    }
    if (_showMeta) {
      height += 34;
    }
    if (widget.showNormalization ?? false) {
      height += 15;
    }
    if (_displayType == HistroyDisplayType.table) {
      height += 30;
    }

    return height;
  }

  Widget getHistoryPresentor() {
    // print('history loading: $_isHistoryLoading');
    return Column(
      children: [
        if (_showMeta) getMetaRow(),
        widget.reserveTooltipSpace
            ? (_displayType == HistroyDisplayType.chart
                ? verticalSpaceMedium
                : verticalSpaceTiny)
            : Container(),
        SizedBox(
          width: widget.width,
          height: widget.height - _getOverheadHeight() - 90,
          child: _isHistoryLoading
              ? Align(
                  alignment: Alignment.center,
                  child: xtWait(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _displayType == HistroyDisplayType.chart
                  ? getChartRepresentation()
                  : _displayType == HistroyDisplayType.table
                      ? getListRepresentation()
                      : Container(),
        ),
      ],
    );
  }

  Widget getChartRepresentation() {
    if (_tooManyRecordsText.isNotEmpty) {
      return Center(
        child: Text(
          'Too many records to display',
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 21,
          ),
        ),
      );
    }
    return WgtPagHistoryRepChart(
      loggedInUser: widget.loggedInUser,
      readingTypeConfig: _readingTypeConfig,
      chartReadingTypeKey: _selectedChartReadingTypeKey,
      chartKey: _intRefreshKey,
      width: widget.width,
      chartRatio: widget.chartRatio,
      lookBackMinutes: _selectedTimeRangeMinutes,
      selectedHistoryDataSets: _selectedHistoryDataSetsForChart,
      legend: _legendChart,
      dominantIntervalMinutes: _dominantIntervalMinutes,
      borderColor: Colors.transparent,
      chartBorder: widget.chartBorder,
      showXTitles: widget.showXTitles,
      showYTitles: widget.showYTitles,
      reserveTooltipSpace: widget.reserveTooltipSpace,
      height: widget.height - _getOverheadHeight(),
      barColor: widget.barColor,
    );
  }

  Widget getListRepresentation() {
    return WgtPagHistoryRepList(
      loggedInUser: widget.loggedInUser,
      appConfig: widget.appConfig,
      itemId: widget.itemId,
      readingTypeConfig: _readingTypeConfig,
      readingTypes: _selectedMultiFields.map((e) => e.value!).toList(),
      listKey: _intRefreshKey,
      lookBackMinutes: _selectedTimeRangeMinutes,
      iniHistoryData: _historyDataForList,
      height: widget.height - _getOverheadHeight(),
      borderColor: Colors.transparent,
      startDate: _startDate,
      endDate: _endDate,
      fullCols: _fullCols,
      jobRequest: _jobRequest,
      valTitle: 'reading total',
      valDiffTitle: 'usage',
    );
  }

  Widget getMetaRow() {
    DataType dataType =
        _getReadingTypeConfig(_selectedChartReadingTypeKey, 'dataType')
            as DataType;
    int decimals =
        _getReadingTypeConfig(_selectedChartReadingTypeKey, 'decimals')
                as int? ??
            2;

    return _displayType == HistroyDisplayType.table
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              xtKeyValueText(
                selectable: true,
                spaceInBetween: 1,
                keyText: 'Duration:',
                valueText: _actualDuration == null
                    ? 'N/A'
                    : '${_actualDuration!.inHours}h',
              ),
              horizontalSpaceTiny,
              xtKeyValueText(
                selectable: true,
                spaceInBetween: 1,
                keyText: 'Expected:',
                valueText: _expectedCount == null ? 'N/A' : '$_expectedCount±1',
              ),
              horizontalSpaceTiny,
              xtKeyValueText(
                selectable: true,
                spaceInBetween: 1,
                keyText: 'Missing:',
                valueText:
                    _missingCount == null ? 'N/A' : _missingCount.toString(),
              ),
              horizontalSpaceTiny,
              xtKeyValueText(
                selectable: true,
                spaceInBetween: 1,
                keyText: 'Neg Total:',
                valueText:
                    _negTotalCount == null ? 'N/A' : _negTotalCount.toString(),
              ),
              horizontalSpaceTiny,
              xtKeyValueText(
                selectable: true,
                spaceInBetween: 1,
                keyText: 'Neg Diff:',
                valueText:
                    _negDiffCount == null ? 'N/A' : _negDiffCount.toString(),
              ),
              horizontalSpaceTiny,
              xtKeyValueText(
                selectable: true,
                spaceInBetween: 1,
                keyText: 'Overflow:',
                valueText: _overThresholdCount == null
                    ? 'N/A'
                    : _overThresholdCount.toString(),
              ),
              horizontalSpaceSmall,
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              (_displayType == HistroyDisplayType.table &&
                      _selectedDataFieldsForList.length > 1)
                  ? const SizedBox(width: 360)
                  : Wrap(children: [
                      dataType == DataType.total
                          ? Container()
                          : xtKeyValueText(
                              selectable: true,
                              spaceInBetween: 1,
                              keyText: 'Sum:',
                              valueText: _total.toStringAsFixed(decimals),
                            ),
                      horizontalSpaceTiny,
                      xtKeyValueText(
                        selectable: true,
                        spaceInBetween: 1,
                        keyText: 'Min:',
                        valueText: _historyMeta.isEmpty
                            ? 'N/A'
                            : (_minY).toStringAsFixed(decimals),
                      ),
                      horizontalSpaceTiny,
                      xtKeyValueText(
                        selectable: true,
                        spaceInBetween: 1,
                        keyText: 'Max:',
                        valueText: _historyMeta.isEmpty
                            ? 'N/A'
                            : (_maxY).toStringAsFixed(decimals),
                      ),
                      horizontalSpaceTiny,
                      xtKeyValueText(
                        selectable: true,
                        spaceInBetween: 1,
                        keyText: 'Avg:',
                        valueText: _historyMeta.isEmpty
                            ? 'N/A'
                            : _avgY.toStringAsFixed(decimals),
                      ),
                      horizontalSpaceTiny,
                      xtKeyValueText(
                        selectable: true,
                        spaceInBetween: 1,
                        keyText: 'Med:',
                        valueText: _historyMeta.isEmpty
                            ? 'N/A'
                            : _medianY.toStringAsFixed(decimals),
                      ),
                      horizontalSpaceSmall,
                    ]),
              _intervalStr.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 13.0),
                      child: Tooltip(
                        message: 'reading interval',
                        waitDuration: const Duration(milliseconds: 500),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 1),
                          child: Text(
                            _intervalStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          );
  }
}

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WgtHistoryRepChart extends StatefulWidget {
  WgtHistoryRepChart({
    Key? key,
    required this.readingTypeConfig,
    required this.chartReadingTypeKey,
    required this.selectedHistoryDataSets,
    required this.dominantIntervalMinutes,
    this.legend = const [],
    this.barColor,
    this.width = 720,
    this.height = 650,
    this.bgColor,
    this.borderColor,
    this.chartBorder,
    this.chartKey,
    this.startDate,
    this.endDate,
    this.chartRatio = 1.8,
    this.lookBackMinutes = 1440,
    this.showXTitles = true,
    this.showYTitles = true,
    this.reserveTooltipSpace = true,
    this.fullCol = false,
  }) : super(key: key);

  final Map<String, dynamic> readingTypeConfig;
  final String chartReadingTypeKey;
  final List<Map<String, List<Map<String, dynamic>>>> selectedHistoryDataSets;
  final List<Map<String, dynamic>> legend;
  final int dominantIntervalMinutes;
  final double width;
  final double height;
  final Color? barColor;
  final Color? bgColor;
  final Color? borderColor;
  final Border? chartBorder;
  final UniqueKey? chartKey;
  final double chartRatio;
  final DateTime? startDate;
  final DateTime? endDate;
  final int lookBackMinutes;
  final bool showXTitles;
  final bool showYTitles;
  final bool reserveTooltipSpace;
  final bool fullCol;

  @override
  _WgtHistoryRepChartState createState() => _WgtHistoryRepChartState();
}

class _WgtHistoryRepChartState extends State<WgtHistoryRepChart> {
  late ScopeProfile _scopeProfile;
  late Evs2User? _loggedInUser;

  bool _isHistoryLoading = false;

  late int _dominantIntervalMinutes;

  final List<Map<String, List<Map<String, dynamic>>>> _selectedHistoryDataSets =
      [];

  final Map<String, dynamic> _historyMeta = {};

  late List<Map<String, dynamic>> _legend = [];

  int _dataPointWarningCount = 0;
  late DataType _chartDataType;
  late ChartType _chartType;
  late List<Map<String, dynamic>> _historyDataFields;
  int _skipInterval = 1;
  late double _ySpace;
  late String _unit;
  late int _decimals;
  // late double _factor;

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];

    List<String> header = ['time'];
    for (var element in _selectedHistoryDataSets) {
      header.add(element.keys.first);
      if (widget.fullCol) {
        //is estimated
        header.add('${element.keys.first}_is_est');
      }
    }
    table.add(header);

    for (var i = 0;
        i < _selectedHistoryDataSets.first.values.first.length;
        i++) {
      List<dynamic> row = [];
      row.add(_selectedHistoryDataSets.first.values.first[i]['time']);
      for (var element in _selectedHistoryDataSets) {
        row.add(element.values.first[i]['value']);
        if (widget.fullCol) {
          row.add(element.values.first[i]['is_estimated']);
        }
      }
      table.add(row);
    }

    return table;
  }

  // List<Map<String, dynamic>> _selectSingleData() {
  //   if (_selectedHistoryDataSets.isEmpty) {
  //     return [];
  //   }
  //   if (widget.dataFields.length == 1) {
  //     return _selectedHistoryDataSets.first.values.first;
  //   }
  //   return [];
  // }

  // Color _getBoarderColor() {
  //   _dataPointWarningCount = 0;
  //   List<Map<String, dynamic>> data = _selectSingleData();
  //   if (data.isEmpty) {
  //     return Theme.of(context).hintColor;
  //   }
  //   for (var item in data) {
  //     if (item['value'] < 0) {
  //       _dataPointWarningCount++;
  //     }
  //   }
  //   double warningRate = _dataPointWarningCount / data.length;

  //   if (warningRate > 0.1) {
  //     return Colors.orange.withOpacity(0.8);
  //   } else if (warningRate > 0.05) {
  //     return Colors.yellow.withOpacity(0.8);
  //   } else {
  //     return Theme.of(context).hintColor;
  //   }
  // }

  int _getSkipInterval(int desiredIndicatorCount) {
    int skipInterval = 1;
    int indicatorCount = widget.lookBackMinutes ~/ _dominantIntervalMinutes;
    if (indicatorCount > desiredIndicatorCount) {
      skipInterval = indicatorCount ~/ desiredIndicatorCount;
    }
    return skipInterval;
  }

  void _loadHistorySetting() {
    _chartDataType = widget.readingTypeConfig[widget.chartReadingTypeKey]
        ['dataType'] as DataType;
    _chartType = widget.readingTypeConfig[widget.chartReadingTypeKey]
        ['chartType'] as ChartType;
    _historyDataFields = [];
    _historyDataFields.addAll(
        widget.readingTypeConfig[widget.chartReadingTypeKey]['dataFields']
            as List<Map<String, dynamic>>);
    _legend.clear();
    _legend.addAll(widget.legend);
    _unit =
        widget.readingTypeConfig[widget.chartReadingTypeKey]['unit'] as String;
    _decimals = widget.readingTypeConfig[widget.chartReadingTypeKey]['decimals']
            as int? ??
        0;
    _ySpace = (widget.readingTypeConfig[widget.chartReadingTypeKey]['ySpace']
            as double?) ??
        (widget.showYTitles ? 50 : 0);
    // _factor = widget.chartConfig[widget.chartReading]['factor'] as double? ?? 1;
    _selectedHistoryDataSets.clear();
    _selectedHistoryDataSets.addAll(widget.selectedHistoryDataSets);
    _legend.clear();
    _legend.addAll(widget.legend);
    _dominantIntervalMinutes = widget.dominantIntervalMinutes;
    _skipInterval = _getSkipInterval(13);
  }

  @override
  void initState() {
    super.initState();
    _scopeProfile =
        Provider.of<AppModel>(context, listen: false).portalScopeProfile;
    _loggedInUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;

    _loadHistorySetting();
  }

  @override
  Widget build(BuildContext context) {
    // _selectedHistoryDataSets.clear();
    // _selectedHistoryDataSets.addAll(widget.selectedHistoryDataSets);
    // _legend.clear();
    // _legend.addAll(widget.legend);
    // _dominantIntervalMinutes = widget.dominantIntervalMinutes;
    // _skipInterval = _getSkipInterval(13);
    // print('skipInterval $_skipInterval dominantIntervalMinutes $_dominantIntervalMinutes');
    _loadHistorySetting();
    // if (kDebugMode) {
    //   print('isHistoryLoading $_isHistoryLoading');
    // }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.borderColor ??
            (Theme.of(context).brightness == Brightness.light
                // ? Colors.grey.shade700
                ? Theme.of(context).cardColor
                : null),
        border: Border.all(
          color:
              widget.borderColor ?? Colors.transparent, //?? _getBoarderColor(),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getLegend(),
          SizedBox(
            width: widget.width,
            height: widget.height - (widget.reserveTooltipSpace ? 145 : 3),
            child: _isHistoryLoading
                ? Align(
                    alignment: Alignment.center,
                    child: xtWait(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : getChartCore(),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Widget getLegend() {
    return
        // _selectedHistoryDataSets.length <= 1
        _legend.length <= 1
            ? Container()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13.0),
                child: Row(
                  children: [
                    for (var item in _legend)
                      xtInfoBox(
                        padding: const EdgeInsets.all(0.0),
                        icon: Icon(
                          Icons.square,
                          color: item['color'],
                          size: 13,
                        ),
                        text: item['name'],
                        textStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).hintColor),
                      ),
                  ],
                ),
              );
  }

  Widget getChartCore() {
    if (kDebugMode) {
      if (_selectedHistoryDataSets.isEmpty) {
        print('getChartCore: selectedHistoryDataSets is empty');
      }
    }
    return _chartType == ChartType.line
        ? WgtHistoryLineChart(
            showTitle: false,
            chartKey: widget.chartKey,
            chartRatio: widget.chartRatio,
            historyDataSets: _selectedHistoryDataSets,
            timeKey: 'time',
            valKey: 'value',
            showXTitle: widget.showXTitles,
            showYTitle: widget.showYTitles,
            xTimeFormat: 'MM-dd HH:mm',
            xSpace: 30,
            reservedSizeLeft: _ySpace,
            // minY: _minY,
            // skipOddXTitle: true,
            skipInterval: _skipInterval,
            yDecimal: _decimals,
            valUnit: _unit,
            legend: _legend,
            rereservedSizeBottom: 65,
            bottomTextColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          )
        : WgtHistoryBarChart(
            chartKey: widget.chartKey,
            historyData: _selectedHistoryDataSets.isEmpty
                ? []
                : _selectedHistoryDataSets.first.values.first,
            ratio: widget.chartRatio,
            reservedSizeLeft: _ySpace,
            rereservedSizeBottom: 30,
            timeKey: 'time',
            valKey: 'value',
            xTimeFormat: 'MM-dd HH:mm',
            showXTitle: widget.showXTitles,
            showYTitle: widget.showYTitles,
            xSpace: 30,
            yUnit: _unit,
            skipInterval: _skipInterval, //_getSkipInteral(10),
            // maxVal: _maxY,
            showEmptyMessage: true,
            dominantIntervalSecond: _dominantIntervalMinutes * 60,
            // yDecimal: decideDisplayDecimal(0.5 * _maxY),
            barColor: widget.barColor ?? Theme.of(context).colorScheme.primary,
            altBarColorIf: (int index, Map<String, dynamic> item) {
              return item['is_estimated'] == 'true' ||
                  item['is_empty'] == 'true' ||
                  item['is_restart'] == 'true';
            },
            // prefixLabel: 'est.',
            prefixLabelIf: (int index, Map<String, dynamic> item) {
              return item['is_estimated'] == 'true' ||
                  item['is_empty'] == 'true' ||
                  item['is_restart'] == 'true';
            },
            getPrefixLabel: (int index, Map<String, dynamic> item) {
              return item['is_estimated'] == 'true'
                  ? 'est.'
                  : item['is_empty'] == 'true'
                      ? 'empty.'
                      : item['is_restart'] == 'true'
                          ? 'prog_rst.'
                          : '';
            },
            getAltVal: (int index, Map<String, dynamic> item) {
              return item['is_empty'] == 'true' ? '-' : null;
            },
            useAltBarColor: true,
            border: widget.chartBorder,
            bottomTextColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            tooltipTextColor:
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.92),
            highlightColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            timestampOnSecondLine: true,
          );
  }
}

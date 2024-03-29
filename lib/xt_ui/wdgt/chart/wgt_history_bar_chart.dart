import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../util/date_time_util.dart';
import '../../../util/string_util.dart';
import '../../../util/util.dart';
import '../../style/app_colors.dart';

class WgtHistoryBarChart extends StatefulWidget {
  WgtHistoryBarChart({
    super.key,
    required this.timeKey,
    required this.valKey,
    required this.historyData,
    this.chartData,
    this.chartKey,
    this.border,
    this.reservedSizeLeft,
    this.rereservedSizeBottom,
    this.tooltipTimeFormat,
    this.xTimeFormat = 'MM-dd HH:mm',
    this.xSpace = 8,
    this.skipOddXTitle = false,
    this.skipInterval,
    this.ratio,
    this.title,
    this.showTitle = true,
    this.titleWidget,
    this.yUnit = '',
    this.useK = false,
    this.adjK = false,
    this.yUnitK = '',
    this.yDecimalK = 0,
    this.kThreashold = 100000,
    this.commaSeparated = false,
    this.maxVal,
    this.showKonY,
    this.showEmptyMessage,
    this.toolTipDecimal,
    this.showMaxYValue = false,
    this.dominantIntervalSecond,
    this.altBarTip,
    this.altBarTipKey,
    this.altBarTipIf,
    this.useAltBarColor,
    this.altBarColorIf,
    this.prefixLabelIf,
    this.getPrefixLabel,
    this.getAltVal,
    this.prefixLabel,
    this.yDecimal,
    this.showXTitle = true,
    this.showYTitle = true,
    this.timestampOnSecondLine = false,
    this.stackWidget,
    this.getTooltipXText,
    this.getXText,
    this.bottomTextAngle,
    this.hightlightEmpty = false,
    this.barColor = AppColors.contentColorYellow,
    this.tooltipTextColor = AppColors.contentColorYellow,
    this.tooltipBackgroundColor = AppColors.contentColorYellow,
    this.highlightColor = AppColors.contentColorYellow,
    this.bottomTouchedTextColor = AppColors.contentColorYellow,
    Color? bottomTextColor,
    Color? errorTooltipBackgroundColor,
  })  : errorTooltipBackgroundColor =
            errorTooltipBackgroundColor ?? Colors.redAccent.withOpacity(0.62),
        bottomTextColor =
            bottomTextColor ?? AppColors.contentColorYellow.withOpacity(0.62);

  final List<Map<String, dynamic>> historyData;
  final String timeKey;
  final String valKey;
  final List<FlSpot>? chartData;
  final int? dominantIntervalSecond;
  final int? yDecimal;
  final String yUnit;
  final double? maxVal;
  final bool? showKonY;
  final bool? showEmptyMessage;
  final int? toolTipDecimal;
  final bool showMaxYValue;
  final String? title;
  final bool showTitle;
  final Widget? titleWidget;
  // final double? width;
  final double? reservedSizeLeft;
  final double? rereservedSizeBottom;
  final double? ratio;
  final Color barColor;
  final Color tooltipTextColor;
  final Color tooltipBackgroundColor;
  final Color errorTooltipBackgroundColor;
  final Color highlightColor;
  final Color bottomTextColor;
  final Color bottomTouchedTextColor;
  final Border? border;
  final String? tooltipTimeFormat;
  final String xTimeFormat;
  final double xSpace;
  final bool skipOddXTitle;
  final int? skipInterval;
  final String? altBarTipKey;
  final String? altBarTip;
  final Function? altBarTipIf;
  final bool? useAltBarColor;
  final Function? altBarColorIf;
  final Function? prefixLabelIf;
  final String? prefixLabel;
  final Function? getPrefixLabel;
  final Function? getAltVal;
  final UniqueKey? chartKey;
  final bool showXTitle;
  final bool showYTitle;
  final bool timestampOnSecondLine;
  final bool commaSeparated;
  final bool useK;
  final bool adjK;
  final String yUnitK;
  final int yDecimalK;
  final double kThreashold;
  final Widget? stackWidget;
  final Function? getTooltipXText;
  final Function? getXText;
  final double? bottomTextAngle;
  final bool hightlightEmpty;

  @override
  _WgtHistoryBarChartState createState() => _WgtHistoryBarChartState();
}

class _WgtHistoryBarChartState extends State<WgtHistoryBarChart> {
  UniqueKey? _chartKey;
  double _touchedValue = -1;

  final Duration animDuration = const Duration(milliseconds: 200);

  final bool _fitInsideBottomTitle = false;
  final bool _fitInsideLeftTitle = false;

  bool _errorToolTip = false;

  List<Map<String, int>> _xTitles = [];

  // int dataLength = 0;

  double _maxY = 0;
  double _yGridFactor = 1;

  int yAxisTitleCount = 5;

  int _timeStampStart = 0;
  int _timeStampEnd = 0;

  double _barWidth = 10;
  List<BarChartGroupData> _barGroups = [];

  final List<FlSpot> _chartData = [];
  List<Map<String, dynamic>> _errorData = [];
  List<Map<String, dynamic>> _altBarTipData = [];
  bool _valueIsDouble = false;

  int _yDecimal = 0;

  Widget leftTitles(double value, TitleMeta meta) {
    double max = meta.max;
    if (!widget.showMaxYValue) {
      if (value > 0.999 * max) {
        return Container();
      }
    }
    final style = TextStyle(
      color: widget.bottomTextColor,
      fontSize: 13,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      fitInside: _fitInsideLeftTitle
          ? SideTitleFitInsideData.fromTitleMeta(meta)
          : SideTitleFitInsideData.disable(),
      child: Text(
          // text,
          // yTitles[index],
          // value.toStringAsFixed(widget.yDecimal),
          (widget.showKonY ?? false)
              ? getK(value, widget.yDecimalK)
              : value.toStringAsFixed(_yDecimal),
          style: style,
          textAlign: TextAlign.center),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final isTouched = value == _touchedValue;
    final style = TextStyle(
      color: isTouched ? widget.bottomTouchedTextColor : widget.bottomTextColor,
      // fontWeight: FontWeight.bold,
      fontSize: 13,
    );

    String xTitle = '';
    if (widget.getXText != null) {
      xTitle = widget.getXText!(value.toInt());
    } else {
      if (value.toInt() == _timeStampStart || value.toInt() == _timeStampEnd) {
        return Container();
      }

      //find the index of the value in the xTitles
      int index = -1;
      for (var i = 0; i < _xTitles.length; i++) {
        if (double.parse(_xTitles[i].keys.first).toInt() == value.toInt()) {
          index = i;
          break;
        }
      }
      if (widget.skipInterval != null) {
        if (widget.skipInterval! > 2) {
          if (index > 0 && index % widget.skipInterval! != 0) {
            return Container();
          }
        }
      } else {
        if (index > 0 && (widget.skipOddXTitle) && index % 2 == 1) {
          return Container();
        }
      }
      xTitle = getDateFromDateTimeStr(
          DateTime.fromMillisecondsSinceEpoch(value.toInt()).toString(),
          format: widget.xTimeFormat);
    }

    return SideTitleWidget(
      space: 0,
      axisSide: meta.axisSide,
      fitInside: _fitInsideBottomTitle
          ? SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0)
          : SideTitleFitInsideData.disable(),
      // angle: 4 * pi / 12,
      child: Transform.translate(
        offset: Offset(0, widget.xSpace),
        child: Transform.rotate(
          angle: widget.bottomTextAngle ?? 4 * pi / 12,
          child: Text(
            xTitle, // xTitles[value.toInt()],
            style: style,
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> getBars(int touchedValue) {
    // Color barColor = widget.barColor.withOpacity(0.62);
    // double rodWidth = 0.92 * _chartWidth / dataLength;
    // _rodSpace = 0.08 * _chartWidth / dataLength;
    return [
      for (var i = _chartData.length - 1; i >= 0; i--)
        BarChartGroupData(
          x: _chartData[i].x.toInt(),
          // barsSpace: _rodSpace,
          barRods: [
            BarChartRodData(
              toY: _chartData[i].y,
              width: _barWidth, //rodWidth,
              color: setBarColor(i, touchedValue),
              borderRadius: BorderRadius.circular(3),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _maxY,
                color: Colors.transparent,
              ),
            ),
          ],
          // showingTooltipIndicators: [0],
        ),
    ];
  }

  List<FlSpot> genHistoryChartData(
      List<Map<String, dynamic>> historyData, String timeKey, String valKey,
      {List<Map<String, dynamic>>? errorData,
      List<Map<String, dynamic>>? altBarTipData}) {
    List<FlSpot> chartData = [];

    for (var historyDataItem in historyData) {
      int timestamp =
          DateTime.parse(historyDataItem[timeKey]).millisecondsSinceEpoch;
      chartData.add(FlSpot(
          timestamp.toDouble(),
          _valueIsDouble
              ? historyDataItem[valKey] ?? 0
              : double.parse((historyDataItem[valKey] == null ||
                      historyDataItem[valKey] == 'null')
                  ? '0'
                  : historyDataItem[valKey])));
      if (errorData != null) {
        if (historyDataItem['error_data'] != null) {
          errorData.add({timestamp.toString(): historyDataItem['error_data']});
        }
      }
      if (altBarTipData != null && widget.altBarTipKey != null) {
        if (historyDataItem[widget.altBarTipKey] != null) {
          altBarTipData.add(
              {timestamp.toString(): historyDataItem[widget.altBarTipKey]});
        }
      }
    }
    return chartData;
  }

  Color? setBarColor(int i, int touchedValue) {
    if (widget.altBarColorIf != null) {
      if (widget.altBarColorIf!(i, widget.historyData[i])) {
        return widget.barColor.withOpacity(0.5);
      }
    }

    if (i == _chartData.length - touchedValue - 1) {
      return widget.tooltipBackgroundColor;
      // return widget.highlightColor; //Colors.white;
    }
    Color barColor = widget.barColor.withOpacity(0.67);

    return widget.useAltBarColor ?? false
        ? widget.altBarTipIf != null
            ? widget.altBarTipIf!(_altBarTipData[i].values.first)
                ? widget.barColor.withOpacity(0.5)
                : barColor
            : barColor
        : barColor;
  }

  void _loadChartData() {
    if (widget.historyData.isEmpty) {
      _chartData.clear();
      return;
    }
    bool useWidgetChartData = widget.chartData != null;
    _valueIsDouble = false;
    if (useWidgetChartData) {
      _valueIsDouble = true;
    } else {
      _valueIsDouble = widget.historyData[0][widget.valKey] is double;
    }
    widget.historyData[0][widget.valKey] is double;
    _chartData.clear();
    _chartData.addAll(widget.chartData ??
        genHistoryChartData(widget.historyData, widget.timeKey, widget.valKey,
            errorData: _errorData, altBarTipData: _altBarTipData));

    // _chartWidth = widget.width ?? 900; //0.8 * MediaQuery.of(context).size.width;

    // dataLength = _chartData.length;
    //normalize the data
    List<double> yValues = [];

    for (var i = 0; i < _chartData.length; i++) {
      if (useWidgetChartData) {
        yValues.add(_chartData[i].y);
      } else {
        yValues.add(_valueIsDouble
            ? widget.historyData[i][widget.valKey]
            : double.parse((widget.historyData[i][widget.valKey] == null ||
                    widget.historyData[i][widget.valKey] == 'null')
                ? '0'
                : widget.historyData[i][widget.valKey]));
      }
    }

    _maxY = findMax(yValues);
    _yDecimal = widget.yDecimal ?? decideDisplayDecimal(0.5 * _maxY);
    //_maxY = 0.3, _yGridFactor = 10, _maxY = 0.03, _yGridFactor = 100
    _yGridFactor = 1;
    if (_maxY > 0.1) {
      _yGridFactor = 10;
    } else if (_maxY > 0.01) {
      _yGridFactor = 100;
    } else if (_maxY > 0.001) {
      _yGridFactor = 1000;
    } else if (_maxY > 0.0001) {
      _yGridFactor = 10000;
    } else if (_maxY > 0.00001) {
      _yGridFactor = 100000;
    }

    _timeStampEnd = _chartData[0].x.toInt();
    _timeStampStart = _chartData[_chartData.length - 1].x.toInt();

    //building xTitles
    _xTitles = [];
    for (var i = 0; i < _chartData.length; i++) {
      _xTitles.add(Map.of({_chartData[i].x.toString(): 0}));
    }
    _touchedValue = -1;
  }

  @override
  void initState() {
    super.initState();

    _loadChartData();
    _chartKey = widget.chartKey;
  }

  @override
  Widget build(BuildContext context) {
    // give the bar chart a new key to
    // reload the chart with new data
    if (widget.chartKey != null) {
      if (_chartKey != widget.chartKey) {
        _chartKey = widget.chartKey;
        _loadChartData();
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showTitle)
          widget.titleWidget ??
              (widget.title == null
                  ? Container()
                  : Text(
                      widget.title!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
        AspectRatio(
          aspectRatio: widget.ratio ?? 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 5.0, left: 5.0),
            child: LayoutBuilder(builder: (context, constraints) {
              final barsSpace = 0.08 * constraints.maxWidth / _chartData.length;
              final wAdj = widget.reservedSizeLeft == null
                  ? 0
                  : widget.reservedSizeLeft! - 21;
              final barsWidth =
                  0.85 * (constraints.maxWidth - wAdj) / _chartData.length;

              _barWidth = barsWidth;
              _barGroups = getBars(_touchedValue.toInt());
              // print(widget.key);
              return Stack(
                children: [
                  if (widget.historyData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 89.0),
                        child: Text(
                          'no data for the duration',
                          style: TextStyle(
                              fontSize: getMaxFitFontSize(
                                  constraints.maxWidth * 0.75,
                                  'no data for the duration',
                                  const TextStyle(fontWeight: FontWeight.bold)),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .hintColor
                                  .withOpacity(0.13)),
                        ),
                      ),
                    ),
                  if (widget.maxVal != null &&
                      widget.maxVal == 0 &&
                      _maxY == 0 &&
                      widget.historyData.isNotEmpty &&
                      widget.showEmptyMessage == true)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 89.0),
                        child: Text(
                          'zero values for the duration',
                          style: TextStyle(
                              fontSize: getMaxFitFontSize(
                                  constraints.maxWidth * 0.75,
                                  'zero values for the duration',
                                  const TextStyle(fontWeight: FontWeight.bold)),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .hintColor
                                  .withOpacity(0.13)),
                        ),
                      ),
                    ),
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.center,
                      groupsSpace: barsSpace, //_rodSpace,
                      barGroups: _barGroups,
                      //getData(barsWidth, barsSpace, -1),

                      barTouchData: BarTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              barTouchResponse == null ||
                              barTouchResponse.spot == null) {
                            _touchedValue = -1;
                            setState(() {
                              // _containHighlight = false;
                              _barGroups = getBars(-1);
                            });
                            return;
                          }
                          setState(() {
                            _touchedValue = barTouchResponse
                                .spot!.touchedBarGroupIndex
                                .toDouble();
                          });

                          // setState(() {
                          // _containHighlight = true;
                          // _barGroups = getBars(_touchedValue.toInt());
                          // });
                          // print('touch');
                        },
                        touchTooltipData: BarTouchTooltipData(
                          // tooltipBgColor: _errorToolTip
                          //     ? widget.errorTooltipBackgroundColor
                          //     : widget.tooltipBackgroundColor,
                          tooltipPadding: const EdgeInsets.all(3),
                          tooltipMargin: 6,
                          getTooltipItem: (
                            BarChartGroupData group,
                            int groupIndex,
                            BarChartRodData rod,
                            int rodIndex,
                          ) {
                            // setState(() {
                            //   _errorToolTip = false;
                            // });

                            String errorDataText = '';
                            if (_errorData.isNotEmpty) {
                              // errorDataText = _errorData[rodIndex].values.first;
                              String key = group.x.toInt().toString();
                              Map<String, dynamic> errorData =
                                  getElementMapByKey(_errorData, key);
                              if (errorData.isNotEmpty) {
                                errorDataText = errorData[key];
                                if (errorDataText.isNotEmpty) {
                                  // setState(() {
                                  _errorToolTip = true;
                                  // });
                                }
                              }
                            }
                            String altBarTipValue = '';
                            // String xText = '';
                            if (_altBarTipData.isNotEmpty) {
                              String key = group.x.toInt().toString();
                              Map<String, dynamic> altBarTip =
                                  getElementMapByKey(_altBarTipData, key);
                              if (altBarTip.isNotEmpty) {
                                altBarTipValue = altBarTip[key];
                              }
                            }

                            final xText = widget.getTooltipXText != null
                                ? widget.getTooltipXText!(group.x.toInt())
                                : getDateFromDateTimeStr(
                                    DateTime.fromMicrosecondsSinceEpoch(
                                            group.x.toInt() * 1000)
                                        .toString(),
                                    format: widget.tooltipTimeFormat ??
                                        'MM-dd HH:mm');

                            // if (kDebugMode) {print(group.x);}

                            double theVal = rod.toY;
                            String theUnit = widget.yUnit;
                            int theDecimal = widget.yDecimal ?? _yDecimal;
                            bool useKcase1 = widget.useK;
                            bool useKcase2 =
                                widget.adjK && theVal > widget.kThreashold;

                            if (useKcase1 || useKcase2) {
                              theVal = theVal / 1000;
                              theUnit = widget.yUnitK;
                              theDecimal = widget.yDecimalK;
                            }
                            int index = _chartData.indexWhere((element) =>
                                element.x.toInt() == group.x.toInt());

                            String? yText;
                            if (widget.getAltVal != null) {
                              yText = widget.getAltVal!(
                                  index, widget.historyData[index]);
                            }
                            if (yText == null) {
                              yText = theVal.toStringAsFixed(
                                  widget.toolTipDecimal ?? theDecimal);
                              if (widget.commaSeparated) {
                                yText = getCommaNumberStr(theVal,
                                    decimal:
                                        widget.toolTipDecimal ?? theDecimal);
                              }
                            }
                            if (widget.prefixLabelIf != null) {
                              // String key = group.x.toInt().toString();

                              if (index != -1) {
                                // if (widget.prefixLabelIf!(
                                //     index, widget.historyData[index])) {
                                //   yText = '${widget.prefixLabel ?? ''}$yText';
                                // }

                                if (widget.getPrefixLabel != null) {
                                  yText =
                                      '${widget.getPrefixLabel!(index, widget.historyData[index])}$yText';
                                } else {
                                  yText = '${widget.prefixLabel ?? ''}$yText';
                                }
                              }
                            }

                            return BarTooltipItem(
                              errorDataText.isNotEmpty
                                  ? 'Error Data: $errorDataText'
                                  : altBarTipValue.isNotEmpty
                                      ? widget.altBarTipIf != null
                                          ? widget.altBarTipIf!(altBarTipValue)
                                              ? widget.altBarTip ?? ''
                                              : '$yText$theUnit'
                                          : '$yText$theUnit}'
                                      : '$yText$theUnit',
                              errorDataText.isEmpty
                                  ? TextStyle(
                                      color: widget.tooltipTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)
                                  : TextStyle(
                                      color: Colors.red[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                              children: [
                                TextSpan(
                                  text: widget.timestampOnSecondLine
                                      ? '\n$xText'
                                      : xText,
                                  style: TextStyle(
                                    color: widget.tooltipTextColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                    // fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: widget.showYTitle,
                            reservedSize: widget.showYTitle
                                ? widget.reservedSizeLeft ?? 40
                                : 0,
                            getTitlesWidget: leftTitles,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: widget.showXTitle,
                            reservedSize: widget.showXTitle
                                ? widget.rereservedSizeBottom ?? 40
                                : 0,
                            getTitlesWidget: bottomTitles,
                            // for bar chart, maxX is hard coded to 1
                            // interval is ignored
                            interval: 1,
                          ),
                        ),
                      ),
                      minY: 0,
                      borderData: FlBorderData(
                        show: true,
                        border: widget.border ??
                            Border.all(
                              // color: AppColors.borderColor,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.33),
                            ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        checkToShowHorizontalLine: (value) =>
                            value * _yGridFactor % 1 == 0,
                        checkToShowVerticalLine: (value) => value % 1 == 0,
                        getDrawingHorizontalLine: (value) {
                          if (value == 0) {
                            return const FlLine(
                              color: AppColors.contentColorOrange,
                              strokeWidth: 2,
                            );
                          } else {
                            return FlLine(
                              color: Theme.of(context).hintColor.withOpacity(
                                  0.2), //AppColors.mainGridLineColor,
                              strokeWidth: 0.5,
                            );
                          }
                        },
                        getDrawingVerticalLine: (value) {
                          if (value == 0) {
                            return const FlLine(
                              color: Colors.redAccent,
                              strokeWidth: 10,
                            );
                          } else {
                            return const FlLine(
                              color: AppColors.mainGridLineColor,
                              strokeWidth: 0.5,
                            );
                          }
                        },
                      ),
                    ),
                    // key: UniqueKey(),
                  ),
                  widget.stackWidget ?? Container(),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

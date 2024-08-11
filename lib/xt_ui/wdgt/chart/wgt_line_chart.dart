import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../style/app_colors.dart';
import '../xtInfoBox.dart';

class WgtLineChart extends StatefulWidget {
  const WgtLineChart({
    super.key,
    required this.xKey,
    required this.yKey,
    this.width,
    this.xAxisName,
    this.yAxisName,
    required this.dataSets,
    this.legend,
    this.chartRatio = 1.5,
    this.isCurved = false,
    this.fitInsideBottomTitle = false,
    this.fitInsideTopTitle = false,
    this.fitInsideLeftTitle = false,
    this.fitInsideRightTitle = false,
    this.showLeftTitle = true,
    this.showRightTitle = true,
    this.showTopTitle = true,
    this.showBottomTitle = true,
    this.reservedSizeLeft,
    this.reservedSizeRight,
    this.reservedSizeTop,
    this.reservedSizeBottom,
    this.xColor,
    this.yColor,
    this.xTitleStyle,
    this.yTitleStyle,
    this.showBottomAxisName = true,
    this.showLeftAxisName = true,
    this.yDecimal = 0,
    this.valUnit = '',
    this.getTooltipText,
    Color? tooltipTextColor,
  }) : tooltipTextColor = tooltipTextColor ?? AppColors.contentColorYellow;

  final String xKey;
  final String yKey;
  final String? xAxisName;
  final String? yAxisName;
  final List<Map<String, List<Map<String, dynamic>>>> dataSets;
  final List<Map<String, dynamic>>? legend;
  final double chartRatio;
  final double? width;
  final bool isCurved;
  final bool fitInsideBottomTitle;
  final bool fitInsideTopTitle;
  final bool fitInsideLeftTitle;
  final bool fitInsideRightTitle;
  final bool showLeftTitle;
  final bool showRightTitle;
  final bool showTopTitle;
  final bool showBottomTitle;
  final double? reservedSizeLeft;
  final double? reservedSizeRight;
  final double? reservedSizeTop;
  final double? reservedSizeBottom;
  final Color? xColor;
  final Color? yColor;
  final TextStyle? xTitleStyle;
  final TextStyle? yTitleStyle;
  final bool showBottomAxisName;
  final bool showLeftAxisName;
  final int yDecimal;
  final String valUnit;
  final String Function(double, String)? getTooltipText;
  final Color tooltipTextColor;

  @override
  State<WgtLineChart> createState() => _WgtLineChartState();
}

class _WgtLineChartState extends State<WgtLineChart> {
  double _maxY = 0;
  double _minY = double.infinity;
  double _range = 0;
  List<LineChartBarData> _chartDataSets = [];
  List<Map<String, int>> _xTitles = [];

  List<FlSpot> genHistoryChartData(
      List<Map<String, dynamic>> historyData, String xKey, String yKey,
      {List<Map<String, dynamic>>? errorData}) {
    List<FlSpot> chartData = [];
    Map<String, dynamic> firstData = historyData.first;
    // bool isDouble = firstData[yKey] is double;
    // _maxY = 0;
    // _minY = double.infinity;
    for (var historyDataItem in historyData) {
      double xVal = historyDataItem[xKey] is double
          ? historyDataItem[xKey]
          : historyDataItem[xKey] is int
              ? historyDataItem[xKey].toDouble()
              : double.parse(historyDataItem[xKey]);
      double value = historyDataItem[yKey] is double
          ? historyDataItem[yKey]
          : historyDataItem[yKey] is int
              ? historyDataItem[yKey].toDouble()
              : double.parse(historyDataItem[yKey]);
      if (value > _maxY) {
        _maxY = value;
      }
      if (value < _minY) {
        _minY = value;
      }
      chartData.add(FlSpot(xVal, value));
      if (errorData != null) {
        if (historyDataItem['error_data'] != null) {
          errorData.add({
            'x': xVal.toInt(),
            'y': value.toInt(),
            'error': historyDataItem['error_data']
          });
        }
      }
    }
    return chartData;
  }

  void _loadChartData() {
    _chartDataSets = [];

    int i = 0;
    for (var historyDataInfo in widget.dataSets) {
      Color? lineColor;
      if (widget.legend != null) {
        for (var legendItem in widget.legend!) {
          if (legendItem['name'] == historyDataInfo.keys.first) {
            lineColor = legendItem['color'];
          }
        }
      }

      for (List<Map<String, dynamic>> historyData
          in historyDataInfo.values.toList()) {
        Color color = lineColor ??
            AppColors.tier1colorsAlt[i > 8 ? 8 : i].withOpacity(0.8);
        i++;
        List<FlSpot> chartData = genHistoryChartData(
            historyData, widget.xKey, widget.yKey,
            errorData: []);

        //building xTitles
        _xTitles = [];
        int dataLength = chartData.length;
        for (var i = 0; i < dataLength; i++) {
          _xTitles.add(Map.of({chartData[i].x.toString(): 0}));
        }

        _chartDataSets.add(LineChartBarData(
          isCurved: widget.isCurved,
          color: color,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
              show: false,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: color,
                );
              }),
          belowBarData: BarAreaData(show: false),
          spots: chartData,
        ));
      }
    }
    _range = _maxY - _minY;
    if (_range == 0) {
      _range = 0.1 * _minY; //widget.minY;
    }
  }

  List<LineTooltipItem?> getToolTipItems(List<LineBarSpot> touchedBarSpots) {
    List<double> yValues = [];
    for (var tbs in touchedBarSpots) {
      yValues.add(tbs.y);
    }
    double yMin = yValues.reduce(min);
    return touchedBarSpots.map((barSpot) {
      final flSpot = barSpot;

      TextAlign textAlign;
      switch (flSpot.x.toInt()) {
        case 1:
          textAlign = TextAlign.left;
          break;
        case 5:
          textAlign = TextAlign.right;
          break;
        default:
          textAlign = TextAlign.center;
      }

      Color? textColor;
      if (widget.legend != null) {
        textColor = widget.legend![barSpot.barIndex]['color'];
      }

      String text =
          '${flSpot.y.toStringAsFixed(widget.yDecimal)}${widget.valUnit}';
      if (widget.getTooltipText != null) {
        text = widget.getTooltipText!(flSpot.y, '');
      }
      return LineTooltipItem(
        text,
        TextStyle(
          color: textColor ?? widget.tooltipTextColor,
          fontWeight: FontWeight.bold,
        ),
        children: [],
        textAlign: textAlign,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _loadChartData();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        getLegend(),
        AspectRatio(
          aspectRatio: widget.chartRatio,
          child: LineChart(
            LineChartData(
              minY: widget.dataSets.isEmpty
                  ? 0
                  : _minY < 0
                      ? _minY - 0.5 * _range
                      : _minY - 0.5 * _range > 0
                          ? _minY - 0.5 * _range
                          : 0,
              maxY: widget.dataSets.isEmpty ? 0 : _maxY + 0.34 * _range,
              lineBarsData: _chartDataSets,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: getToolTipItems,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: widget.showTopTitle,
                    reservedSize: widget.reservedSizeTop ?? 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameSize: 20,
                  axisNameWidget: widget.showBottomAxisName
                      ? Text(
                          widget.xAxisName ?? widget.xKey,
                          style: widget.xTitleStyle ??
                              TextStyle(color: widget.xColor ?? Colors.blue),
                        )
                      : null,
                  sideTitles: SideTitles(
                    showTitles: widget.showBottomTitle,
                    reservedSize: widget.reservedSizeBottom ?? 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameSize: 20,
                  axisNameWidget: widget.showLeftAxisName
                      ? Text(
                          widget.yAxisName ?? widget.yKey,
                          style: widget.yTitleStyle ??
                              TextStyle(color: widget.yColor ?? Colors.blue),
                        )
                      : null,
                  sideTitles: SideTitles(
                    showTitles: widget.showLeftTitle,
                    reservedSize: widget.reservedSizeLeft ?? 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(widget.yDecimal),
                        style: widget.yTitleStyle ??
                            const TextStyle(
                              color: Colors.blue,
                              fontSize: 13.5,
                            ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: widget.showRightTitle,
                    reservedSize: widget.reservedSizeRight ?? 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(widget.yDecimal),
                        style: widget.yTitleStyle ??
                            const TextStyle(
                              color: Colors.blue,
                              fontSize: 13.5,
                            ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget getLegend() {
    if (widget.legend == null) {
      return Container();
    }
    return widget.legend!.length <= 1
        ? Container()
        : Padding(
            padding: const EdgeInsets.only(left: 3, right: 3, bottom: 10),
            child: Row(
              children: [
                for (var item in widget.legend!)
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
}

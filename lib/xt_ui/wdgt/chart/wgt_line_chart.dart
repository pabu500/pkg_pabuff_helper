import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../style/app_colors.dart';

class WgtLineChart extends StatefulWidget {
  const WgtLineChart({
    Key? key,
    required this.xKey,
    required this.yKey,
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
  }) : super(key: key);

  final String xKey;
  final String yKey;
  final String? xAxisName;
  final String? yAxisName;
  final List<Map<String, List<Map<String, dynamic>>>> dataSets;
  final List<Map<String, dynamic>>? legend;
  final double chartRatio;
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
    _maxY = 0;
    _minY = double.infinity;
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

  @override
  Widget build(BuildContext context) {
    _loadChartData();
    return AspectRatio(
      aspectRatio: widget.chartRatio,
      child: LineChart(
        LineChartData(
          lineBarsData: _chartDataSets,
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
              axisNameWidget: Text(
                widget.xAxisName ?? widget.xKey,
                style: TextStyle(
                    color:
                        widget.xColor ?? Colors.blue //AppColors.mainTextColor2,
                    ),
              ),
              sideTitles: SideTitles(
                showTitles: widget.showBottomTitle,
                reservedSize: widget.reservedSizeBottom ?? 40,
              ),
            ),
            leftTitles: AxisTitles(
              axisNameSize: 20,
              axisNameWidget: Text(
                widget.yAxisName ?? widget.yKey,
                style: TextStyle(color: widget.yColor ?? Colors.blue
                    //AppColors.mainTextColor2,
                    ),
              ),
              sideTitles: SideTitles(
                showTitles: widget.showLeftTitle,
                reservedSize: widget.reservedSizeLeft ?? 40,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: widget.showRightTitle,
                reservedSize: widget.reservedSizeRight ?? 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

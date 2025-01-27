// import 'package:evs2op/ext/fl_chart/resources/app_resources.dart';
import 'dart:math';

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WgtMultiParaBarChart extends StatefulWidget {
  WgtMultiParaBarChart({
    super.key,
    this.chartKey,
    required this.chartData,
    this.ratio = 2.1,
    this.maxY,
    this.skipOddXTitle = false,
    this.skipInterval,
    this.xTimeFormat = 'MM-dd HH:mm',
    this.tooltipTimeFormat,
    this.timestampOnSecondLine = false,
    this.xSpace = 8,
    this.yUnit = '',
    this.useK = false,
    this.adjK = false,
    this.yUnitK = '',
    this.yDecimalK = 0,
    this.kThreashold = 100000,
    this.commaSeparated = false,
    this.maxVal,
    this.showKonY,
    this.barWidth = 5,
    this.barSpace = 3,
    this.yDecimal = 0,
    this.showMaxYValue = false,
    this.showXTitle = true,
    this.showYTitle = true,
    this.reservedSizeLeft,
    this.rereservedSizeBottom,
    this.bottomTextAngle,
    this.hideEdgeXTitle = true,
    this.xLabelWidth,
    this.xOffset,
    Color? barColor,
    Color? tooltipTextColor,
    Color? tooltipTimeColor,
    Color? tooltipBackgroundColor,
    Color? errorTooltipBackgroundColor,
    Color? highlightColor,
    Color? bottomTextColor,
    Color? bottomTouchedTextColor,
  })  : barColor = barColor ?? AppColors.contentColorYellow,
        tooltipTextColor = tooltipTextColor ?? AppColors.contentColorYellow,
        tooltipTimeColor = tooltipTimeColor ?? AppColors.contentColorYellow,
        tooltipBackgroundColor = tooltipBackgroundColor ??
            AppColors.contentColorYellow.withAlpha(160),
        errorTooltipBackgroundColor =
            errorTooltipBackgroundColor ?? Colors.redAccent.withAlpha(160),
        highlightColor = highlightColor ?? AppColors.contentColorYellow,
        bottomTextColor =
            bottomTextColor ?? AppColors.contentColorYellow.withAlpha(160),
        bottomTouchedTextColor =
            bottomTouchedTextColor ?? AppColors.contentColorYellow;

  final UniqueKey? chartKey;
  final double ratio;
  final Color barColor;
  final Color tooltipTextColor;
  final Color tooltipTimeColor;
  final Color tooltipBackgroundColor;
  final Color errorTooltipBackgroundColor;
  final Color highlightColor;
  final Color bottomTextColor;
  final Color bottomTouchedTextColor;
  final String? tooltipTimeFormat;
  final List<Map<String, dynamic>> chartData;
  final double barWidth;
  final double barSpace;
  final double? maxY;
  final String xTimeFormat;
  final double xSpace;
  final bool skipOddXTitle;
  final int? skipInterval;
  final String yUnit;
  final bool useK;
  final bool adjK;
  final String yUnitK;
  final int yDecimalK;
  final double kThreashold;
  final bool commaSeparated;
  final double? maxVal;
  final bool? showKonY;
  final int yDecimal;
  final bool showMaxYValue;
  final bool showXTitle;
  final bool showYTitle;
  final double? reservedSizeLeft;
  final double? rereservedSizeBottom;
  final double? bottomTextAngle;
  final bool hideEdgeXTitle;
  final bool timestampOnSecondLine;
  final double? xLabelWidth;
  final Offset? xOffset;

  final Color avgColor = Colors.orange;
  @override
  State<StatefulWidget> createState() => WgtMultiParaBarChartState();
}

class WgtMultiParaBarChartState extends State<WgtMultiParaBarChart> {
  UniqueKey? _chartKey;
  final double width = 7;

  late final List<BarChartGroupData> _rawBarGroups;
  late List<BarChartGroupData> _showingBarGroups;

  int _touchedGroupIndex = -1;

  late double _maxY;
  int _timeStampStart = 0;
  int _timeStampEnd = 0;
  List<Map<String, dynamic>> _xTitles = [];
  final bool _fitInsideBottomTitle = false;
  final bool _fitInsideLeftTitle = false;

  void _loadChartData() {
    _rawBarGroups.clear();
    for (Map<String, dynamic> groupBars in widget.chartData) {
      int x = groupBars['x'];
      List<Map<String, dynamic>> groupBarList = groupBars['groupBarList'];
      final barGroup = _makeGropData(x, groupBarList);
      _rawBarGroups.add(barGroup);
    }

    _timeStampEnd = _rawBarGroups[0].x.toInt();
    _timeStampStart = _rawBarGroups[_rawBarGroups.length - 1].x.toInt();

    double maxY = 0;
    for (var group in _rawBarGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) {
          maxY = rod.toY;
        }
      }
    }
    _maxY = maxY;
    _showingBarGroups = _rawBarGroups;

    //building xTitles
    _xTitles = [];
    int dataLength = widget.chartData.length;
    for (var i = 0; i < dataLength; i++) {
      Map<String, dynamic> groupBars = widget.chartData[i];
      int x = groupBars['x'];
      if (groupBars['label'] != null) {
        _xTitles.add({x.toString(): groupBars['label']});
      } else {
        _xTitles.add({x.toString(): x});
      }
    }
  }

  BarChartGroupData _makeGropData(
      int x, List<Map<String, dynamic>> groupBarList) {
    List<BarChartRodData> barRods = [];
    for (Map<String, dynamic> groupBars in groupBarList) {
      barRods.add(BarChartRodData(
        toY: groupBars['y'] as double,
        color: groupBars['color'] as Color,
        width: widget.barWidth,
      ));
    }
    return BarChartGroupData(
      barsSpace: widget.barSpace,
      x: x,
      barRods: barRods,
    );
  }

  @override
  void initState() {
    super.initState();

    _rawBarGroups = [];
    _showingBarGroups = [];
    _loadChartData();
    _chartKey = widget.chartKey;

    _showingBarGroups = _rawBarGroups;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chartKey != null) {
      if (_chartKey != widget.chartKey) {
        _chartKey = widget.chartKey;
        _loadChartData();
      }
    }
    return AspectRatio(
      aspectRatio: widget.ratio,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            verticalSpaceTiny,
            // Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: <Widget>[
            //     makeTransactionsIcon(),
            //     const SizedBox(
            //       width: 38,
            //     ),
            //     const Text(
            //       'Transactions',
            //       style: TextStyle(color: Colors.white, fontSize: 22),
            //     ),
            //     const SizedBox(
            //       width: 4,
            //     ),
            //     const Text(
            //       'state',
            //       style: TextStyle(color: Color(0xff77839a), fontSize: 16),
            //     ),
            //   ],
            // ),
            // const SizedBox(
            //   height: 38,
            // ),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: widget.maxY ?? _maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      // tooltipBgColor: Colors.grey,
                      // getTooltipItem: (a, b, c, d) => null,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String yValue =
                            rod.toY.toStringAsFixed(widget.yDecimal);

                        final timeText = getDateFromDateTimeStr(
                            DateTime.fromMicrosecondsSinceEpoch(
                                    group.x.toInt() * 1000)
                                .toString(),
                            format: widget.tooltipTimeFormat ?? 'MM-dd HH:mm');

                        return BarTooltipItem(
                          yValue + widget.yUnit,
                          TextStyle(
                            color: widget.tooltipTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: widget.timestampOnSecondLine
                                  ? '\n$timeText'
                                  : ' $timeText',
                              style: TextStyle(
                                color: widget.tooltipTimeColor,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                // fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, response) {
                      if (response == null || response.spot == null) {
                        setState(() {
                          _touchedGroupIndex = -1;
                          _showingBarGroups = List.of(_rawBarGroups);
                        });
                        return;
                      }

                      _touchedGroupIndex = response.spot!.touchedBarGroupIndex;

                      setState(() {
                        if (!event.isInterestedForInteractions) {
                          _touchedGroupIndex = -1;
                          _showingBarGroups = List.of(_rawBarGroups);
                          return;
                        }
                        _showingBarGroups = List.of(_rawBarGroups);
                        if (_touchedGroupIndex != -1) {
                          var sum = 0.0;
                          for (final rod
                              in _showingBarGroups[_touchedGroupIndex]
                                  .barRods) {
                            sum += rod.toY;
                          }
                          final avg = sum /
                              _showingBarGroups[_touchedGroupIndex]
                                  .barRods
                                  .length;

                          _showingBarGroups[_touchedGroupIndex] =
                              _showingBarGroups[_touchedGroupIndex].copyWith(
                            barRods: _showingBarGroups[_touchedGroupIndex]
                                .barRods
                                .map((rod) {
                              return rod.copyWith(
                                  toY: avg, color: widget.avgColor);
                            }).toList(),
                          );
                        }
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: widget.showXTitle,
                        getTitlesWidget: bottomTitles,
                        reservedSize: widget.showXTitle
                            ? widget.rereservedSizeBottom ?? 22
                            : 0,
                        // interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: widget.showYTitle,
                        reservedSize: widget.showYTitle
                            ? widget.reservedSizeLeft ?? 40
                            : 0,
                        interval: widget.showYTitle ? null : 100000000,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _showingBarGroups,
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          widget.showKonY != null
              ? widget.showKonY!
                  ? getK(value, widget.yDecimalK)
                  : value.toStringAsFixed(widget.yDecimal)
              : value.toStringAsFixed(widget.yDecimal),
          style: style,
          textAlign: TextAlign.center),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final isTouched = value == _touchedGroupIndex;
    final style = TextStyle(
      color: isTouched ? widget.bottomTouchedTextColor : widget.bottomTextColor,
      // fontWeight: FontWeight.bold,
      fontSize: 13,
    );

    if (widget.hideEdgeXTitle) {
      if (_timeStampEnd > 0 && _timeStampStart > 0) {
        if (value.toInt() == _timeStampStart ||
            value.toInt() == _timeStampEnd) {
          return Container();
        }
      }
    }

    //find the index of the value in the xTitles
    int index = -1;
    String? label;
    for (var i = 0; i < _xTitles.length; i++) {
      String key = _xTitles[i].keys.first;

      dynamic labelVal = _xTitles[i][key];
      if (labelVal is String) {
        label = labelVal;
      }
      if (double.parse(key).toInt() == value.toInt()) {
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

    // String xTitle = "";
    //check if the value is present in the xTitles as a value
    // for (Map<String, int> titleTime in _xTitles) {
    //   if (titleTime.values.first == value.toInt()) {
    //     xTitle = getDateFromDateTimeStr(titleTime.keys.first, format: "MM-dd");
    //     break;
    //   }
    // }
    String xTitle = label ??
        getDateFromDateTimeStr(
            DateTime.fromMillisecondsSinceEpoch(value.toInt()).toString(),
            format: widget.xTimeFormat);

    return SideTitleWidget(
      space: 0,
      axisSide: meta.axisSide,
      fitInside: _fitInsideBottomTitle
          ? SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0)
          : SideTitleFitInsideData.disable(),
      // angle: 4 * pi / 12,
      child: Transform.translate(
        offset: widget.xOffset ?? Offset(0, widget.xSpace),
        child: Transform.rotate(
          angle: widget.bottomTextAngle ?? 4 * pi / 12,
          child: Container(
            width: widget.xLabelWidth,
            alignment: Alignment.centerLeft,
            child: Text(
              xTitle, // xTitles[value.toInt()],
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

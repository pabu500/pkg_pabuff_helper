import 'dart:math';

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WgtMultiParaBarChart extends StatefulWidget {
  WgtMultiParaBarChart({
    super.key,
    this.chartKey,
    required this.chartData,
    this.groupType = 'group', // 'group' or 'stack'
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
    this.barWidth,
    this.barSpace,
    this.yDecimal = 0,
    this.showMaxYValue = false,
    this.showXTitle = true,
    this.showYTitle = true,
    this.reservedSizeLeft,
    this.rereservedSizeBottom,
    this.reservedSizeRight,
    this.bottomTextAngle,
    this.hideEdgeXTitle = true,
    this.xLabelWidth,
    this.xOffset,
    this.padding = const EdgeInsets.all(0),
    this.barColorList,
    this.showBorder = false,
    this.borderColor,
    this.border,
    this.showGrid = false,
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
  final String groupType;
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
  final double? barWidth;
  final double? barSpace;
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
  final double? reservedSizeRight;
  final double? bottomTextAngle;
  final bool hideEdgeXTitle;
  final bool timestampOnSecondLine;
  final double? xLabelWidth;
  final Offset? xOffset;
  final EdgeInsets padding;
  final List<Color>? barColorList;
  final bool showBorder;
  final Border? border;
  final Color? borderColor;
  final bool showGrid;
  final Color avgColor = Colors.orange;
  @override
  State<StatefulWidget> createState() => WgtMultiParaBarChartState();
}

class WgtMultiParaBarChartState extends State<WgtMultiParaBarChart> {
  UniqueKey? _chartKey;
  final double width = 7;

  double? _chartWidth;

  final List<BarChartGroupData> _rawBarGroups = [];
  List<BarChartGroupData> _showingBarGroups = [];

  int _touchedGroupIndex = -1;

  late double _maxY;
  int _timeStampStart = 0;
  int _timeStampEnd = 0;
  List<Map<String, dynamic>> _xTitles = [];
  final bool _fitInsideBottomTitle = false;
  final bool _fitInsideLeftTitle = false;

  late double _barWidth = widget.barWidth ?? 5;

  void _loadChartData() {
    _rawBarGroups.clear();

    for (Map<String, dynamic> groupBars in widget.chartData) {
      int x = groupBars['x'];
      List<Map<String, dynamic>> groupBarList = groupBars['groupBarList'];

      bool useColorList = false;
      if (widget.barColorList != null) {
        if (widget.barColorList!.length == groupBarList.length) {
          useColorList = true;
        }
      }

      final barGroup = widget.groupType == 'group'
          ? _makeGroupData(x, groupBarList)
          : _makeStackGroupData(x, groupBarList, useColorList);
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
    _showingBarGroups.clear();
    _showingBarGroups.addAll(_rawBarGroups);

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

  BarChartGroupData _makeGroupData(
      int x, List<Map<String, dynamic>> groupBarList) {
    List<BarChartRodData> barRods = [];
    for (Map<String, dynamic> groupBars in groupBarList) {
      barRods.add(BarChartRodData(
        toY: groupBars['y'] as double,
        color: groupBars['color'] as Color,
        width: widget.barWidth ?? 5,
      ));
    }
    return BarChartGroupData(
      barsSpace: widget.barSpace,
      x: x,
      barRods: barRods,
    );
  }

  BarChartGroupData _makeStackGroupData(
      int x, List<Map<String, dynamic>> groupBarList, bool useColorList) {
    List<BarChartRodData> barRods = [];
    double toY = 0;
    for (Map<String, dynamic> groupBars in groupBarList) {
      if (groupBars['y'] as double > toY) {
        toY = groupBars['y'] as double;
      }
    }

    List<BarChartRodStackItem> rodStackItems = [];
    for (Map<String, dynamic> groupBars in groupBarList) {
      BarChartRodStackItem rodStackItem = BarChartRodStackItem(
        0,
        groupBars['y'] as double,
        useColorList
            ? widget.barColorList![groupBarList.indexOf(groupBars)]
            : groupBars['color'] as Color,
      );

      rodStackItems.add(rodStackItem);
    }

    BarChartRodData barData = BarChartRodData(
      toY: toY,
      width: _barWidth,
      rodStackItems: rodStackItems,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(3),
        topRight: Radius.circular(3),
      ),
    );
    barRods.add(barData);

    return BarChartGroupData(
      x: x,
      barsSpace: widget.barSpace,
      barRods: barRods,
    );
  }

  @override
  void initState() {
    super.initState();

    // _rawBarGroups = [];
    // _showingBarGroups = [];
    // _loadChartData();
    _chartKey = widget.chartKey;
    // _showingBarGroups = _rawBarGroups;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chartKey != null) {
      if (_chartKey != widget.chartKey) {
        _chartKey = widget.chartKey;
        _loadChartData();
        // Timer(const Duration(milliseconds: 100), () {
        //   setState(() {});
        // });
      }
    }

    return AspectRatio(
      aspectRatio: widget.ratio,
      child: Padding(
        padding: widget.padding,
        child: LayoutBuilder(builder: (context, constraints) {
          if (_chartWidth == null && constraints.maxWidth > 0) {
            int barCount = widget.chartData.length;
            _chartWidth = constraints.maxWidth;
            final barsSpace = widget.barSpace ?? 0.08 * _chartWidth! / barCount;
            final wAdj = widget.reservedSizeLeft ?? 0.0;
            _barWidth = ((_chartWidth! - wAdj) / barCount) - barsSpace;

            _loadChartData();
          }

          // barGroups = getBars(_touchedGroupIndex.toInt(), barWidth: barsWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              verticalSpaceTiny,
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: _showingBarGroups,
                    maxY: widget.maxY ?? _maxY,
                    borderData: FlBorderData(
                      show: widget.showBorder,
                      border: widget.border ??
                          Border.all(
                            color: widget.borderColor ??
                                Theme.of(context).hintColor,
                            width: 1,
                          ),
                    ),
                    gridData: FlGridData(
                      show: widget.showGrid,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                    ),
                    barTouchData: BarTouchData(
                      touchCallback: (FlTouchEvent event, response) {
                        if (response == null || response.spot == null) {
                          setState(() {
                            _touchedGroupIndex = -1;
                            _showingBarGroups = List.of(_rawBarGroups);
                          });
                          return;
                        }

                        _touchedGroupIndex =
                            response.spot!.touchedBarGroupIndex;

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
                                  toY: widget.groupType == 'group'
                                      ? avg
                                      : rod.toY,
                                  color: widget.groupType == 'group'
                                      ? widget.avgColor
                                      : rod.color,
                                  borderSide: BorderSide(
                                    color: widget.avgColor,
                                    width: 1.5,
                                  ),
                                  // width: _barWidth + 5,
                                );
                              }).toList(),
                            );

                            int a = 1;
                          }
                        });
                      },
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
                              format:
                                  widget.tooltipTimeFormat ?? 'MM-dd HH:mm');

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
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: widget.reservedSizeRight ?? 0,
                          getTitlesWidget: rightTitles,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
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
                  ),
                ),
              ),
            ],
          );
        }),
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

  Widget rightTitles(double value, TitleMeta meta) {
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
      child: Text(' ', style: style, textAlign: TextAlign.center),
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

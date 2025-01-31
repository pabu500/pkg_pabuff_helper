import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'wgt_pie_chart_item_indicator.dart';

class WgtPieChart extends StatefulWidget {
  const WgtPieChart({
    super.key,
    required this.chartData,
    this.width,
    this.height,
    this.pieSize,
    this.pieYOffset = 0,
    this.centerSize,
    this.sectionRadius,
    this.sectionRadiusIfTouched,
    this.sectionOpacity = 0.7,
    this.centerInfo,
    this.showIndicator = true,
    this.indicatorWidth = 100,
    this.indicatorHeight,
    this.valueDecimal,
    this.valueUnit,
    this.maxIdicators,
    this.percentageCap,
    this.onIdicatorTap,
    this.indicator2Lines = false,
    this.onSectionTap,
    this.backgoundColor,
    this.currentIndicatorIndex,
    this.currentIndicatorColor,
    this.currentIndicatorLabelColor,
    this.currentIndicatorValueColor,
    this.currentIndicatorArrowColor,
    this.indicatorColor,
    this.indicatorValueColor,
    this.leftPadding,
    this.middlePadding = 0,
    this.rightPadding,
    this.titleWidget,
    this.getColorList,
    this.startDegreeOffset,
    this.showLabel = true,
    this.showTouchedLabel = true,
    this.defaultShowLabel = true,
    this.minLabelSize = 9,
    this.maxLabelSize = 18,
    this.labelBaseColor,
    this.indicatorOffset = 0,
    this.getBorderSide,
    this.getGradient,
    this.enableTouch = true,
    this.flipX = false,
    this.titlePositionPercentageOffset,
  });
  final List<Map<String, dynamic>> chartData;
  final double? width;
  final double? height;
  final Color? backgoundColor;
  final double? pieSize;
  final double pieYOffset;
  final double? centerSize;
  final double? sectionRadius;
  final double? sectionRadiusIfTouched;
  final double sectionOpacity;
  final Widget? centerInfo;
  final bool showIndicator;
  final double indicatorWidth;
  final double? indicatorHeight;
  final int? valueDecimal;
  final String? valueUnit;
  final int? maxIdicators;
  final double? percentageCap;
  final Function? onIdicatorTap;
  final bool indicator2Lines;
  final Function? onSectionTap;
  final int? currentIndicatorIndex;
  final Color? currentIndicatorColor;
  final Color? currentIndicatorLabelColor;
  final Color? currentIndicatorValueColor;
  final Color? currentIndicatorArrowColor;
  final Color? indicatorColor;
  final Color? indicatorValueColor;
  final double? leftPadding;
  final double middlePadding;
  final double? rightPadding;
  final Widget? titleWidget;
  final double? startDegreeOffset;
  final bool showLabel;
  final bool showTouchedLabel;
  final List<Color> Function()? getColorList;
  final bool defaultShowLabel;
  final double minLabelSize;
  final double maxLabelSize;
  final Color? labelBaseColor;
  final double indicatorOffset;
  final BorderSide? Function(int)? getBorderSide;
  final Gradient? Function(int)? getGradient;
  final bool enableTouch;
  final bool flipX;
  final double? titlePositionPercentageOffset;

  @override
  State<StatefulWidget> createState() => WgtPieChartState();
}

class WgtPieChartState extends State<WgtPieChart> {
  int touchedIndex = -1;
  List<Color> _listColor = [];
  // _listColor = AppColors.getColorList(widget.chartData.length);

  @override
  void initState() {
    super.initState();
    if (widget.chartData.isEmpty) {
      return;
    }
    if (widget.chartData[0].containsKey('color')) {
      _listColor = widget.chartData.map((e) => e['color'] as Color).toList();
    } else {
      if (widget.getColorList != null) {
        _listColor = widget.getColorList!();
      } else {
        _listColor = AppColors.getColorList(widget.chartData.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double pieWidth = widget.pieSize ?? (widget.centerSize ?? 100) * 3.4;
    double middleWidth = widget.showIndicator ? widget.middlePadding : 0;
    double rightWidth = widget.showIndicator ? widget.indicatorWidth : 0;
    double widgetWidth =
        pieWidth + middleWidth + rightWidth + widget.indicatorOffset;
    return Container(
      width: widget.width ?? widgetWidth,
      height: widget.height ?? widgetWidth,
      color: widget.backgoundColor ?? Colors.transparent,
      child: widget.chartData.isEmpty
          ? const Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: AppColors.mainTextColor2,
                  fontSize: 16,
                ),
              ),
            )
          : getWidget(),
    );
  }

  Widget getWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.titleWidget ?? Container(),
        Transform.translate(
          offset: Offset(0, widget.pieYOffset),
          child: Row(
            // NOTE: the below line wil break the touch behavior
            // mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: widget.leftPadding ?? 0),
              Expanded(
                // fit: FlexFit.loose,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: widget.centerSize,
                          sectionsSpace: 0.5,
                          sections: showingSections(),
                          startDegreeOffset: widget.startDegreeOffset ?? -90,
                          pieTouchData: PieTouchData(
                            enabled: widget.enableTouch,
                            touchCallback: !widget.enableTouch
                                ? null
                                : (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      // print('isInterestedForInteractions: ${event.isInterestedForInteractions}');
                                      // print('pieTouchResponse == null: ${pieTouchResponse == null}');
                                      // print('pieTouchResponse.touchedSection == null: ${pieTouchResponse?.touchedSection == null}');
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        // if (kDebugMode) {
                                        //   print('0 isInterestedForInteractions: ${event.isInterestedForInteractions}');
                                        // }
                                        if (!event
                                                .isInterestedForInteractions &&
                                            pieTouchResponse == null) {
                                          //tested behavior: triggered by click
                                          if (kDebugMode) {
                                            print('click 0');
                                          }
                                          if (touchedIndex != -1) {
                                            if (kDebugMode) {
                                              print(
                                                  'touchedIndex 0: $touchedIndex');
                                            }
                                            widget.onSectionTap
                                                ?.call(touchedIndex);
                                          }
                                        }

                                        if (kDebugMode) {
                                          //tested behavior: triggered by click or moving out
                                          print('click/moving out');
                                        }

                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                      // if (kDebugMode) {
                                      //   print('touchedIndex 1: $touchedIndex');
                                      // }
                                      // if (touchedIndex == -1) return;

                                      // if (widget.hoverClick == 1) {
                                      //   if (event
                                      //       .isInterestedForInteractions) {
                                      //     if (widget.onSectionTap != null) {
                                      //       widget.onSectionTap!(
                                      //           touchedIndex);
                                      //     }
                                      //   }
                                      // }

                                      // if (widget.onSectionTap != null) {
                                      //   widget.onSectionTap!(touchedIndex);
                                      // }

                                      // if (touchedIndex == -1) return;
                                      // widget.onSectionTap == null
                                      //     ? null
                                      //     : widget.onSectionTap!(touchedIndex);
                                      // print('touchedIndex: $touchedIndex');
                                      // show popup label
                                      // showPopupLabel(
                                      //     widget.chartData[touchedIndex]['label'],
                                      //     widget.chartData[touchedIndex]['value']);
                                    });
                                  },
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                        ),
                      ),
                      Center(
                        child: widget.centerInfo ?? Container(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: widget.middlePadding),
              widget.showIndicator
                  ? SizedBox(
                      width: widget.indicatorWidth,
                      height: widget.indicatorHeight,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: getIndicators(),
                          ),
                        ),
                      ),
                    )
                  : Container(),
              SizedBox(
                width: widget.rightPadding ?? 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.chartData.length, (i) {
      final isTouched = i == touchedIndex;
      // final fontSize = isTouched ? 25.0 : 16.0;
      // if (kDebugMode) {
      //   print('i $i, touchedIndex $touchedIndex');
      // }
      final double radius = isTouched
          ? widget.sectionRadiusIfTouched ??
              (widget.centerSize == null ? 50 + 13 : widget.centerSize! + 13)
          : widget.sectionRadius ??
              (widget.centerSize == null ? 50 : widget.centerSize!);
      // const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      List<double> values =
          widget.chartData.map((e) => e['value'] as double).toList();
      return PieChartSectionData(
        color: widget.chartData[i]['color'] ??
            getColor(_listColor, i, withOpacity: widget.sectionOpacity),
        value: widget.chartData[i]['value'],
        showTitle: widget.showTouchedLabel,
        title: getSectionDisplayText(i, isTouched),
        titlePositionPercentageOffset: widget.titlePositionPercentageOffset,
        radius: radius,
        titleStyle: getLabelStyle(
            widget.labelBaseColor ?? Theme.of(context).hintColor,
            values,
            i,
            isTouched),
        borderSide: widget.getBorderSide?.call(i),
        gradient: widget.getGradient?.call(i),
      );
    });
  }

  List<Widget> getIndicators() {
    // List<Color> listColor = AppColors.getColorList(widget.chartData.length);

    return List.generate(
        widget.maxIdicators == null
            ? widget.chartData.length
            : widget.maxIdicators! < widget.chartData.length
                ? widget.maxIdicators!
                : widget.chartData.length, (i) {
      return InkWell(
        onTap: widget.onIdicatorTap == null
            ? null
            : () {
                widget.onIdicatorTap!(i);
                // print('tapped: $i');
              },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: widget.currentIndicatorIndex == i
                ? widget.currentIndicatorColor ??
                    Theme.of(context).colorScheme.error.withAlpha(80)
                : widget.indicatorColor ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).hintColor.withAlpha(60)
                        : Colors.grey.shade400),
          ),
          padding: const EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 2),
          margin: const EdgeInsets.only(left: 0, right: 13, bottom: 3, top: 3),
          child: WgtPieChartItemIndicator(
            size: 8,
            isSquare: true,
            color: widget.chartData[i]['color'] ?? getColor(_listColor, i),
            displayLabel: Text.rich(
              TextSpan(
                text: (widget.chartData[i]['is_empty'] ?? false)
                    ? ' '
                    : convertToDisplayString(widget.chartData[i]['label'],
                        widget.indicatorWidth, const TextStyle(fontSize: 15)),
                style: widget.currentIndicatorIndex == i
                    ? TextStyle(
                        fontSize: 15,
                        // fontWeight: FontWeight.bold,
                        color: widget.currentIndicatorLabelColor != null
                            ? widget.currentIndicatorLabelColor!
                            : Colors.orange.withAlpha(210))
                    : TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor.withAlpha(130),
                      ),
                children: [
                  TextSpan(
                      text: (widget.chartData[i]['is_empty'] ?? false)
                          ? ' \n '
                          : '${widget.indicator2Lines ? '\n' : ' '}${getCommaNumberStr(widget.chartData[i]['value'], decimal: widget.valueDecimal ?? decideDisplayDecimal(widget.chartData[i]['value']))} ${widget.valueUnit ?? widget.valueUnit ?? ''}',
                      style: widget.currentIndicatorIndex == i
                          ? TextStyle(
                              fontSize: 15,
                              // fontWeight: FontWeight.bold,
                              color: widget.currentIndicatorValueColor ??
                                  Colors.orange)
                          : TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: widget.indicatorValueColor ??
                                  Colors.orange.shade200)),
                ],
              ),
            ),
            suffix: widget.currentIndicatorIndex == i
                ? Icon(Icons.arrow_right,
                    color: widget.currentIndicatorArrowColor ??
                        Colors.orangeAccent.withAlpha(210))
                : null,
          ),
        ),
      );
    });
  }

  String getSectionDisplayText(int index, bool isTouched) {
    String valueText =
        '${getCommaNumberStr(widget.chartData[index]['value'] as double, decimal: widget.valueDecimal ?? decideDisplayDecimal(widget.chartData[index]['value']))}${widget.valueUnit ?? widget.valueUnit ?? ''}';
    String labelText = widget.chartData[index]['label'];

    String displayText = valueText;
    String displayTextTouched = labelText;
    if (widget.defaultShowLabel) {
      displayText = labelText;
      displayTextTouched = valueText;
    }

    if (widget.showLabel) {
      if (!isTouched) {
        return displayText;
      }
    }

    if (widget.showTouchedLabel) {
      if (isTouched) {
        if (widget.showLabel) {
          return displayTextTouched;
        } else {
          return '$labelText: $valueText';
        }
      }
    }
    return '';
  }

  TextStyle getLabelStyle(
      Color baseColor, List<double> values, int index, bool isTouched) {
    double sum = values.reduce((value, element) => value + element);
    double percent = values[index] / sum;
    double blurRadius = 5 * (index + 2) / values.length;
    if (blurRadius < 2) {
      blurRadius = 2;
    }
    return TextStyle(
        fontSize: getLabelDisplaySize(values.length, index, isTouched),
        // fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
        // fontStyle: FontStyle.italic,
        // backgroundColor:
        //     isTouched ? baseColor.withOpacity(0.8) : baseColor.withOpacity(0),
        color: getLabelDisplayColor(
            baseColor, percent, values.length, index, isTouched),
        shadows: (percent > (widget.percentageCap ?? 0.01))
            ? [
                Shadow(
                  blurRadius: blurRadius,
                  offset: const Offset(1, 2),
                  color: Theme.of(context).hintColor.withAlpha(130),
                )
              ]
            : null);
  }

  double getLabelDisplaySize(int listLength, int index, bool isTouched) {
    double minSize = widget.minLabelSize;
    double maxSize = widget.maxLabelSize;
    //decrease size according to list index
    double size = maxSize - (maxSize - minSize) * (index / listLength);
    return isTouched ? size * 1.2 : size;
  }

  Color getLabelDisplayColor(
      Color baseColor,
      /*List<double> values,*/ double percent,
      int len,
      int index,
      bool isTouched) {
    double minOpacity = 0.55;
    double maxOpacity = 0.89;

    if (isTouched) return baseColor.withAlpha(255 * maxOpacity ~/ 1);

    //decrease opacity according to list index
    double opacity = maxOpacity - (maxOpacity - minOpacity) * (index / len);

    if (percent < (widget.percentageCap ?? 0.01)) {
      return baseColor.withAlpha(0);
    }
    return baseColor.withAlpha(opacity * 255 ~/ 1);
  }

  Color getColor(List<Color> listColor, int index, {double? withOpacity}) {
    Color color = Colors.white;
    if (index < listColor.length) {
      color = listColor[index];
    } else {
      color = listColor[index % listColor.length];
    }
    if (index == widget.chartData.length - 1) {
      // print('color0: $color');
      if (color == listColor[0] && widget.chartData.length > 1) {
        color = listColor[1];
        // print('color1: $color');
      }
    }
    color = color
        .withAlpha(withOpacity == null ? 255 : (withOpacity * 255).toInt());

    return color;
  }

  Tooltip showPopupLabel(String label, String value) {
    return Tooltip(
      message: '$label: $value',
      triggerMode: TooltipTriggerMode.tap,
      child: Text(label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.black.withAlpha(150),
          )),
    );
  }
}

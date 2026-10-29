import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WgtMultiParaBarChart2 extends StatefulWidget {
  WgtMultiParaBarChart2({
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
    this.xLabelFontSize = 13,
    this.fitXLabelsHorizontally = false,
    this.statusSummary,
    this.statusAction,
    this.yAxisLabel,
    this.warningColor,
    Color? barColor,
    Color? tooltipTextColor,
    Color? tooltipTimeColor,
    Color? tooltipBackgroundColor,
    Color? errorTooltipBackgroundColor,
    Color? highlightColor,
    Color? bottomTextColor,
    Color? bottomTouchedTextColor,
  }) : barColor = barColor ?? AppColors.contentColorYellow,
       tooltipTextColor = tooltipTextColor ?? AppColors.contentColorYellow,
       tooltipTimeColor = tooltipTimeColor ?? AppColors.contentColorYellow,
       tooltipBackgroundColor =
           tooltipBackgroundColor ??
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

  /// Font size of the X-axis (date) labels.
  final double xLabelFontSize;

  /// Lay X labels flat when the widest one fits its bar slot; otherwise fall
  /// back to [bottomTextAngle].
  final bool fitXLabelsHorizontally;

  /// One-line data-quality summary shown above the chart (e.g. partial days
  /// and meter coverage). Rows may also carry `status` (complete, approximate,
  /// partial, incomplete), `coverage` (0..1) and a multi-line `tooltip`.
  final String? statusSummary;

  /// Optional control shown after [statusSummary], e.g. a strict-view toggle.
  final Widget? statusAction;

  /// Unit caption shown above the Y axis, e.g. 'kWh'.
  final String? yAxisLabel;

  /// Colour for partial/no-data markers; defaults to a green-tinted amber
  /// that suits the current brightness. Red is deliberately not used.
  final Color? warningColor;

  final Color avgColor = Colors.orange;
  @override
  State<StatefulWidget> createState() => WgtMultiParaBarChart2State();
}

class WgtMultiParaBarChart2State extends State<WgtMultiParaBarChart2> {
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

  // Detail card (hover/tap) shown in the app overlay so it is never clipped
  // by the chart box.
  final OverlayPortalController _detailPortal = OverlayPortalController();
  final GlobalKey _plotKey = GlobalKey();
  int? _detailIndex;
  Offset? _detailGlobal;
  bool _xLabelsFlat = false;

  void _loadChartData() {
    _rawBarGroups.clear();
    _showingBarGroups.clear();
    _xTitles = [];
    _maxY = 0;
    _timeStampStart = 0;
    _timeStampEnd = 0;
    _touchedGroupIndex = -1;
    _detailIndex = null;
    if (widget.chartData.isEmpty) return;

    for (Map<String, dynamic> groupBars in widget.chartData) {
      int x = groupBars['x'];
      List<Map<String, dynamic>> groupBarList = groupBars['groupBarList'];

      bool useColorList = false;
      if (widget.barColorList != null) {
        if (widget.barColorList!.length == groupBarList.length) {
          useColorList = true;
        }
      }

      final barGroup = groupBars['status'] == 'incomplete'
          ? BarChartGroupData(x: x, barRods: [])
          : widget.groupType == 'group'
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

    // A day without any total gets a short dashed stub at the baseline: it
    // reads as an intentional gap (not a missing render), never as zero, and
    // gives touch users something to tap for the coverage tooltip. Stubs are
    // added after the max is known so they never affect the Y scale.
    if (_maxY > 0) {
      final stubHeight = (widget.maxY ?? _maxY) * 0.06;
      for (var i = 0; i < _rawBarGroups.length; i++) {
        if (widget.chartData[i]['status'] != 'incomplete') continue;
        _rawBarGroups[i] = _rawBarGroups[i].copyWith(
          barRods: [
            BarChartRodData(
              toY: stubHeight,
              color: Colors.transparent,
              width: _barWidth,
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: widget.bottomTextColor, width: 1),
              borderDashArray: const [3, 3],
            ),
          ],
        );
      }
    }
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
    int x,
    List<Map<String, dynamic>> groupBarList,
  ) {
    List<BarChartRodData> barRods = [];
    for (Map<String, dynamic> groupBars in groupBarList) {
      final color = groupBars['color'] as Color;
      barRods.add(
        BarChartRodData(
          toY: groupBars['y'] as double,
          color: color,
          width: widget.barWidth ?? 5,
          borderSide: _partialOutline(groupBars, color),
        ),
      );
    }
    return BarChartGroupData(
      barsSpace: widget.barSpace,
      x: x,
      barRods: barRods,
    );
  }

  BarChartGroupData _makeStackGroupData(
    int x,
    List<Map<String, dynamic>> groupBarList,
    bool useColorList,
  ) {
    List<BarChartRodData> barRods = [];
    double toY = 0;
    for (Map<String, dynamic> groupBars in groupBarList) {
      if (groupBars['y'] as double > toY) {
        toY = groupBars['y'] as double;
      }
    }

    List<BarChartRodStackItem> rodStackItems = [];
    for (Map<String, dynamic> groupBars in groupBarList) {
      int alpha = groupBars['alpha'] ?? 255;
      final color = useColorList
          ? widget.barColorList![groupBarList.indexOf(groupBars)].withAlpha(
              alpha,
            )
          : (groupBars['color'] as Color);
      BarChartRodStackItem rodStackItem = BarChartRodStackItem(
        0,
        groupBars['y'] as double,
        color,
        borderSide: _partialOutline(groupBars, color),
      );

      rodStackItems.add(rodStackItem);
    }

    BarChartRodData barData = BarChartRodData(
      color: Colors.transparent,
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

  /// Partial subtotals are drawn translucent with a solid outline in the
  /// series colour, so they stay distinct from complete (solid) bars.
  BorderSide _partialOutline(Map<String, dynamic> bar, Color color) {
    if (bar['partial'] != true || (bar['alpha'] ?? 255) < 50) {
      return BorderSide.none;
    }
    return BorderSide(color: color.withAlpha(255), width: 1.5);
  }

  Color _warning(BuildContext context) =>
      widget.warningColor ??
      (Theme.of(context).brightness == Brightness.dark
          // Amber blended ~50% toward green: noticeable without reading
          // as an alarm.
          ? Color.lerp(Colors.amber.shade300, Colors.green.shade300, 0.5)!
          : Color.lerp(Colors.amber.shade800, Colors.green.shade800, 0.5)!);

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
    if (widget.chartData.isEmpty) {
      _loadChartData();
      // Recalculate bar widths when readings become available again.
      _chartWidth = null;
      return AspectRatio(
        aspectRatio: widget.ratio,
        child: Padding(
          padding: widget.padding,
          child: Center(
            child: Text(
              'no data for the duration',
              style: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(80),
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.chartKey != null) {
      if (_chartKey != widget.chartKey) {
        _chartKey = widget.chartKey;
        _loadChartData();
        // Timer(const Duration(milliseconds: 100), () {
        //   setState(() {});
        // });
      }
    }

    return OverlayPortal(
      controller: _detailPortal,
      overlayChildBuilder: _buildDetailOverlay,
      child: AspectRatio(
        aspectRatio: widget.ratio,
        child: Padding(
          padding: widget.padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_chartWidth == null && constraints.maxWidth > 0) {
                int barCount = widget.chartData.length;
                _chartWidth = constraints.maxWidth;
                final barsSpace =
                    widget.barSpace ?? 0.08 * _chartWidth! / barCount;
                final wAdj = widget.reservedSizeLeft ?? 0.0;
                _barWidth = ((_chartWidth! - wAdj) / barCount) - barsSpace;

                _loadChartData();
              }

              // barGroups = getBars(_touchedGroupIndex.toInt(), barWidth: barsWidth);
              _xLabelsFlat = _xLabelsFitFlat(constraints.maxWidth);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  verticalSpaceTiny,
                  if (_showUnitCaption) _buildUnitCaption(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, plotBox) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            KeyedSubtree(
                              key: _plotKey,
                              child: BarChart(
                                BarChartData(
                                  barGroups: _showingBarGroups,
                                  maxY: widget.maxY ?? (_maxY > 0 ? _maxY : 1),
                                  borderData: FlBorderData(
                                    show: widget.showBorder,
                                    border:
                                        widget.border ??
                                        Border.all(
                                          color:
                                              widget.borderColor ??
                                              Theme.of(context).hintColor,
                                          width: 1,
                                        ),
                                  ),
                                  gridData: FlGridData(
                                    show: widget.showGrid && !_noPositiveBars,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                  ),
                                  barTouchData: BarTouchData(
                                    touchCallback: (FlTouchEvent event, response) {
                                      _updateDetailFromTouch(event, response);
                                      if (response == null ||
                                          response.spot == null) {
                                        setState(() {
                                          _touchedGroupIndex = -1;
                                          _showingBarGroups = List.of(
                                            _rawBarGroups,
                                          );
                                        });
                                        return;
                                      }

                                      _touchedGroupIndex =
                                          response.spot!.touchedBarGroupIndex;

                                      setState(() {
                                        if (!event
                                            .isInterestedForInteractions) {
                                          _touchedGroupIndex = -1;
                                          _showingBarGroups = List.of(
                                            _rawBarGroups,
                                          );
                                          return;
                                        }
                                        _showingBarGroups = List.of(
                                          _rawBarGroups,
                                        );
                                        if (_touchedGroupIndex != -1) {
                                          var sum = 0.0;
                                          for (final rod
                                              in _showingBarGroups[_touchedGroupIndex]
                                                  .barRods) {
                                            sum += rod.toY;
                                          }
                                          final avg =
                                              sum /
                                              _showingBarGroups[_touchedGroupIndex]
                                                  .barRods
                                                  .length;

                                          _showingBarGroups[_touchedGroupIndex] =
                                              _showingBarGroups[_touchedGroupIndex].copyWith(
                                                barRods: _showingBarGroups[_touchedGroupIndex]
                                                    .barRods
                                                    .map((rod) {
                                                      return rod.copyWith(
                                                        toY:
                                                            widget.groupType ==
                                                                'group'
                                                            ? avg
                                                            : rod.toY,
                                                        color:
                                                            widget.groupType ==
                                                                'group'
                                                            ? widget.avgColor
                                                            : rod.color,
                                                        borderSide: BorderSide(
                                                          color:
                                                              widget.avgColor,
                                                          width: 1.5,
                                                        ),
                                                        // width: _barWidth + 5,
                                                      );
                                                    })
                                                    .toList(),
                                              );

                                          int a = 1;
                                        }
                                      });
                                    },
                                    touchTooltipData: BarTouchTooltipData(
                                      // tooltipBgColor: Colors.grey,
                                      // getTooltipItem: (a, b, c, d) => null,
                                      fitInsideHorizontally: _hasDetailTooltip,
                                      fitInsideVertically: _hasDetailTooltip,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        // Rows with a structured detail use the detail card
                                        // instead of fl_chart's text-only tooltip.
                                        if (widget
                                                .chartData[groupIndex]['detail']
                                            is Map) {
                                          return null;
                                        }
                                        final detail = widget
                                            .chartData[groupIndex]['tooltip'];
                                        if (detail is String) {
                                          // One detail card per date, even with grouped rods.
                                          if (rodIndex > 0) return null;
                                          return _detailTooltip(
                                            context,
                                            detail,
                                          );
                                        }
                                        String yValue = rod.toY.toStringAsFixed(
                                          widget.yDecimal,
                                        );

                                        final timeText = getDateFromDateTimeStr(
                                          DateTime.fromMicrosecondsSinceEpoch(
                                            group.x.toInt() * 1000,
                                          ).toString(),
                                          format:
                                              widget.tooltipTimeFormat ??
                                              'MM-dd HH:mm',
                                        );

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
                                        reservedSize:
                                            widget.reservedSizeRight ?? 0,
                                        getTitlesWidget: rightTitles,
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles:
                                            widget.showXTitle ||
                                            _hasQualityStatus,
                                        getTitlesWidget: bottomTitles,
                                        reservedSize:
                                            widget.showXTitle ||
                                                _hasQualityStatus
                                            ? _bottomLabelReserve +
                                                  (_hasQualityStatus
                                                      ? _stripReserve
                                                      : 0)
                                            : 0,
                                        // interval: 1,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles:
                                            widget.showYTitle &&
                                            !_allIncomplete,
                                        reservedSize: widget.showYTitle
                                            ? widget.reservedSizeLeft ?? 40
                                            : 0,
                                        interval: widget.showYTitle
                                            ? _niceInterval(plotBox.maxHeight)
                                            : 100000000,
                                        getTitlesWidget: leftTitles,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_noPositiveBars)
                              Positioned.fill(
                                bottom:
                                    _bottomLabelReserve +
                                    (_hasQualityStatus ? _stripReserve : 0),
                                child: IgnorePointer(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _emptyTitle,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          if (_emptySubtitle != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _emptySubtitle!,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_showStatusRow) _buildStatusRow(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool get _hasDetailCards =>
      widget.chartData.any((row) => row['detail'] is Map);

  void _showDetail(int index, Offset globalPosition) {
    if (!mounted || index < 0 || index >= widget.chartData.length) return;
    if (widget.chartData[index]['detail'] is! Map) return;
    setState(() {
      _detailIndex = index;
      _detailGlobal = globalPosition;
    });
    if (!_detailPortal.isShowing) _detailPortal.show();
  }

  void _hideDetail() {
    if (!mounted) return;
    if (_detailIndex == null && !_detailPortal.isShowing) return;
    setState(() => _detailIndex = null);
    if (_detailPortal.isShowing) _detailPortal.hide();
  }

  /// Hover shows the card while the pointer is over a bar; a tap keeps it
  /// open until the next tap (touch screens have no hover).
  void _updateDetailFromTouch(FlTouchEvent event, BarTouchResponse? response) {
    if (!_hasDetailCards) return;
    final spot = response?.spot;
    final local = event.localPosition;
    final box = _plotKey.currentContext?.findRenderObject() as RenderBox?;
    if (spot != null &&
        local != null &&
        box != null &&
        (event.isInterestedForInteractions || event is FlTapUpEvent)) {
      _showDetail(spot.touchedBarGroupIndex, box.localToGlobal(local));
    } else if (event is FlPointerExitEvent ||
        event is FlPointerHoverEvent ||
        event is FlTapUpEvent) {
      _hideDetail();
    }
  }

  Widget _buildDetailOverlay(BuildContext context) {
    final index = _detailIndex;
    final anchor = _detailGlobal;
    if (index == null || anchor == null || index >= widget.chartData.length) {
      return const SizedBox.shrink();
    }
    final detail = widget.chartData[index]['detail'];
    if (detail is! Map) return const SizedBox.shrink();
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final local = overlayBox?.globalToLocal(anchor) ?? anchor;
    return IgnorePointer(
      child: CustomSingleChildLayout(
        delegate: _DetailCardLayout(local),
        child: _detailCard(context, Map<String, dynamic>.from(detail)),
      ),
    );
  }

  /// Card for a structured `detail`:
  /// {title, status, sections: [{name?, color?, rows: [{label, value}]}], note?}
  Widget _detailCard(BuildContext context, Map<String, dynamic> detail) {
    final scheme = Theme.of(context).colorScheme;
    final warn = _warning(context);
    final primary = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final (chipLabel, chipColor) = switch (detail['status']) {
      'partial' => ('Partial', warn),
      'incomplete' => ('No total', warn),
      'approximate' => ('Approximate', scheme.primary),
      _ => ('Complete', muted),
    };
    final sections = (detail['sections'] as List? ?? const []).cast<Map>();
    final labelStyle = TextStyle(fontSize: 12, color: muted, height: 1.4);
    final valueStyle = TextStyle(
      fontSize: 12,
      color: primary,
      height: 1.4,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cellRow(Map cell) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${cell['label']}', style: labelStyle),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '${cell['value']}',
            style: valueStyle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 264,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant.withAlpha(140)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${detail['title'] ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              if (sections[i]['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sections[i]['color'] as Color? ?? muted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${sections[i]['name']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final cell
                  in (sections[i]['rows'] as List? ?? const []).cast<Map>())
                Padding(
                  padding: EdgeInsets.only(
                    left: sections[i]['name'] != null ? 14 : 0,
                  ),
                  child: cellRow(cell),
                ),
            ],
            if (detail['note'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${detail['note']}',
                style: TextStyle(fontSize: 11, color: muted, height: 1.35),
              ),
            ],
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
    // With no positive bars the 0..1 scale is a placeholder: only the zero
    // line carries meaning.
    if (_noPositiveBars && value != 0) return Container();
    final style = TextStyle(color: widget.bottomTextColor, fontSize: 13);
    // Small ranges would otherwise round to repeated labels (0, 0, 0, 1, 1).
    final stepDecimals = _decimalsFor(meta.appliedInterval);
    final yDecimal = stepDecimals > widget.yDecimal
        ? stepDecimals
        : widget.yDecimal;
    final yDecimalK = stepDecimals > widget.yDecimalK
        ? stepDecimals
        : widget.yDecimalK;
    return SideTitleWidget(
      // axisSide: meta.axisSide,
      meta: meta,
      space: 6,
      fitInside: _fitInsideLeftTitle
          ? SideTitleFitInsideData.fromTitleMeta(meta)
          : SideTitleFitInsideData.disable(),
      child: Text(
        widget.showKonY != null
            ? widget.showKonY!
                  ? getK(value, yDecimalK)
                  : value.toStringAsFixed(yDecimal)
            : value.toStringAsFixed(yDecimal),
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Fewest decimals (max 4) that print every multiple of [step] distinctly.
  int _decimalsFor(double step) {
    if (step <= 0 || step >= 1) return 0;
    for (var d = 1; d < 4; d++) {
      final scaled = step * pow(10, d);
      if ((scaled - scaled.round()).abs() < 1e-6) return d;
    }
    return 4;
  }

  Widget rightTitles(double value, TitleMeta meta) {
    final style = TextStyle(color: widget.bottomTextColor, fontSize: 13);
    return SideTitleWidget(
      // axisSide: meta.axisSide,
      meta: meta,
      space: 6,
      fitInside: _fitInsideLeftTitle
          ? SideTitleFitInsideData.fromTitleMeta(meta)
          : SideTitleFitInsideData.disable(),
      child: Text(' ', style: style, textAlign: TextAlign.center),
    );
  }

  bool get _usesStatus => widget.chartData.any((row) => row['status'] != null);

  bool get _allIncomplete =>
      widget.chartData.isNotEmpty &&
      widget.chartData.every((row) => row['status'] == 'incomplete');

  /// Status-aware charts with nothing above zero: every day lacks a total, or
  /// every value (including partial subtotals) is a genuine zero.
  bool get _noPositiveBars =>
      widget.chartData.isNotEmpty && _usesStatus && _maxY <= 0;

  bool get _hasQualityStatus => widget.chartData.any(
    (row) =>
        row['status'] == 'incomplete' ||
        row['status'] == 'partial' ||
        row['status'] == 'approximate',
  );

  bool get _hasDetailTooltip =>
      widget.chartData.any((row) => row['tooltip'] is String);

  bool get _hasCoverage =>
      widget.chartData.any((row) => row['coverage'] is num);

  /// Downward nudge of X labels. Under a coverage strip the label is placed
  /// by [_stripLabelGap] instead, so no extra nudge.
  double get _labelOffsetY =>
      _hasQualityStatus && _hasCoverage ? 0 : widget.xSpace;

  /// Layout gap from coverage strip to label box. With the label's line
  /// height pinned to 1.0, the digits start ~2 px into the box, so the
  /// visible gap is ~8 px whatever the app theme's text height is.
  static const double _stripLabelGap = 6;

  /// Space between the X axis and the coverage strip.
  static const double _stripGap = 5;

  /// Extra bottom space for the coverage strip (gap + strip + gap to label).
  double get _stripReserve => _hasCoverage ? _stripGap + 4 + _stripLabelGap : 0;

  bool get _showUnitCaption => widget.yAxisLabel?.isNotEmpty ?? false;

  bool get _showStatusRow => widget.statusSummary != null || _hasQualityStatus;

  /// Unit caption above the Y axis (e.g. 'kWh').
  /// Height reserved for X labels: rotated labels use the configured size,
  /// flat labels only need one text line below the axis.
  double get _bottomLabelReserve {
    final configured = widget.rereservedSizeBottom ?? 22;
    if (!_xLabelsFlat) return configured;
    // A no-total warning icon sits on a second line under the date.
    final iconLine =
        widget.chartData.any((row) => row['status'] == 'incomplete')
        ? _iconLineHeight
        : 0.0;
    final flat = _labelOffsetY + widget.xLabelFontSize + 4 + iconLine;
    return flat < configured ? flat : configured;
  }

  /// Whether the widest X label (plus a little padding) fits one bar slot.
  bool _xLabelsFitFlat(double chartWidth) {
    if (!widget.fitXLabelsHorizontally || widget.chartData.isEmpty) {
      return false;
    }
    final plotWidth =
        chartWidth - _leftReserve - (widget.reservedSizeRight ?? 0);
    final slot = plotWidth / widget.chartData.length;
    var widest = 0.0;
    for (final row in widget.chartData) {
      final text = row['label'] is String
          ? row['label'] as String
          : getDateFromDateTimeStr(
              DateTime.fromMillisecondsSinceEpoch(row['x'] as int).toString(),
              format: widget.xTimeFormat,
            );
      final painter = TextPainter(
        text: TextSpan(
          text: '$text ≈',
          style: TextStyle(fontSize: widget.xLabelFontSize),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    // The warning icon goes on its own line, so only the date must fit.
    return widest + 6 <= slot;
  }

  /// Gap plus icon size for the no-total warning line under a flat date.
  static const double _iconLineHeight = 15; // 2 px gap + 13 px icon

  /// Width of the Y-axis label column; the caption and status row align to it.
  double get _leftReserve =>
      widget.showYTitle ? widget.reservedSizeLeft ?? 40 : 0;

  /// Unit caption right-aligned over the Y-axis labels (e.g. 'kWh').
  Widget _buildUnitCaption() => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: _leftReserve > 0 ? _leftReserve - 6 : null,
        child: Text(
          widget.yAxisLabel!,
          textAlign: _leftReserve > 0 ? TextAlign.right : TextAlign.left,
          style: TextStyle(fontSize: 11, color: widget.bottomTextColor),
        ),
      ),
    ),
  );

  /// Round-number Y step (1, 2, 2.5 or 5 x 10^n) with about one gridline per
  /// 32 px of plot height. Status-aware charts only; others keep fl_chart's
  /// automatic interval.
  double? _niceInterval(double plotHeight) {
    final top = widget.maxY ?? _maxY;
    if (!_usesStatus || top <= 0 || !plotHeight.isFinite || plotHeight <= 0) {
      return null;
    }
    final bottom = widget.showXTitle || _hasQualityStatus
        ? _bottomLabelReserve + (_hasQualityStatus ? _stripReserve : 0)
        : 0.0;
    final ticks = max(2, ((plotHeight - bottom) / 32).floor());
    final raw = top / ticks;
    final magnitude = pow(10, (log(raw) / ln10).floor()).toDouble();
    final norm = raw / magnitude;
    final double step = norm <= 1
        ? 1
        : norm <= 2
        ? 2
        : norm <= 2.5
        ? 2.5
        : norm <= 5
        ? 5
        : 10;
    return step * magnitude;
  }

  String get _emptyTitle {
    if (_allIncomplete) return 'No complete daily totals';
    final unit = widget.yAxisLabel ?? '';
    return 'All values are 0${unit.isEmpty ? '' : ' $unit'}';
  }

  String? get _emptySubtitle {
    if (_allIncomplete) return 'Tap or hover a date to see meter coverage.';
    if (widget.chartData.any((row) => row['status'] == 'partial')) {
      return 'Partial days include only the meters that could be calculated.';
    }
    return null;
  }

  /// Data-quality summary, strict-view action and legend, below the chart.
  Widget _buildStatusRow(BuildContext context) {
    final muted = widget.bottomTextColor;
    final warn = _warning(context);
    final small = TextStyle(fontSize: 11, color: muted);
    final statuses = widget.chartData.map((row) => row['status']).toSet();

    Widget swatch({Color? fill, Color? border}) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: fill,
        border: border == null ? null : Border.all(color: border),
        borderRadius: BorderRadius.circular(2),
      ),
    );
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 4),
        Text(text, style: small),
      ],
    );

    // Legend lists only the states present on screen: coverage strip and
    // no-total triangle first (the markers under the axis), then bar styles.
    final legendItems = <Widget>[
      if (_hasQualityStatus && _hasCoverage)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Meter coverage', style: small),
            for (final (band, label) in const [
              (0.95, '≥90%'),
              (0.8, '70–89%'),
              (0.5, '<70%'),
            ]) ...[
              const SizedBox(width: 6),
              Container(
                width: 14,
                height: 4,
                decoration: BoxDecoration(
                  color: _coverageColor(context, band),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Text(label, style: small),
            ],
          ],
        ),
      if (statuses.contains('incomplete'))
        item(
          Icon(Icons.info_outline_rounded, size: 13, color: warn),
          'No total',
        ),
      if (statuses.contains('partial'))
        item(swatch(fill: muted.withAlpha(50), border: muted), 'Partial'),
      if (_hasQualityStatus && statuses.contains('complete'))
        item(swatch(fill: muted), 'Complete'),
      if (statuses.contains('approximate'))
        item(Text('≈', style: small), 'Approximate boundary'),
    ];
    final legend = <Widget>[
      if (legendItems.isNotEmpty)
        Text('Legend', style: small.copyWith(fontWeight: FontWeight.w600)),
      ...legendItems,
    ];

    return Padding(
      // Centred over the plot area (offset by the Y-axis label column).
      padding: EdgeInsets.only(top: 6, left: _leftReserve),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.statusSummary != null)
            Tooltip(
              message: widget.statusSummary!,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: warn),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.statusSummary!,
                      style: small.copyWith(color: warn),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.statusAction != null) widget.statusAction!,
          ...legend,
        ],
      ),
    );
  }

  BarTooltipItem _detailTooltip(BuildContext context, String detail) {
    final lines = detail.split('\n');
    final base = TextStyle(
      color: widget.tooltipTextColor,
      fontSize: 12,
      height: 1.35,
    );
    return BarTooltipItem(
      lines.first,
      base.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
      textAlign: TextAlign.left,
      children: [
        for (final line in lines.skip(1))
          TextSpan(
            text: '\n$line',
            style: line.startsWith('Partial =')
                ? base.copyWith(fontStyle: FontStyle.italic, fontSize: 11)
                : base,
          ),
      ],
    );
  }

  /// Coverage bands for the strip: green from [_coverageGood], olive (the
  /// standard warning colour) from [_coverageFair], amber below. A fully
  /// covered day stays neutral grey (handled by the caller).
  static const double _coverageGood = 0.9;
  static const double _coverageFair = 0.7;

  Color _coverageColor(BuildContext context, double coverage) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (coverage >= _coverageGood) {
      return dark ? const Color(0xFF7CC48E) : Colors.green.shade700;
    }
    if (coverage >= _coverageFair) return _warning(context);
    return dark ? const Color(0xFFE3A64A) : Colors.amber.shade900;
  }

  Widget _coverageStrip(double? coverage, Color warn) {
    final width = _barWidth.clamp(8.0, 36.0).toDouble();
    final full = coverage != null && coverage >= 0.999;
    return SizedBox(
      width: width,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: widget.bottomTextColor.withAlpha(45)),
            if (coverage != null && coverage > 0)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: coverage.clamp(0.0, 1.0).toDouble(),
                child: ColoredBox(
                  color: full
                      ? widget.bottomTextColor.withAlpha(150)
                      : _coverageColor(context, coverage),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Date labels open the same detail card as the bars (hover or tap). Rows
  /// with only a text `tooltip` keep a plain tooltip.
  Widget _labelInteraction(
    Map<String, dynamic> row,
    String message,
    Widget child,
  ) {
    if (row['detail'] is Map) {
      final index = widget.chartData.indexOf(row);
      return MouseRegion(
        onEnter: (event) => _showDetail(index, event.position),
        onExit: (_) => _hideDetail(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _showDetail(index, details.globalPosition),
          child: child,
        ),
      );
    }
    return Tooltip(
      message: message,
      // Touch screens have no hover: a tap opens the coverage details.
      triggerMode: TooltipTriggerMode.tap,
      child: child,
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final row = widget.chartData.firstWhere(
      (row) => row['x'] == value.toInt(),
      orElse: () => <String, dynamic>{},
    );
    final noTotal = row['status'] == 'incomplete';
    final approximate = row['status'] == 'approximate';
    final coverage = row['coverage'] is num
        ? (row['coverage'] as num).toDouble()
        : null;
    final showStrip = _hasQualityStatus && _hasCoverage;

    final isTouched = value == _touchedGroupIndex;
    final style = TextStyle(
      color: isTouched ? widget.bottomTouchedTextColor : widget.bottomTextColor,
      // fontWeight: FontWeight.bold,
      fontSize: widget.xLabelFontSize,
      // Pin line height: a theme-level `height` would otherwise push the
      // digits well below the box top (and away from the coverage strip).
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );

    // The usual label-thinning rules apply to every date; partial dates are
    // still identifiable through the outlined bar and the coverage strip.
    var skipped = false;
    if (widget.hideEdgeXTitle) {
      if (_timeStampEnd > 0 && _timeStampStart > 0) {
        if (value.toInt() == _timeStampStart ||
            value.toInt() == _timeStampEnd) {
          skipped = true;
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
          skipped = true;
        }
      }
    } else {
      if (index > 0 && (widget.skipOddXTitle) && index % 2 == 1) {
        skipped = true;
      }
    }

    String xTitle =
        label ??
        getDateFromDateTimeStr(
          DateTime.fromMillisecondsSinceEpoch(value.toInt()).toString(),
          format: widget.xTimeFormat,
        );

    final text = widget.showXTitle && !skipped ? xTitle : '';
    final suffix = approximate && !skipped ? ' ≈' : '';
    // No-total days keep their icon even when the label is thinned out: with
    // no bar to tap, it is the only way to reach the coverage details.
    final showIcon = noTotal;
    final labelVisible = text.isNotEmpty || suffix.isNotEmpty || showIcon;
    if (!labelVisible && !showStrip) {
      return const SizedBox.shrink();
    }

    final warn = _warning(context);
    final message = row['tooltip'] as String? ?? xTitle;
    return SideTitleWidget(
      space: 0,
      // axisSide: meta.axisSide,
      meta: meta,
      fitInside: _fitInsideBottomTitle
          ? SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0)
          : SideTitleFitInsideData.disable(),
      child: _labelInteraction(
        row,
        message,
        Semantics(
          label: message,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStrip) ...[
                // Gap so the strip reads as separate from the bar above.
                const SizedBox(height: _stripGap),
                _coverageStrip(coverage, warn),
                const SizedBox(height: _stripLabelGap),
              ],
              if (labelVisible)
                Transform.translate(
                  offset: widget.xOffset ?? Offset(0, _labelOffsetY),
                  child: Transform.rotate(
                    angle: _xLabelsFlat
                        ? 0
                        : widget.bottomTextAngle ?? 4 * pi / 12,
                    child: Container(
                      width: _xLabelsFlat || widget.xLabelWidth == null
                          ? null
                          : widget.xLabelWidth! + (showIcon ? 16 : 0),
                      alignment: _xLabelsFlat
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: _xLabelsFlat
                          // Flat: date on line 1, warning icon on line 2, so
                          // the icon never widens the label or forces a slant.
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ('$text$suffix'.isNotEmpty)
                                  Text('$text$suffix', style: style),
                                if (showIcon)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 13,
                                      color: warn,
                                    ),
                                  ),
                              ],
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '$text$suffix'),
                                  if (showIcon)
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        size: 14,
                                        color: warn,
                                      ),
                                    ),
                                ],
                              ),
                              style: style,
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Places the detail card beside the pointer, flipping left near the right
/// edge and keeping it fully on screen.
class _DetailCardLayout extends SingleChildLayoutDelegate {
  _DetailCardLayout(this.anchor);

  final Offset anchor;
  static const double _gap = 14;
  static const double _margin = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: max(0, constraints.maxWidth - 2 * _margin),
        maxHeight: max(0, constraints.maxHeight - 2 * _margin),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var left = anchor.dx + _gap;
    if (left + childSize.width > size.width - _margin) {
      left = anchor.dx - _gap - childSize.width;
    }
    left = left
        .clamp(_margin, max(_margin, size.width - childSize.width - _margin))
        .toDouble();
    final top = (anchor.dy - childSize.height / 2)
        .clamp(_margin, max(_margin, size.height - childSize.height - _margin))
        .toDouble();
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_DetailCardLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}

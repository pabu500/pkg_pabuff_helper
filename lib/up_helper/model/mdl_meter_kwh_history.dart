import 'mdl_meter_kwh_history_row.dart';
import 'package:fl_chart/fl_chart.dart';

class MeterKwhHistory {
  List<MeterKwhHistoryRow>? meterKwhHistory;
  MeterHistoryMeta? meterKwhHistoryMeta;

  List<Map<int, bool>>? _isEstimated;

  bool _test = false;
  List<FlSpot>? _testChartData;

  MeterKwhHistory(
      {required this.meterKwhHistory, required this.meterKwhHistoryMeta});

  factory MeterKwhHistory.fromJson(
      List<dynamic> jsonHistory, Map<String, dynamic> jsonMeta) {
    MeterHistoryMeta meta = MeterHistoryMeta.fromJson(jsonMeta);
    List<MeterKwhHistoryRow> history =
        jsonHistory.map((x) => MeterKwhHistoryRow.fromJson(x)).toList();

    return MeterKwhHistory(meterKwhHistory: history, meterKwhHistoryMeta: meta);
  }

  Map<String, dynamic> toJson() {
    return {
      'meterKwhHistory': meterKwhHistory!.map((x) => x.toJson()).toList(),
      'meterKwhHistoryMeta': meterKwhHistoryMeta!.toJson(),
    };
  }

  bool isEmpty() {
    return meterKwhHistory!.isEmpty;
  }

  bool isEstimated(int timestamp) {
    return _isEstimated!.firstWhere((element) => element.containsKey(timestamp),
        orElse: () => {0: false})[timestamp]!;
  }

  List<FlSpot> genHistoryChartData() {
    //conver the list to map with DateTime as key and kwh_diff as value
    List<FlSpot> chartData = [];
    _isEstimated = [];
    for (var kwhDiff in meterKwhHistory!) {
      int kwh_timestamp = kwhDiff.khwTimestamp!.millisecondsSinceEpoch;
      chartData
          .add(FlSpot(kwh_timestamp.toDouble(), kwhDiff.kwhDiff!.toDouble()));
      _isEstimated!.add({kwh_timestamp: kwhDiff.isEstimated!});
    }

    if (_test) {
      _testChartData = [
        FlSpot(1680751031000, 0.0),
        FlSpot(1680749230000, 0.0),
        FlSpot(1680747430000, 0.004),
        FlSpot(1680745630000, 0.0),
        FlSpot(1680743830000, 0.004),
        FlSpot(1680742028000, 0.004),
        FlSpot(1680740229000, 0.002),
        FlSpot(1680738429000, 0.004),
        FlSpot(1680736629000, 0.004),
        FlSpot(1680734829000, 0.003),
        FlSpot(1680733029000, 0.004),
        FlSpot(1680731230000, 0.004),
        FlSpot(1680729429000, 0.002),
        FlSpot(1680727630000, 0.004),
        // FlSpot.nullSpot,
        FlSpot(1680725829000, 0.004),
        FlSpot(1680724029000, 0.005),
        FlSpot(1680722230000, 0.004),
        FlSpot(1680720429000, 0.004),
        FlSpot(1680718629000, 0.004),
        FlSpot(1680716830000, 0.004),
        FlSpot(1680715030000, 0.004),
        FlSpot(1680713230000, 0.004),
        FlSpot(1680711429000, 0.004),
        FlSpot(1680709629000, 0.004),
        FlSpot(1680707829000, 0.005),
        FlSpot(1680706068000, 0.002),
        FlSpot(1680704268000, 0.004),
        FlSpot(1680702468000, 0.002),
        FlSpot(1680700629000, 0.005),
        FlSpot(1680698830000, 0.002),
        FlSpot(1680697029000, 0.0),
        FlSpot(1680695229000, 0.0),
      ];
      for (var i = 0; i < _testChartData!.length; i++) {
        if (_testChartData![i] == FlSpot.nullSpot) {
        } else {
          _isEstimated!.add({_testChartData![i].x.toInt(): false});
        }
      }
      chartData = _testChartData!;
    }

    return chartData;
  }

  MeterHistoryMeta toHistoryChartMeta() {
    //chart interval in minutes
    int dominantInterval =
        (meterKwhHistoryMeta!.dominantInterval / 60000).round();
    //chart duration in hours
    int duration = (meterKwhHistoryMeta!.duration / 3600000).round();
    double maxVal = meterKwhHistoryMeta!.maxVal;

    if (_test) {
      //find max of test chart data
      maxVal = _testChartData!.map((e) => e.y).reduce((value, element) {
        if (value > element) {
          return value;
        } else {
          return element;
        }
      });
      //get duration from test chart data
      duration = ((_testChartData!.first.x - _testChartData!.last.x) / 3600000)
          .round();
    }

    return MeterHistoryMeta(
      dominantInterval: dominantInterval,
      duration: duration,
      maxVal: maxVal,
      maxValDt: meterKwhHistoryMeta!.maxValDt,
      minVal: meterKwhHistoryMeta!.minVal,
      minValNonZero: meterKwhHistoryMeta!.minValNonZero,
      minValNonZeroDt: meterKwhHistoryMeta!.minValNonZeroDt,
      avgVal: 0,
      medianVal: 0,
      total: 0,
      // positiveCount: 0,
      rawDataCount: 0,
      expectedReadingCount: 0,
      actualReadingCount: 0,
      missingReadingCount: 0,
      repeatedReadingCount: 0,
      negativeTotalCount: 0,
      negativeDiffCount: 0,
      overThresholdCount: 0,
      // estIntervals: meterKwhHistoryMeta!.estIntervals,
    );
  }
}

class MeterHistoryMeta {
  int dominantInterval = 0;
  int duration = 0;
  double maxVal = 0;
  DateTime? maxValDt;
  double avgVal = 0;
  double medianVal = 0;
  double minVal = 0;
  double minValNonZero = 0;
  DateTime? minValNonZeroDt;
  double total = 0;
  // int positiveCount = 0;
  List<Map<String, String>>? estIntervals;
  int rawDataCount = 0;
  int expectedReadingCount = 0;
  int actualReadingCount = 0;
  int repeatedReadingCount = 0;
  int missingReadingCount = 0;
  int negativeTotalCount = 0;
  int negativeDiffCount = 0;
  int overThresholdCount = 0;

  MeterHistoryMeta(
      {required this.dominantInterval,
      required this.duration,
      required this.maxVal,
      required this.maxValDt,
      required this.minVal,
      required this.minValNonZero,
      required this.minValNonZeroDt,
      required this.avgVal,
      required this.medianVal,
      required this.total,
      // required this.positiveCount,
      required this.rawDataCount,
      required this.expectedReadingCount,
      required this.actualReadingCount,
      required this.missingReadingCount,
      required this.repeatedReadingCount,
      required this.negativeTotalCount,
      required this.negativeDiffCount,
      required this.overThresholdCount,
      this.estIntervals});

  factory MeterHistoryMeta.fromJson(Map<String, dynamic> json) {
    DateTime? maxValDt;
    if (json['max_val_dt'] != null) {
      maxValDt = DateTime.parse(json['max_val_dt']);
    }
    DateTime? minValNonZeroDt;
    if (json['min_val_non_zero_dt'] != null) {
      minValNonZeroDt = DateTime.parse(json['min_val_non_zero_dt']);
    }
    return MeterHistoryMeta(
      dominantInterval: json['dominant_interval'],
      duration: json['duration'],
      maxVal: json['max_val'] ?? -1,
      maxValDt: maxValDt,
      minVal: json['min_val'] ?? -1,
      minValNonZero: json['min_val_non_zero'] ?? -1,
      minValNonZeroDt: minValNonZeroDt,
      avgVal: json['avg_val'] ?? -1,
      medianVal: json['median_val'] ?? -1,
      total: json['total'] ?? -1,
      // positiveCount: json['positive_count'] ?? -1,
      // estIntervals: json['est_intervals'] ?? [] as List<Map<String, String>>?,
      rawDataCount: json['raw_data_count'] ?? -1,
      expectedReadingCount: json['expected_reading_count'] ?? -1,
      actualReadingCount: json['actual_reading_count'] ?? -1,
      missingReadingCount: json['missing_reading_count'] ?? -1,
      repeatedReadingCount: json['repeated_reading_count'] ?? -1,
      negativeTotalCount: json['negative_total_count'] ?? -1,
      negativeDiffCount: json['negative_diff_count'] ?? -1,
      overThresholdCount: json['over_threshold_count'] ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dominant_interval': dominantInterval,
      'duration': duration,
      'max_val': maxVal,
      'max_val_dt': maxValDt,
      'min_val': minVal,
      'min_val_non_zero': minValNonZero,
      'min_val_non_zero_dt': minValNonZeroDt,
      'avg_val': avgVal,
      'median_val': medianVal,
      'total': total,
      // 'positive_count': positiveCount,
      'est_intervals': estIntervals,
      'raw_data_count': rawDataCount,
      'expected_reading_count': expectedReadingCount,
      'actual_reading_count': actualReadingCount,
      'negative_total_count': negativeTotalCount,
      'negative_diff_count': negativeDiffCount,
      'missing_reading_count': missingReadingCount,
      'repeated_reading_count': repeatedReadingCount,
      'over_threshold_count': overThresholdCount,
    };
  }
}

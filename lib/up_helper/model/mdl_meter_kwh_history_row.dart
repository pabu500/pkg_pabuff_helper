import 'package:intl/intl.dart';

class MeterKwhHistoryRow {
  DateTime? khwTimestamp;
  double? kwhDiff;
  double? kwhTotal;
  bool? isEstimated;

  MeterKwhHistoryRow(
      {required this.khwTimestamp,
      required this.kwhDiff,
      required this.kwhTotal,
      this.isEstimated = false});

  factory MeterKwhHistoryRow.fromJson(Map<String, dynamic> json) {
    return MeterKwhHistoryRow(
      khwTimestamp: DateTime.parse(json['reading_timestamp']),
      kwhDiff: json['reading_diff'],
      kwhTotal: json['reading_total'],
      isEstimated: json['is_estimated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reading_timestamp': khwTimestamp!.toIso8601String(),
      'reading_diff': kwhDiff,
      'reading_total': kwhTotal,
      'is_estimated': isEstimated,
    };
  }

  static List<dynamic> getKeyList() {
    return [
      'reading_timestamp',
      'reading_diff',
      'reading_total',
      'is_estimated',
    ];
  }

  List<dynamic> getValueStringList() {
    return [
      DateFormat('yyyy-MM-dd HH:mm:ss').format(khwTimestamp!),
      kwhDiff ?? '',
      kwhTotal ?? '',
      isEstimated ?? '',
    ];
  }
}

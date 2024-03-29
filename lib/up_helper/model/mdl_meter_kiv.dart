import 'package:intl/intl.dart';

class MeterKiv {
  String kivTag;
  DateTime kivTimestamp;
  String? meterSn;
  String? meterDisplayname;
  String? kivRef;
  double? kivVal;

  MeterKiv({
    required this.kivTag,
    required this.kivTimestamp,
    this.meterSn,
    this.meterDisplayname,
    this.kivRef,
    this.kivVal,
  });

  factory MeterKiv.fromJson(Map<String, dynamic> json) {
    return MeterKiv(
      kivTag: json['kiv_tag'],
      kivTimestamp: DateTime.parse(json['kiv_start_timestamp']),
      meterSn: json['meter_sn'] ?? '',
      meterDisplayname: json['meter_displayname'] ?? '',
      kivRef: json['kiv_ref'] ?? '',
      kivVal: json['kiv_val'] == null
          ? null
          : double.parse(json['kiv_val'].toString()),
    );
  }

  bool isEmpty() => kivTag.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'kiv_tag': kivTag,
      'kiv_start_timestamp': kivTimestamp.toIso8601String(),
      'meter_sn': meterSn,
      'meter_displayname': meterDisplayname,
      'kiv_ref': kivRef,
      'kiv_val': kivVal,
    };
  }

  static List<dynamic> getKeyList() {
    return [
      'kiv_tag',
      'kiv_start_timestamp',
      'meter_sn',
      'meter_displayname',
      'kiv_ref',
      'kiv_val',
    ];
  }

  List<dynamic> getValueStringList() {
    return [
      kivTag,
      DateFormat('yyyy-MM-dd HH:mm:ss').format(kivTimestamp),
      meterSn ?? '',
      meterDisplayname ?? '',
      kivRef ?? '',
      kivVal == null ? '' : kivVal.toString(),
    ];
  }
}

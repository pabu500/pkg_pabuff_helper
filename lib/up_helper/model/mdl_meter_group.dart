import '../helper/device_def.dart';

class MeterGroup {
  int? id;
  String? label;
  String? name;
  // String? locationTag;
  // String? sapWbs;
  String? meterInfoStr;
  MeterType? meterType;
  String? createdTimeStr;

  MeterGroup({
    this.id = 0,
    this.label,
    this.name,
    // this.locationTag,
    // this.sapWbs,
    this.meterInfoStr,
    this.meterType,
    this.createdTimeStr,
  });

  factory MeterGroup.fromJson(Map<String, dynamic> json) {
    return MeterGroup(
      id: int.tryParse(json['id']) ?? -1,
      label: json['label'] ?? '',
      name: json['name'] ?? '',
      // locationTag: json['location_tag'] ?? '',
      // sapWbs: json['sap_wbs'] ?? '',
      meterInfoStr: json['meter_info_str'] ?? '',
      meterType: getMeterType((json['meter_type'] ?? '').toUpperCase()),
      createdTimeStr: json['created_timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'name': name,
      // 'location_tag': locationTag,
      // 'sap_wbs': sapWbs,
      'meter_info_str': meterInfoStr,
      'meter_type': meterType, //meterType?.name,
      'created_timestamp': createdTimeStr,
    };
  }
}
